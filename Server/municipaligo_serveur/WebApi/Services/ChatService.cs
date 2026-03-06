using Microsoft.EntityFrameworkCore;
using Models.Models;
using Models.Models.DTOs;
using municipaligo_serveur.Data;
using WebApi.Interfaces;

namespace WebApi.Services
{
    public class ChatService : IChatService
    {
        private readonly ApplicationDbContext _context;
        private readonly IUserConnectionTracker _tracker;

        public ChatService(ApplicationDbContext context, IUserConnectionTracker tracker)
        {
            _context = context;
            _tracker = tracker;
        }

        public async Task<IEnumerable<ConversationDto>> GetConversationsAsync(string userId)
        {
            var citizen = await GetCitizenAsync(userId);
            if (citizen == null) return Enumerable.Empty<ConversationDto>();

            var hiddenRecords = await _context.HiddenConversations
                .Where(h => h.CitizenId == citizen.Id)
                .ToListAsync();

            var hiddenDates = hiddenRecords
                .GroupBy(h => h.PartnerCitizenId)
                .ToDictionary(g => g.Key, g => g.Max(h => h.HiddenAt));

            var messages = await _context.Messages
                .Where(m => m.FromCitizenId == citizen.Id || m.ToCitizenId == citizen.Id)
                .Include(m => m.FromCitizen)
                .Include(m => m.ToCitizen)
                .OrderByDescending(m => m.SentAt)
                .ToListAsync();

            var conversations = messages
                .GroupBy(m => m.FromCitizenId == citizen.Id ? m.ToCitizenId : m.FromCitizenId)
                .Select(g =>
                {
                    var partnerId = g.Key;

                    // filter messages by hidden date if conversation was deleted
                    var visibleMessages = hiddenDates.TryGetValue(partnerId, out var hiddenAt)
                        ? g.Where(m => m.SentAt > hiddenAt).ToList()
                        : g.ToList();

                    // no messages after deletion yet — don't show conversation
                    if (!visibleMessages.Any()) return null;

                    var latest = visibleMessages.First();
                    var partner = latest.FromCitizenId == citizen.Id
                        ? latest.ToCitizen
                        : latest.FromCitizen;

                    var unread = visibleMessages.Count(m => m.ToCitizenId == citizen.Id && !m.Read);

                    return new ConversationDto(
                        CitizenId: partner.Id,
                        Name: $"{partner.FirstName} {partner.LastName}",
                        Online: _tracker.IsOnline(partner.UserId),
                        LastMessage: latest.Content,
                        LastMessageTime: latest.SentAt,
                        UnreadCount: unread
                    );
                })
                .Where(d => d != null)
                .Cast<ConversationDto>()
                .ToList();

            return conversations;
        }

        public async Task<IEnumerable<MessageDto>> GetMessagesAsync(string userId, int partnerCitizenId, int page, int pageSize)
        {
            var citizen = await GetCitizenAsync(userId);
            if (citizen == null) return Enumerable.Empty<MessageDto>();

            var hiddenAt = await _context.HiddenConversations
                .Where(h => h.CitizenId == citizen.Id && h.PartnerCitizenId == partnerCitizenId)
                .Select(h => (DateTime?)h.HiddenAt)
                .FirstOrDefaultAsync();

            var query = _context.Messages
                .Include(m => m.Incident)
                .Where(m =>
                    (m.FromCitizenId == citizen.Id && m.ToCitizenId == partnerCitizenId) ||
                    (m.FromCitizenId == partnerCitizenId && m.ToCitizenId == citizen.Id));

            if (hiddenAt.HasValue)
                query = query.Where(m => m.SentAt > hiddenAt.Value);

            return await query
                .OrderByDescending(m => m.SentAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .OrderBy(m => m.SentAt)
                .Select(m => new MessageDto(
                    m.FromCitizenId,
                    m.Content,
                    m.SentAt,
                    m.Read,
                    m.SharedIncidentId != null ? new SharedIncidentDto(
                        m.Incident!.Id,
                        m.Incident!.Title,
                        m.Incident!.Status,
                        m.Incident!.Categories,
                        m.Incident!.Location,
                        m.Incident!.ImagesUrl[0]
                    ) : null
                ))
                .ToListAsync();
        }

        public async Task<IEnumerable<CitizenDTO>> SearchUsersAsync(string userId, string? search)
        {
            var currentRole = await _context.UserRoles
                .Where(ur => ur.UserId == userId)
                .Join(_context.Roles, ur => ur.RoleId, r => r.Id, (ur, r) => r.Name)
                .FirstOrDefaultAsync();

            var targetRole = currentRole switch
            {
                "White collar" => "Blue collar",
                "Blue collar" => "White collar",
                _ => null
            };

            if (targetRole == null) return Enumerable.Empty<CitizenDTO>();

            var targetUserIds = await _context.UserRoles
                .Join(_context.Roles, ur => ur.RoleId, r => r.Id, (ur, r) => new { ur.UserId, r.Name })
                .Where(x => x.Name == targetRole)
                .Select(x => x.UserId)
                .ToListAsync();

            var query = _context.Citizens
                .Where(c => c.UserId != userId && targetUserIds.Contains(c.UserId));

            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(c =>
                    c.FirstName.Contains(search) || c.LastName.Contains(search));

            var citizens = await query
                .OrderBy(c => c.FirstName)
                .Take(20)
                .ToListAsync();

            return citizens.Select(c => new CitizenDTO(
                c.Id,
                $"{c.FirstName} {c.LastName}",
                _tracker.IsOnline(c.UserId)
            ));
        }

        public async Task HideConversationAsync(string userId, int partnerCitizenId)
        {
            var citizen = await GetCitizenAsync(userId);
            if (citizen == null) return;

            var existing = await _context.HiddenConversations
                .FirstOrDefaultAsync(h => h.CitizenId == citizen.Id && h.PartnerCitizenId == partnerCitizenId);

            if (existing != null)
            {
                // reset the cutoff date
                existing.HiddenAt = DateTime.UtcNow;
            }
            else
            {
                _context.HiddenConversations.Add(new HiddenConversation
                {
                    CitizenId = citizen.Id,
                    PartnerCitizenId = partnerCitizenId,
                    HiddenAt = DateTime.UtcNow
                });
            }

            await _context.SaveChangesAsync();
        }

        public async Task MarkMessagesAsReadAsync(string userId, int partnerCitizenId)
        {
            var citizen = await GetCitizenAsync(userId);
            if (citizen == null) return;

            var unread = await _context.Messages
                .Where(m => m.FromCitizenId == partnerCitizenId && m.ToCitizenId == citizen.Id && !m.Read)
                .ToListAsync();

            unread.ForEach(m => m.Read = true);
            await _context.SaveChangesAsync();
        }

        private async Task<Citizen?> GetCitizenAsync(string userId) =>
            await _context.Citizens.FirstOrDefaultAsync(c => c.UserId == userId);
    }
}