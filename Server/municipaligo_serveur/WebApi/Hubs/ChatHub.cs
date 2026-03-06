using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Models.Models;
using municipaligo_serveur.Data;
using WebApi.Interfaces;

namespace WebApi.Hubs
{
    public interface IChatClient
    {
        Task ReceiveMessage(int fromCitizenId, string message, DateTime sentAt);
        Task PartnerOnline(int citizenId);
        Task PartnerOffline(int citizenId);
        Task PartnerTyping();
        Task NewConversationMessage(int fromCitizenId, string fromName, string message, DateTime sentAt);
        Task ReceiveIncident(int fromCitizenId, object incident, DateTime sentAt);
    }

    [Authorize]
    public class ChatHub : Hub<IChatClient>
    {
        private readonly ApplicationDbContext _db;
        private readonly IUserConnectionTracker _tracker;
        private readonly ILogger<ChatHub> _logger;

        public ChatHub(ApplicationDbContext db, IUserConnectionTracker tracker, ILogger<ChatHub> logger)
        {
            _db = db;
            _tracker = tracker;
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = GetUserId();
            _tracker.AddConnection(userId, Context.ConnectionId);
            _logger.LogInformation("User {UserId} connected: {ConnectionId}", userId, Context.ConnectionId);
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = GetUserId();
            _tracker.RemoveConnection(userId, Context.ConnectionId);
            _logger.LogInformation("User {UserId} disconnected: {ConnectionId}", userId, Context.ConnectionId);
            await base.OnDisconnectedAsync(exception);
        }

        public async Task OpenConversation(int partnerCitizenId)
        {
            var citizen = await GetCitizenAsync(GetUserId())
                ?? throw new HubException("Citizen not found.");

            var roomId = GetRoomId(citizen.Id, partnerCitizenId);
            await Groups.AddToGroupAsync(Context.ConnectionId, roomId);

            var partnerUserId = await _db.Citizens
                .Where(c => c.Id == partnerCitizenId)
                .Select(c => c.UserId)
                .FirstOrDefaultAsync();

            if (partnerUserId != null && _tracker.IsOnline(partnerUserId))
                await Clients.Caller.PartnerOnline(partnerCitizenId);
            else
                await Clients.Caller.PartnerOffline(partnerCitizenId);
        }

        public async Task CloseConversation(int partnerCitizenId)
        {
            var citizen = await GetCitizenAsync(GetUserId());
            if (citizen == null) return;

            var roomId = GetRoomId(citizen.Id, partnerCitizenId);
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, roomId);
        }

        public async Task SendMessage(int toCitizenId, string message)
        {
            var citizen = await GetCitizenAsync(GetUserId())
                ?? throw new HubException("Citizen not found.");

            _db.Messages.Add(new ChatMessage
            {
                FromCitizenId = citizen.Id,
                ToCitizenId = toCitizenId,
                Content = message,
                SentAt = DateTime.UtcNow,
                Read = false
            });
            await _db.SaveChangesAsync();

            var sentAt = DateTime.UtcNow;
            var roomId = GetRoomId(citizen.Id, toCitizenId);
            await Clients.OthersInGroup(roomId).ReceiveMessage(citizen.Id, message, sentAt);

            var partnerUserId = await _db.Citizens
                .Where(c => c.Id == toCitizenId)
                .Select(c => c.UserId)
                .FirstOrDefaultAsync();

            if (partnerUserId != null)
            {
                await Clients.User(partnerUserId).NewConversationMessage(
                    citizen.Id,
                    $"{citizen.FirstName} {citizen.LastName}",
                    message,
                    sentAt
                );
            }
        }

        public async Task SendIncident(int toCitizenId, int incidentId)
        {
            var citizen = await GetCitizenAsync(GetUserId())
                ?? throw new HubException("Citizen not found.");

            var incident = await _db.Incidents
                .FirstOrDefaultAsync(i => i.Id == incidentId)
                ?? throw new HubException("Incident not found.");

            var sentAt = DateTime.UtcNow;

            _db.Messages.Add(new ChatMessage
            {
                FromCitizenId = citizen.Id,
                ToCitizenId = toCitizenId,
                Content = "",
                SentAt = sentAt,
                Read = false,
                SharedIncidentId = incidentId
            });
            await _db.SaveChangesAsync();

            var roomId = GetRoomId(citizen.Id, toCitizenId);

            var sharedIncident = new
            {
                id = incident.Id,
                title = incident.Title,
                description = incident.Description,
                status = incident.Status.ToString(),
                category = incident.Categories,
                location = incident.Location,
                photoUrl = incident.ImagesUrl[0]
            };

            await Clients.OthersInGroup(roomId).ReceiveIncident(citizen.Id, sharedIncident, sentAt);

            var partnerUserId = await _db.Citizens
                .Where(c => c.Id == toCitizenId)
                .Select(c => c.UserId)
                .FirstOrDefaultAsync();

            if (partnerUserId != null && !_tracker.IsInRoom(partnerUserId, roomId))
            {
                await Clients.User(partnerUserId).NewConversationMessage(
                    citizen.Id,
                    $"{citizen.FirstName} {citizen.LastName}",
                    "",
                    sentAt
                );
            }
        }

        public async Task Typing(int toCitizenId)
        {
            var citizen = await GetCitizenAsync(GetUserId());
            if (citizen == null) return;

            var roomId = GetRoomId(citizen.Id, toCitizenId);
            await Clients.OthersInGroup(roomId).PartnerTyping();
        }

        // ── Helpers ───────────────────────────────────────────────────────────

        private static string GetRoomId(int citizenA, int citizenB)
        {
            var ids = new[] { citizenA, citizenB };
            Array.Sort(ids);
            return $"dm_{ids[0]}_{ids[1]}";
        }

        private async Task<Citizen?> GetCitizenAsync(string userId) =>
            await _db.Citizens.FirstOrDefaultAsync(c => c.UserId == userId);

        private string GetUserId() =>
            Context.UserIdentifier ?? throw new HubException("User must be authenticated.");
    }
}