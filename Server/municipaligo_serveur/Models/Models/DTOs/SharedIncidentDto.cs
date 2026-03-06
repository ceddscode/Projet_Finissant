using Models.Models.Enums;

namespace Models.Models.DTOs
{
    public record SharedIncidentDto(
        int Id,
        string Title,
        Status Status,
        Category Category,
        string Location,
        string? PhotoUrl
    );
}
