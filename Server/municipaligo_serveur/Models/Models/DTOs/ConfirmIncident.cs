using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models.DTOs
{
    public class ConfirmIncident
    {
        [Required]
        public int IncidentId { get; set; }
        public string? Description { get; set; }

        [Required]
        [MinLength(1)]
        [MaxLength(10)]
        public List<String> ImagesUrl { get; set; }
    }
}
