using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Models.Models.Enums;

namespace Models.Models.DTOs
{
    public class IncidentHistoryDTO
    {
        public IncidentHistoryDTO(string nomUtilisateur, InterventionType interventionType, DateTime updatedAt, string? refusDescription, List<string>? confirmationImgUrls, string? roleUtilisateur, string? titreIncident, int? incidentId, bool? isAnonymous) 
        { 
            NomUtilisateur = nomUtilisateur;
            RoleUtilisateur = roleUtilisateur;
            IsAnonymous = isAnonymous;
            TitreIncident = titreIncident;
            InterventionType = interventionType;
            UpdatedAt = updatedAt;
            RefusDescription = refusDescription;
            ConfirmationImgUrls = confirmationImgUrls;
            IncidentId = incidentId;
        }

        public string? NomUtilisateur { get; set; }
        public string? RoleUtilisateur { get; set; }
        public bool? IsAnonymous { get; set; }
        public string? TitreIncident { get; set; }
        public int? IncidentId { get; set; }
        public InterventionType InterventionType { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string? RefusDescription { get; set; }
        public List<string>? ConfirmationImgUrls { get; set; }
    }
}
