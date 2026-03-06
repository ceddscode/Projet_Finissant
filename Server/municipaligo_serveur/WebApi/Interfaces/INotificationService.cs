using Models.Models.DTOs;
using Models.Models.Enums;

namespace WebApi.Services
{
    public interface INotificationsService
    {
        Task<bool> SaveDeviceToken(DeviceTokenDTO dto);
        Task SendStatusChangeNotification(int incidentId, Status newStatus, string? assignedUserId = null);
        Task<(bool isSubscribed, bool isMandatory)?> GetSubscriptionInfo(int incidentId);
        Task<(bool isSubscribed, bool isMandatory)?> ToggleSubscription(int incidentId);
        Task CreateMandatorySubscription(int incidentId, string userId);
        Task SendAssignmentNotification(int incidentId, string assignedUserId);
    }
}