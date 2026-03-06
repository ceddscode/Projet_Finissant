using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using Models.Models.Enums;

namespace Models.Models
{
    public class Incident
    {
        public Incident() { }
        public Incident(
            int id,
            string title,
            string description,
            string location,
            DateTime createdAt,
            DateTime? closedAt,
            Category category,
            Status status,
            DateTime? assignedAt,
            DateTime? inProgressAt,
            string? citizenUserId,
            Citizen? citizen,
            List<string> imagesUrl,
            List<string>? confirmationImagesUrl,
            string? confirmationDescription,
            string? refusalDescription,
            double latitude,
            double longitude,
            int likeCount,
            string? quartier)
        {
            Id = id;
            Title = title;
            Description = description;
            ConfirmationDescription = confirmationDescription;
            RefusalDescription = refusalDescription;
            Location = location;
            CreatedAt = createdAt;
            ClosedAt = closedAt;
            ImagesUrl = imagesUrl;
            ConfirmationImagesUrl = confirmationImagesUrl;
            Status = status;
            Categories = category;
            AssignedAt = assignedAt;
            InProgressAt = inProgressAt;
            Citizen = citizen;
            Longitude = longitude;
            Latitude = latitude;
            CitizenUserId = citizenUserId;
            LikeCount = likeCount;
            Quartier = quartier;
        }
        public int Id { get; set; }

        public string Title { get; set; }

        public string? Description { get; set; }

        public string Location { get; set; }

        public DateTime CreatedAt { get; set; }

        public DateTime? ClosedAt { get; set; }

        public Category Categories { get; set; }

        public Status Status { get; set; }

        public DateTime? AssignedAt { get; set; }

        public DateTime? InProgressAt { get; set; }

        public string? CitizenUserId { get; set; }
        public int? CitizenId { get; set; }

        [JsonIgnore]
        public Citizen? Citizen { get; set; }

        public List<string> ImagesUrl { get; set; } = new();

        public List<string>? ConfirmationImagesUrl { get; set; } = new();

        public string? ConfirmationDescription { get; set; }

        public string? RefusalDescription { get; set; }

        public double Latitude { get; set; }

        public double Longitude { get; set; } 
        public int LikeCount { get; set; }
        public  string? Quartier { get; set; }
        public int? Points { get; set; } 

    }
}
