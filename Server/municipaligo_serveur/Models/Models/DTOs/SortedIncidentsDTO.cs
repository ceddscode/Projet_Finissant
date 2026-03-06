using Models.Models.Enums;

namespace Models.Models.DTOs
{
    public class SortedIncidentsDTO
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Location { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime? ClosedDate { get; set; }
        public string ImageUrl { get; set; }
        public Status Status { get; set; }
        public Category Category { get; set; }
        public int LikeCount { get; set; }
        public string? Quartier { get; set; }

        public SortedIncidentsDTO(Incident t)
        {
            Id = t.Id;
            Title = t.Title;
            Location = t.Location;
            CreatedDate = t.CreatedAt;
            ClosedDate = t.ClosedAt;
            ImageUrl = t.ImagesUrl.FirstOrDefault() ?? string.Empty;
            Status = t.Status;
            Category = t.Categories;
            LikeCount = t.LikeCount;
            Quartier = t.Quartier;
        }
    }
}