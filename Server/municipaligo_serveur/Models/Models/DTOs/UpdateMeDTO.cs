using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models.DTOs
{
    public class UpdateMeDto
    {
        public string? Email { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public int? RoadNumber { get; set; }
        public string? RoadName { get; set; }
        public string? PostalCode { get; set; }
        public string? City { get; set; }
        public bool? IsAnonymous { get; set; }
    }
}
