using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Models.Models.Enums;

namespace Models.Models.DTOs
{
    public class IncidentConfirmationDetailsDTO
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public List<string> ImagesUrl { get; set; }
        public string Location { get; set; }
        public DateTime CreatedDate { get; set; }
        public string? ConfirmationDescription { get; set; }
        public List<string> ConfirmationImagesUrl { get; set; }
        public Category Category { get; set; }
        public int LikeCount { get; set; }
        public string? Quartier { get; set; }
    }
}
