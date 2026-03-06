using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models.DTOs
{
    public class CitizenBadgeProfileDTO
    {
        public int Points { get; set; }
        public string CurrentLevelName { get; set; }
        public int CurrentLevelMinPoints { get; set; }
        public int? NextLevelMinPoints { get; set; }
        public int ProgressPercentage { get; set; }
        public List<BadgeDTO> Badges { get; set; }
    }
}
