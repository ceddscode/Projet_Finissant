using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models.Enums
{
    public enum InterventionType
    {
        Created,
        Validated,
        AssignedToCitizen,
        TaskTookByCitizen,
        AssignedToBlueCollar,
        UnderRepair,
        DoneRepairing,
        RefusedRepair,
        ApprovedRepair
    }
}
