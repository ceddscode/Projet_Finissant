using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models
{
    public class HiddenConversation
    {
        public int Id { get; set; }
        public int CitizenId { get; set; }
        public int PartnerCitizenId { get; set; }
        public DateTime HiddenAt { get; set; }
        public Citizen Citizen { get; set; } = null!;
    }
}
