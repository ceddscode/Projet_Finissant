using System.Collections.Generic;
using System.Security.Claims;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Models.Models;
using Models.Models.DTOs;
using Models.Models.Enums;
using municipaligo_serveur.Data;
using WebApi.Interfaces;

namespace WebApi.Services
{
    public class IncidentService : IIncidentService
    {

        private readonly UserManager<User> _userManager;
        private ApplicationDbContext _context;
        private INotificationsService _notificationsService;
        private readonly BadgeService _badgeService;
        public IncidentService(ApplicationDbContext context, UserManager<User> userManager, INotificationsService notificationsService, BadgeService badgeService)
        {
            _context = context;
            _userManager = userManager;
            _notificationsService = notificationsService;
            _badgeService = badgeService;
        }

        public async Task AddToHistoryAsync(int incidentId, InterventionType interventionType, string userId)
        {
            if (incidentId < 0 || incidentId == null)
                throw new ArgumentException("IncidentId invalide.");

            if (string.IsNullOrWhiteSpace(userId))
                throw new ArgumentException("UserId est requis.");

            if (!Enum.IsDefined(typeof(InterventionType), interventionType))
                throw new ArgumentException("InterventionType invalide.");

            var incidentExists = await _context.Incidents
                .AnyAsync(i => i.Id == incidentId);

            if (!incidentExists)
                throw new InvalidOperationException("Incident inexistant.");

            var userExists = await _context.Users
            .AnyAsync(u => u.Id == userId);

            if (!userExists)
                throw new InvalidOperationException("User inexistant");

            IncidentHistory incidentHistory = new IncidentHistory(0, userId, incidentId, interventionType, DateTime.UtcNow);

            await _context.IncidentHistories.AddAsync(incidentHistory);
            await _context.SaveChangesAsync();
        }

        private async Task ChangeStatusAndNotify(Incident incident, Status newStatus, string? assignedUserId = null)
        {
            var oldStatus = incident.Status;
            incident.Status = newStatus;
            await _context.SaveChangesAsync();

            if (oldStatus != newStatus)
            {
                await _notificationsService.SendStatusChangeNotification(incident.Id, newStatus, assignedUserId);
            }
        }
        public async Task<List<Incident>> GetNotValidatedIncidents()
        {
            return await _context.Incidents.Where(i => i.Status == Status.WaitingForValidation).ToListAsync();
        }
     
        public async Task<List<IncidentListDTO>> GetValidatedIncidents(string? userId)
        {
            var citizen = await _context.Citizens
                .FirstOrDefaultAsync(c => c.UserId == userId);

            return await _context.Incidents
                .Where(i => i.Status != Status.WaitingForValidation)
                .Select(i => new IncidentListDTO
                {
                    Id = i.Id,
                    Title = i.Title,
                    Location = i.Location,
                    CreatedAt = i.CreatedAt,
                    ImagesUrl = i.ImagesUrl,
                    Status = i.Status,
                    Category = i.Categories,
                    Latitude = i.Latitude,
                    Longitude = i.Longitude,
                    Quartier = i.Quartier,
                    IsLiked = citizen != null &&
                        _context.IncidentLikes
                            .Any(l => l.IncidentId == i.Id && l.CitizenId == citizen.Id),
                    LikeCount = i.LikeCount
                })
                .ToListAsync();
        }
        public async Task<List<IncidentListDTO>> GetAllIncidents(string? userId)
        {
            var citizen = await _context.Citizens
                 .FirstOrDefaultAsync(c => c.UserId == userId);

            return await _context.Incidents
                .Select(i => new IncidentListDTO
                {
                    Id = i.Id,
                    Title = i.Title,
                    Location = i.Location,
                    CreatedAt = i.CreatedAt,
                    ImagesUrl = i.ImagesUrl,
                    Status = i.Status,
                    Category = i.Categories,
                    Latitude = i.Latitude,
                    Longitude = i.Longitude,
                    Quartier = i.Quartier,
                    IsLiked = citizen != null &&
                        _context.IncidentLikes
                            .Any(l => l.IncidentId == i.Id && l.CitizenId == citizen.Id),
                    LikeCount = i.LikeCount
                })
                .ToListAsync();
        }

        public async Task<List<IncidentListDTO>> GetIncidentsNotAssigned(string? userId)
        {
            var citizen = await _context.Citizens
                 .FirstOrDefaultAsync(c => c.UserId == userId);

            return await _context.Incidents
                .Where(i => i.Status == Status.WaitingForAssignation)
                .Select(i => new IncidentListDTO
                {
                    Id = i.Id,
                    Title = i.Title,
                    Location = i.Location,
                    CreatedAt = i.CreatedAt,
                    ImagesUrl = i.ImagesUrl,
                    Status = i.Status,
                    Category = i.Categories,
                    Latitude = i.Latitude,
                    Longitude = i.Longitude,
                    Quartier = i.Quartier,
                    IsLiked = citizen != null &&
                        _context.IncidentLikes
                            .Any(l => l.IncidentId == i.Id && l.CitizenId == citizen.Id),
                    LikeCount = i.LikeCount
                })
                .ToListAsync();
        }

         public async Task<IncidentConfirmationDetailsDTO?> GetIncidentConfirmationDetails(int id)
        {
            return await _context.Incidents
                .Where(i => i.Id == id)
                .Select(i => new IncidentConfirmationDetailsDTO
                {
                    Id = i.Id,
                    Title = i.Title,
                    ImagesUrl = i.ImagesUrl,
                    Location = i.Location,
                    CreatedDate = i.CreatedAt,
                    ConfirmationDescription = i.ConfirmationDescription,
                    ConfirmationImagesUrl = i.ConfirmationImagesUrl,
                    Category = i.Categories,
                    LikeCount = i.LikeCount,
                    Quartier= i.Quartier
                    
                })
                .FirstOrDefaultAsync();
        }

        public async Task<List<Incident>> GetIncidentsAssignedToCitizen()
        {
            return await _context.Incidents.Where(i => i.Status == Status.AssignedToCitizen).ToListAsync();
        }

        public async Task<List<Incident>> GetIncidentsUnderRepair()
        {
            return await _context.Incidents.Where(i => i.Status == Status.UnderRepair).ToListAsync();
        }

        public async Task<List<IncidentDetailsDTO>?> GetIncidentsNotConfirmed()
        {
            return await _context.Incidents.Where(i => i.Status == Status.WaitingForConfirmation)
                .Select(i => new IncidentDetailsDTO
                {
                    Id = i.Id,
                    Title = i.Title,
                    Location = i.Location,
                    CreatedDate = i.CreatedAt,
                    Description = i.Description,
                    ImagesUrl = i.ImagesUrl,
                    Status = i.Status,
                    CitizenId = i.Citizen.UserId,
                    Category = i.Categories,
                    IsLiked = false,
                    LikeCount = i.LikeCount,
                    Quartier = i.Quartier,
                    Points=i.Points
                })
                .ToListAsync();
        }

        public async Task<List<Incident>> GetIncidentsDone()
        {
            return await _context.Incidents.Where(i => i.Status == Status.Done).ToListAsync();
        }

        public async Task<IncidentDetailsDTO?> GetIncidentDetails(int id, string? userId)
        {

            var citizen = await _context.Citizens
            .FirstOrDefaultAsync(c => c.UserId == userId);

            return await _context.Incidents
                .Where(i => i.Id == id)
                .Select(i => new IncidentDetailsDTO
                {
                    Id = i.Id,
                    Title = i.Title,
                    Location = i.Location,
                    CreatedDate = i.CreatedAt,
                    Description = i.Description,
                    ImagesUrl = i.ImagesUrl,
                    Status = i.Status,
                    CitizenId = i.Citizen.UserId,
                    Category = i.Categories,

                    IsLiked = citizen != null &&
                    _context.IncidentLikes
                    .Any(l => l.IncidentId == i.Id && l.CitizenId == citizen.Id),
                    LikeCount = i.LikeCount,
                    Quartier = i.Quartier,
                    ConfirmationDescription = i.ConfirmationDescription,
                    ConfirmationImagesUrl = i.ConfirmationImagesUrl,
                    Points=i.Points
                })
                .FirstOrDefaultAsync();
        }


        public async Task<List<IncidentListDTO>?> GetMyAssignedIncidents(string userId)
        {
            var citizen = await _context.Citizens
                .FirstOrDefaultAsync(c => c.UserId == userId);

            return await _context.Incidents.Where(i => i.Citizen.UserId == userId).Select(i => new IncidentListDTO
            {
                Id = i.Id,
                Title = i.Title,
                Location = i.Location,
                CreatedAt = i.CreatedAt,
                ImagesUrl = i.ImagesUrl,
                Status = i.Status,
                Category = i.Categories,
                Latitude = i.Latitude,
                Longitude = i.Longitude,
                Quartier = i.Quartier,
                IsLiked = citizen != null &&
                        _context.IncidentLikes
                            .Any(l => l.IncidentId == i.Id && l.CitizenId == citizen.Id),
                LikeCount = i.LikeCount
            }).ToListAsync();
        }

        public async Task<List<IncidentListDTO>> GetMySubbedIncidents(string userId)
        {
            var citizenId = await _context.Citizens
                .Where(c => c.UserId == userId)
                .Select(c => (int?)c.Id)
                .FirstOrDefaultAsync();

            return await _context.IncidentSubscriptions
                .Where(s => s.UserId == userId)
                .Select(s => s.Incident)
                .Select(i => new IncidentListDTO
                {
                    Id = i.Id,
                    Title = i.Title,
                    Location = i.Location,
                    CreatedAt = i.CreatedAt,
                    ImagesUrl = i.ImagesUrl,
                    Status = i.Status,
                    Category = i.Categories,
                    Latitude = i.Latitude,
                    Longitude = i.Longitude,
                    Quartier = i.Quartier,
                    IsLiked = citizenId != null &&
                        _context.IncidentLikes.Any(l => l.IncidentId == i.Id && l.CitizenId == citizenId.Value),

                    LikeCount = i.LikeCount
                })
                .ToListAsync();
        }

        public async Task PostIncident(Incident incident)
        {
            if(incident == null)
                throw new ArgumentNullException(nameof(incident));

            if (incident.Status != Status.WaitingForValidation)
                throw new InvalidOperationException("L'incident doit avoir le status WaitingForValidation lors de sa création");

            var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                await _context.Incidents.AddAsync(incident);
                await _context.SaveChangesAsync();

                if (!string.IsNullOrEmpty(incident.CitizenUserId))
                {
                    var userExists = await _context.Users
                        .AnyAsync(u => u.Id == incident.CitizenUserId);

                    if (!userExists)
                        throw new InvalidOperationException("Le citoyen n'existe pas");

                    await _notificationsService
                        .CreateMandatorySubscription(incident.Id, incident.CitizenUserId);
                }

                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }

        }

        public async Task EditIncident(int incidentId, EditIncidentDTO Dto)
        {
            var incident = await _context.Incidents.FindAsync(incidentId);
            if (incident == null)
                return;
            if (Dto.Title != null)
                incident.Title = Dto.Title;
            if (Dto.Description != null)
                incident.Description = Dto.Description;
            if (Dto.Categories != null )
                incident.Categories = Dto.Categories;

            _context.Update(incident);
            await _context.SaveChangesAsync();
        }
 
        public async Task DeleteIncidentAsync(int id)
        {
            var incident = await _context.Incidents.FindAsync(id);

            if (incident == null)
                return;

            _context.Incidents.Remove(incident);
            await _context.SaveChangesAsync();
        }

        public async Task<bool> IncidentExists(int id)
        {
            return await _context.Incidents.AnyAsync(e => e.Id == id);
        }

        public async Task<bool> AssignToBlueCollarAsync(int incidentId)
        {
            var incident = await _context.Incidents.FindAsync(incidentId);

            if (incident == null)
                return false;

            var blueCollarsIds = (await _userManager.GetUsersInRoleAsync("Blue collar")).Select(u => u.Id).ToList();

            var citizen = await _context.Citizens.Include(c => c.Taches).Where(c => blueCollarsIds.Contains(c.UserId)).OrderBy(c => c.Taches.Count).FirstOrDefaultAsync();

            if (citizen == null)
                return false;

            incident.AssignedAt = DateTime.UtcNow;
            incident.Citizen = citizen;
            citizen.Taches.Add(incident);

            await _notificationsService.CreateMandatorySubscription(incidentId, citizen.UserId);
            incident.Status = Status.AssignedToBlueCollar;
            await _context.SaveChangesAsync();
            await _notificationsService.SendAssignmentNotification(incidentId, citizen.UserId);

            return true;
        }

        public async Task<bool> ApproveIncidentAsync(int incidentId, int points)
        {
            var incident = await _context.Incidents
                .FirstOrDefaultAsync(i => i.Id == incidentId);

            if (incident == null)
                return false;

            incident.Points = points;

            if (!string.IsNullOrEmpty(incident.CitizenUserId))
            {
                var citizen = await _context.Citizens
                    .FirstOrDefaultAsync(c => c.UserId == incident.CitizenUserId);

                if (citizen != null)
                {
                    citizen.Points += points;
                    await _badgeService.CheckLevelUpAsync(citizen.Id);
                }
            }

            await ChangeStatusAndNotify(incident, Status.WaitingForAssignation);
            incident.AssignedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ConfirmIncidentAsync(int incidentId)
        {
            var incident = await _context.Incidents.FindAsync(incidentId);

            if (incident == null)
                return false;

            incident.ClosedAt = DateTime.UtcNow;
            await ChangeStatusAndNotify(incident, Status.Done);
            return true;
        }

        public async Task<bool> RefuseIncidentAsync(int incidentId, string description)
        {
            var incident = await _context.Incidents.FindAsync(incidentId);

            if (incident == null)
                return false;

            incident.ConfirmationDescription = "";
            incident.RefusalDescription = description;
            incident.ConfirmationImagesUrl = [];

            await ChangeStatusAndNotify(incident, Status.UnderRepair);
            return true;
        }

        public async Task<bool> AssignIncidentToCitizenAsync(int incidentId)
        {
            var incident = await _context.Incidents.FindAsync(incidentId);

            if (incident == null)
                return false;

            incident.AssignedAt = DateTime.UtcNow;


            await ChangeStatusAndNotify(incident, Status.WaitingForAssignationToCitizen);
            return true;
        }

        public async Task<bool> CitizenTakeTaskAsync(int incidentId, Citizen citizen)
        {
            var incident = await _context.Incidents.FindAsync(incidentId);

            if (incident == null) 
                return false;

            incident.Citizen = citizen;
            incident.CitizenUserId = citizen.UserId;
            citizen.Taches.Add(incident);

            await _notificationsService.CreateMandatorySubscription(incidentId, citizen.UserId);

            await ChangeStatusAndNotify(incident, Status.AssignedToCitizen);
            return true;
        }

        public async Task<bool> ConfirmationImagesSubmission(int incidentId, List<string> confirmationImagesUrls, string? description, string userId)
        {
            var incident = await _context.Incidents.FindAsync(incidentId);
            if (incident == null) return false;

            incident.ConfirmationDescription = description;

            incident.ConfirmationImagesUrl ??= new List<string>();

            foreach (var img in confirmationImagesUrls)
                incident.ConfirmationImagesUrl.Add(img);

            await ChangeStatusAndNotify(incident, Status.WaitingForConfirmation);

            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<bool> ChangeTaskStatusToUnderRepair(int incidentId, Citizen citizen)
        {
            var incident = await _context.Incidents.FindAsync(incidentId);

            if (incident == null || incident.Citizen.UserId != citizen.UserId)
                return false;

            incident.Status = Status.UnderRepair;

        incident.InProgressAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<PagedResult<SortedIncidentsDTO>> GetSortedNotAssignedIncidents(QueryParametersDTO filter, bool isAdmin)
        {
            var baseQuery = _context.Incidents.AsNoTracking().Where(t => t.Status == Status.WaitingForAssignation);

            return await GetSortedIncidents(filter, isAdmin, baseQuery);
        }

        public async Task<PagedResult<SortedIncidentsDTO>> GetSortedNotValidatedIncidents(QueryParametersDTO filter, bool isAdmin)
        {
            var baseQuery = _context.Incidents.AsNoTracking().Where(t => t.Status == Status.WaitingForValidation);

            return await GetSortedIncidents(filter, isAdmin, baseQuery);
        }

        public async Task<Incident?> GetIncident(int id)
        {
            return await _context.Incidents.FirstOrDefaultAsync(i => i.Id == id);
        }

        public async Task<PagedResult<SortedIncidentsDTO>> GetSortedIncidents(QueryParametersDTO filter, bool isAdmin, IQueryable<Incident>? baseQuery = null)
        {
            if (!isAdmin)
            {
                filter.DateEnd = null;
                filter.DateFrom = null;
                filter.ClosingDate = null;
                filter.CreationDate = null;
            }

            var query = BuildFilteredQuery(filter, baseQuery);

            var totalCount = await query.CountAsync();

            var incidents = await query
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .Select(t => new SortedIncidentsDTO(t))
                .ToListAsync();

            return new PagedResult<SortedIncidentsDTO>
            {
                Incidents = incidents,
                TotalCount = totalCount,
                Page = filter.Page,
                PageSize = filter.PageSize
            };
        }

        private IQueryable<Incident> BuildFilteredQuery(QueryParametersDTO filter, IQueryable<Incident>? baseQuery = null)
        {
            if (filter.DateFrom.HasValue)
                filter.DateFrom = DateTime.SpecifyKind(filter.DateFrom.Value, DateTimeKind.Utc);
            if (filter.DateEnd.HasValue)
                filter.DateEnd = DateTime.SpecifyKind(filter.DateEnd.Value, DateTimeKind.Utc);

            var query = baseQuery ?? _context.Incidents.AsNoTracking().AsQueryable();

            if (filter.Category.HasValue)
                query = query.Where(t => t.Categories == filter.Category);

            if (filter.Status.HasValue)
                query = query.Where(t => t.Status == filter.Status);

            if (!string.IsNullOrWhiteSpace(filter.Search))
            {
                var term = filter.Search.Trim();
                var pattern = $"%{term.Replace(" ", "%")}%";

                query = query.Where(t =>
                    
                    t.Title.ToLower().Contains(term.ToLower()) ||
                    t.Location.ToLower().Contains(term.ToLower())
                );
            }

            if (filter.DateFrom.HasValue || filter.DateEnd.HasValue)
            {
                if (filter.FilterByCreation)
                {
                    if (filter.DateFrom.HasValue)
                        query = query.Where(t => t.CreatedAt >= filter.DateFrom.Value);
                    if (filter.DateEnd.HasValue)
                        query = query.Where(t => t.CreatedAt < filter.DateEnd.Value.AddDays(1));
                }
                else if (filter.FilterByClosing)
                {
                    if (filter.DateFrom.HasValue)
                        query = query.Where(t => t.ClosedAt.HasValue && t.ClosedAt.Value >= filter.DateFrom.Value);
                    if (filter.DateEnd.HasValue)
                        query = query.Where(t => t.ClosedAt.HasValue && t.ClosedAt.Value < filter.DateEnd.Value.AddDays(1));
                }
            }

            return filter.Sort switch
            {
                "ClosedAt" => filter.Direction == "asc" ? query.OrderBy(e => e.ClosedAt) : query.OrderByDescending(e => e.ClosedAt),
                "Categories" => filter.Direction == "asc" ? query.OrderBy(e => e.Categories) : query.OrderByDescending(e => e.Categories),
                "Status" => filter.Direction == "asc" ? query.OrderBy(e => e.Status) : query.OrderByDescending(e => e.Status),
                "LikeCount" => filter.Direction == "asc" ? query.OrderBy(e => e.LikeCount) : query.OrderByDescending(e => e.LikeCount),
                "Quartier" => filter.Direction == "asc" ? query.OrderBy(e => e.Quartier) : query.OrderByDescending(e => e.Quartier),
                _ => filter.Direction == "asc" ? query.OrderBy(e => e.CreatedAt) : query.OrderByDescending(e => e.CreatedAt),
            };
        }

        public async Task<List<string>> GetQuartiers()
        {
            return await _context.Incidents
                .Where(i => i.Quartier != null && i.Quartier != "")
                .Select(i => i.Quartier!)
                .Distinct()
                .OrderBy(x => x)
                .ToListAsync();
        }

        public async Task Like(string userId, int incidentId)
        {
            var citizen = await _context.Citizens
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (citizen == null)
                throw new Exception("Citizen not found");

            var incident = await _context.Incidents.Where(a => a.Id == incidentId).FirstOrDefaultAsync();

            var like = await _context.IncidentLikes
                .FirstOrDefaultAsync(l =>
                    l.CitizenId == citizen.Id &&
                    l.IncidentId == incidentId);

            if (like == null && incident != null)
            {
                incident.LikeCount++;

                _context.IncidentLikes.Add(new IncidentLike
                {
                    CitizenId = citizen.Id,
                    IncidentId = incidentId
                });
            }
            else
            {
                _context.IncidentLikes.Remove(like);
            }

            await _context.SaveChangesAsync();
        }

        public async Task<List<IncidentHistoryDTO>> GetIncidentHistory(int incidentId)
        {
            List<IncidentHistory> incidentHistories = await _context.IncidentHistories.Where(i => i.IncidentId == incidentId).OrderByDescending(i => i.UpdatedAt).ToListAsync();
            List<IncidentHistoryDTO> incidentHistoryDTOs = [];
            foreach(var incidentHistory in incidentHistories)
            {
                string firstName = await _context.Citizens.Where(i => i.UserId == incidentHistory.UserId).Select(i => i.FirstName).FirstOrDefaultAsync();
                string lastName = await _context.Citizens.Where(i => i.UserId == incidentHistory.UserId).Select(i => i.LastName).FirstOrDefaultAsync();
                string userName = firstName + " " + lastName;
                bool isAnonymous = await _context.Users.Where(i => i.Id == incidentHistory.UserId).Select(i => i.IsAnonymous).FirstOrDefaultAsync();
                string? refusDescription = await _context.Incidents.Where(i => i.Id == incidentHistory.IncidentId).Select(i => i.RefusalDescription).FirstOrDefaultAsync();
                string roleUtilisateur = await _context.UserRoles.Where(i => i.UserId == incidentHistory.UserId).Select(i => i.RoleId).FirstOrDefaultAsync();
                List<string>? confirmationImgUrls = await _context.Incidents.Where(i => i.Id == incidentHistory.IncidentId).Select(i => i.ConfirmationImagesUrl).FirstOrDefaultAsync();
                incidentHistoryDTOs.Add(new IncidentHistoryDTO(userName, incidentHistory.InterventionType, incidentHistory.UpdatedAt, refusDescription, confirmationImgUrls, roleUtilisateur, null, null, isAnonymous));
            }
            return incidentHistoryDTOs;
        }

        public async Task<List<IncidentHistoryDTO>> GetMyIncidentHistory(string userId)
        {
            List<IncidentHistory> incidentHistories = await _context.IncidentHistories.Where(i => i.UserId == userId).OrderByDescending(i => i.UpdatedAt).ToListAsync();
            List<IncidentHistoryDTO> incidentHistoryDTOs = [];
            foreach (var incidentHistory in incidentHistories)
            {
                string? refusDescription = await _context.Incidents.Where(i => i.Id == incidentHistory.IncidentId).Select(i => i.RefusalDescription).FirstOrDefaultAsync();
                List<string>? confirmationImgUrls = await _context.Incidents.Where(i => i.Id == incidentHistory.IncidentId).Select(i => i.ConfirmationImagesUrl).FirstOrDefaultAsync();
                string? titreIncident = await _context.Incidents.Where(i => i.Id == incidentHistory.IncidentId).Select(i => i.Title).FirstOrDefaultAsync();
                incidentHistoryDTOs.Add(new IncidentHistoryDTO(null, incidentHistory.InterventionType, incidentHistory.UpdatedAt, refusDescription, confirmationImgUrls, null, titreIncident, incidentHistory.IncidentId, null));
            }
            return incidentHistoryDTOs;
        }
    }
}
