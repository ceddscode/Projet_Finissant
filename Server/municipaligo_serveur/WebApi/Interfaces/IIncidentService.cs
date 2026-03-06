using Models.Models;
using Models.Models.DTOs;
using Models.Models.Enums;

namespace WebApi.Interfaces
{
    public interface IIncidentService
    {
        Task<List<Incident>> GetNotValidatedIncidents();
        Task<List<IncidentListDTO>> GetValidatedIncidents(string? userId);
        Task<Incident?> GetIncident(int id);
        Task<List<IncidentListDTO>> GetAllIncidents(string? userId);
        Task<List<IncidentListDTO>> GetIncidentsNotAssigned(string? userId);
        Task<IncidentConfirmationDetailsDTO?> GetIncidentConfirmationDetails(int id);
        Task<List<Incident>> GetIncidentsAssignedToCitizen();
        Task<List<Incident>> GetIncidentsUnderRepair();
        Task<List<IncidentDetailsDTO>?> GetIncidentsNotConfirmed();
        Task<List<Incident>> GetIncidentsDone();
        Task<IncidentDetailsDTO?> GetIncidentDetails(int id, string? userId);
        Task<List<IncidentListDTO>?> GetMyAssignedIncidents(string userId);
        Task<List<IncidentListDTO>?> GetMySubbedIncidents(string userId);
        Task PostIncident(Incident incident);
        Task EditIncident(int incidentId, EditIncidentDTO Dto);
        Task DeleteIncidentAsync(int id);
        Task<bool> IncidentExists(int id);
        Task<List<string>> GetQuartiers();
        Task<bool> AssignToBlueCollarAsync(int incidentId);
        Task<bool> ApproveIncidentAsync(int incidentId, int points);
        Task<bool> ConfirmIncidentAsync(int incidentId);
        Task<bool> RefuseIncidentAsync(int incidentId, string description);
        Task<bool> AssignIncidentToCitizenAsync(int incidentId);
        Task<bool> CitizenTakeTaskAsync(int incidentId, Citizen citizen);
        Task<bool> ConfirmationImagesSubmission(int incidentId, List<string> confirmationImagesUrls, string? description, string userId);
        Task<bool> ChangeTaskStatusToUnderRepair(int incidentId, Citizen citizen);
        Task<PagedResult<SortedIncidentsDTO>> GetSortedNotAssignedIncidents(QueryParametersDTO filter, bool isAdmin);
        Task<PagedResult<SortedIncidentsDTO>> GetSortedNotValidatedIncidents(QueryParametersDTO filter, bool isAdmin);
        Task<PagedResult<SortedIncidentsDTO>> GetSortedIncidents(QueryParametersDTO filter, bool isAdmin, IQueryable<Incident>? baseQuery = null);
        Task Like(string userId, int incidentId);
        Task AddToHistoryAsync(int incidentId, InterventionType interventionType, string userId);
        Task<List<IncidentHistoryDTO>> GetIncidentHistory(int incidentId);
        Task<List<IncidentHistoryDTO>> GetMyIncidentHistory(string userId);
    }
}
