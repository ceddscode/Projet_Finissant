using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Models.Models.Enums;

namespace Models.Models.DTOs
{
    public class IncidentDetailsDTO
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Location { get; set; }
        public DateTime CreatedDate { get; set; }
        public string? Description { get; set; }
        public List<string> ImagesUrl { get; set; }
        public Status Status { get; set; }
        public string? CitizenId { get; set; }
        public Category Category { get; set; }

        public bool IsLiked { get; set; }

        public int LikeCount { get; set; }
        public string? Quartier { get; set; }

        public int? Points { get; set; }

        public string? ConfirmationDescription { get; set; }
        public List<string>? ConfirmationImagesUrl { get; set; }
    }
}
