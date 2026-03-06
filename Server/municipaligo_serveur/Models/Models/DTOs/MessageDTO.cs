using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models.DTOs
{
    public record MessageDto(
        int FromCitizenId,
        string Message,
        DateTime SentAt,
        bool Read,
        SharedIncidentDto? SharedIncident
    );
}
