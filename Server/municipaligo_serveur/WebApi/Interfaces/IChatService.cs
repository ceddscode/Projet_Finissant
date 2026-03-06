using Models.Models.DTOs;

namespace WebApi.Interfaces
{
    public interface IChatService
    {
        Task<IEnumerable<ConversationDto>> GetConversationsAsync(string userId);
        Task<IEnumerable<MessageDto>> GetMessagesAsync(string userId, int partnerCitizenId, int page, int pageSize);
        Task<IEnumerable<CitizenDTO>> SearchUsersAsync(string userId, string? search);
        Task MarkMessagesAsReadAsync(string userId, int partnerCitizenId);
        Task HideConversationAsync(string userId, int partnerCitizenId);
    }
}