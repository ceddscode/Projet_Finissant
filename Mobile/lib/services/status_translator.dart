import '../generated/l10n.dart';

/// Backend Status enum:
/// 0 = WaitingForValidation
/// 1 = WaitingForAssignation
/// 2 = AssignedToCitizen (citizen took the task)
/// 3 = UnderRepair
/// 4 = Done
/// 5 = AssignedToBlueCollar
/// 6 = WaitingForAssignationToCitizen (available for citizens to take)
/// 7 = WaitingForConfirmation
class StatusTranslator {
  static String translate(int status, S s) {
    switch (status) {
      case 0:
        return s.waitingForValidation;
      case 1:
        return s.waitingAssignment;
      case 2:
        return s.assignedToCitizen;
      case 3:
        return s.underRepair;
      case 4:
        return s.done;
      case 5:
        return s.assignedBlueCollar;
      case 6:
        return s.availableForCitizens;
      case 7:
        return s.waitingForConfirmation;
      default:
        return "Statut inconnu";
    }
  }
}
