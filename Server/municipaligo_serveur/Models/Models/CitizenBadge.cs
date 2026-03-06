using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models
{
    public class CitizenBadge
    {
        public int Id { get; set; }
        public int CitizenId { get; set; }
        public Citizen Citizen { get; set; }

        public int BadgeId { get; set; }
        public Badge Badge { get; set; }

        public DateTime EarnedAt { get; set; }
    }
}
