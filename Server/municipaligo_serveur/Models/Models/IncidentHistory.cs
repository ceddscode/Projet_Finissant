using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Models.Models.Enums;

namespace Models.Models
{
    public class IncidentHistory
    {
        public IncidentHistory() { }
        public IncidentHistory(int id, string userId, int incidentId, InterventionType interventionType, DateTime updatedAt) 
        { 
            Id = id;
            UserId = userId;
            IncidentId = incidentId;
            InterventionType = interventionType;
            UpdatedAt = updatedAt;
        }
        public int Id { get; set; }
        public string UserId { get; set; }
        public virtual User User { get; set; }
        public int IncidentId { get; set; }
        public virtual Incident Incident { get; set; }
        public InterventionType InterventionType { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
