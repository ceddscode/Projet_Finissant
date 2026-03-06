using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Models.Models.Enums;

namespace Models.Models.DTOs
{
    public class ReportIncident
    {
        [Required]
        [StringLength(100, MinimumLength = 5)]
        public string Title { get; set; }

        public string? Description { get; set; }

        [Required]
        [MinLength(1)]
        [MaxLength(10)]
        public List<string> ImagesUrl { get; set; }

        [Required]
        [StringLength(100)]
        public string Location { get; set; }

        [Required]
        public Category Category { get; set; }

        [Required]
        public double Latitude { get; set; }

        [Required]
        public double Longitude { get; set; }
        public string? Quartier { get; set; }

    }
}
