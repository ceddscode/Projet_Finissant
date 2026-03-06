using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Models.Models.Enums
{
    public enum Status
    {
        WaitingForValidation ,
        WaitingForAssignation,
        AssignedToCitizen,
        UnderRepair,
        Done,
        AssignedToBlueCollar,
        WaitingForAssignationToCitizen,
        WaitingForConfirmation
    }
}
