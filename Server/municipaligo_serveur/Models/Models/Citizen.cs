using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Models.Models.Enums;
using NuGet.Packaging;

namespace Models.Models
{
    public class Citizen
    {
        public int Id { get; set; }

        public string FirstName { get; set; }

        public string LastName { get; set; }

        public int RoadNumber { get; set; }

        public string UserId { get; set; } = null!;

        public User User { get; set; } = null!;

        public string RoadName { get; set; }

        public string PostalCode { get; set; }

        public string City { get; set; }

        public int Points { get; set; }

        
        [JsonIgnore]
        public List<ChatMessage> SentMessages { get; set; } = new();
        [JsonIgnore]
        public List<ChatMessage> ReceivedMessages { get; set; } = new();

        [JsonIgnore]
        public List<Incident> Taches { get; set; } = new List<Incident>();

        public List<IncidentSubscription> Subscriptions { get; set; } = new();
        public List<Comment> Comments { get; set; }
        public List<LikedComment> LikedComments { get; set; }
        public List<ReportComment> ReportComments { get; set; }

        public List<CitizenBadge> CitizenBadges { get; set; } = new();
    }
}
