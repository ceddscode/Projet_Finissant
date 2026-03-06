using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models
{
    public class IncidentSubscription
    {
        public int Id { get; set; }

        public int IncidentId { get; set; }
        public Incident Incident { get; set; }

        public string UserId { get; set; }

        public User User { get; set; }
        public bool IsMandatory { get; set; }

       }
}
