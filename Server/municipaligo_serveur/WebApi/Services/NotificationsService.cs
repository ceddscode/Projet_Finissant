using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Models.Models;
using Models.Models.Enums;
using municipaligo_serveur.Data;
using Models.Models.DTOs;
using FirebaseAdmin.Messaging;


namespace WebApi.Services
{
    public class NotificationsService : INotificationsService
    {
        private ApplicationDbContext _context;
        private readonly IHttpContextAccessor _http;

        public NotificationsService(ApplicationDbContext context, IHttpContextAccessor http)
        {
            _context = context;
            _http = http;
        }

        // method pour sauvegarder le device token
        public async Task<bool> SaveDeviceToken([FromBody] DeviceTokenDTO dto)
        {
            var userId = _http.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return false;
            }

            var existing = await _context.DeviceTokens.FirstOrDefaultAsync(a => a.UserId == userId);
            if (existing == null)
            {
                _context.DeviceTokens.Add(new DeviceToken
                {
                    UserId = userId,
                    Token = dto.DeviceToken,
                    UpdatedAt = DateTime.UtcNow,
                    Language = dto.Language ?? "fr"
                });
            }
            else
            {
                 existing.Token = dto.DeviceToken;
                existing.UpdatedAt = DateTime.UtcNow;
                existing.Language = dto.Language ?? "fr";
            }

            await _context.SaveChangesAsync();
            return true;

        }



        public async Task SendStatusChangeNotification(int incidentId, Status newStatus, string? assignedUserId = null)
        {
            try
            {

                var incident = await _context.Incidents.FirstOrDefaultAsync(i => i.Id == incidentId);
                if (incident == null) {
                    //not found
                    return;
                }


                var subscribers = await _context.IncidentSubscriptions.Where(i => i.IncidentId == incidentId).Join(_context.DeviceTokens, sub => sub.UserId, token => token.UserId, (sub, token) => new { sub.UserId, token.Token, token.Language })
                    .Where(i => !string.IsNullOrEmpty(i.Token)).ToListAsync();
                if (!subscribers.Any())
                {
                    //no subsrcibers
                    return;
                }


                var statusMessage = subscribers.Select(sub =>
                {
                    var lang = sub.Language;
                    var status = TranslateStatus(newStatus, lang);
                    var title = lang == "en" ? $"Incident #{incidentId} - Update" : $"Incident #{incidentId} - Mise à jour";
                    var body = lang == "en" ? $"{incident.Title}\nStatus: {status}" : $"{incident.Title}\nStatus: {status} ";


                    return new Message
                    {
                        Token = sub.Token,
                        Notification = new Notification { Title = title, Body = body },
                        Data = new Dictionary<string, string>
                    {
                        { "incidentId", incidentId.ToString() },
                        { "status", ((int)newStatus).ToString() }
                    },
                        Android = new AndroidConfig
                        {
                            Priority = Priority.High,
                            Notification = new AndroidNotification
                            {
                                ChannelId = "municipaligo_channel",
                                Sound = "default"
                            }
                        }
                    };
                }).ToList();
                await FirebaseMessaging.DefaultInstance.SendEachAsync(statusMessage);

            }


            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
            }


        }
        private string TranslateStatus(Status status, string language)
        {
            if (language == "en")
            {
                return status switch
                {
                    Status.WaitingForValidation => "Waiting for validation",
                    Status.WaitingForAssignation => "Waiting for assignment",
                    Status.WaitingForAssignationToCitizen => "Waiting for citizen assignment",
                    Status.AssignedToCitizen => "Assigned to citizen",
                    Status.AssignedToBlueCollar => "Assigned to blue collar",
                    Status.UnderRepair => "Under repair",
                    Status.WaitingForConfirmation => "Waiting for confirmation",
                    Status.Done => "Done",
                    _ => "Updated"
                };
            }
            else
            {
                return status switch
                {
                    Status.WaitingForValidation => "En attente de validation",
                    Status.WaitingForAssignation => "En attente d'assignation",
                    Status.WaitingForAssignationToCitizen => "En attente d'assignation à un citoyen",
                    Status.AssignedToCitizen => "Assigné à un citoyen",
                    Status.AssignedToBlueCollar => "Assigné à un col bleu",
                    Status.UnderRepair => "En réparation",
                    Status.WaitingForConfirmation => "En attente de confirmation",
                    Status.Done => "Terminé",
                    _ => "Mis à jour"
                };
            }
        }

        // get
        public async Task<(bool isSubscribed, bool isMandatory)?> GetSubscriptionInfo(int incidentId)
        {
            var incident = await _context.Incidents.AnyAsync(i => i.Id == incidentId);
            if (!incident)
            {
                return null;
            }
            var userId = _http.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            {
                return null;
            }
            var existing = await _context.IncidentSubscriptions.FirstOrDefaultAsync(s => s.IncidentId == incidentId && s.UserId == userId);
            if (existing == null)
            {
                return (false, false);
            }
            else
            {
                return (true, existing.IsMandatory);
            }
            
        }


        // toggle subscribe or unsubscribe
        public async Task<(bool isSubscribed, bool isMandatory)?> ToggleSubscription(int incidentId)
        {
            var incident = await _context.Incidents.AnyAsync(i => i.Id == incidentId);
            if (!incident)
            {
                return null;
            }

            var userId = _http.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null)
            { 
                return null;
            }

            var existing = await _context.IncidentSubscriptions.FirstOrDefaultAsync(s => s.IncidentId == incidentId && s.UserId == userId);

            if (existing == null)
            {
                _context.IncidentSubscriptions.Add(new IncidentSubscription
                {
                    UserId = userId,
                    IncidentId = incidentId,
                    IsMandatory = false
                });
                await _context.SaveChangesAsync();
                return (true, false);
            }

            if (existing.IsMandatory)
            {
                return (true, true);
            }
            _context.IncidentSubscriptions.Remove(existing);
            await _context.SaveChangesAsync();
            return (false, false);
        }

        public async Task CreateMandatorySubscription(int incidentId, string userId)
        {
            var existing = await _context.IncidentSubscriptions.FirstOrDefaultAsync(s => s.IncidentId == incidentId && s.UserId == userId);

            if (existing == null)
            {
                _context.IncidentSubscriptions.Add(new IncidentSubscription
                {
                    UserId = userId,
                    IncidentId = incidentId,
                    IsMandatory = true
                });
                await _context.SaveChangesAsync();
            }
            else if (!existing.IsMandatory)
            {
                existing.IsMandatory = true;
                await _context.SaveChangesAsync();
            }
        }
        public async Task SendAssignmentNotification(int incidentId, string assignedUserId)
        {
            try
            {
                var incident = await _context.Incidents.FirstOrDefaultAsync(i => i.Id == incidentId);
                if (incident == null) return;

                var deviceToken = await _context.DeviceTokens.FirstOrDefaultAsync(d => d.UserId == assignedUserId);
                if (deviceToken == null || string.IsNullOrEmpty(deviceToken.Token)) return;

                var lang = deviceToken.Language ?? "fr";
                var title = lang == "en" ? "New Task Assigned" : "Nouvelle tâche assignée";
                var body = lang == "en"
                    ? $"You have been assigned to: {incident.Title}"
                    : $"Vous avez été assigné à: {incident.Title}";

                var message = new Message
                {
                    Token = deviceToken.Token,
                    Notification = new Notification { Title = title, Body = body },
                    Data = new Dictionary<string, string>
            {
                { "incidentId", incidentId.ToString() },
                { "type", "assignment" }
            },
                    Android = new AndroidConfig
                    {
                        Priority = Priority.High,
                        Notification = new AndroidNotification
                        {
                            ChannelId = "municipaligo_channel",
                            Sound = "default"
                        }
                    }
                };

                await FirebaseMessaging.DefaultInstance.SendAsync(message);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
            }
        }

    }
}
