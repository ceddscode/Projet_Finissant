import 'package:municipalgo/models/intervention_type_enum.dart';

import '../generated/l10n.dart';


class InterventionTypeTranslator {
  static String translate(int interventionTypeIndex, S s) {
    InterventionTypeEnum interventionType;

    try {
      interventionType = InterventionTypeEnum.values[interventionTypeIndex];
    } catch (_) {
      return "Unknown";
    }

    switch (interventionType) {
      case InterventionTypeEnum.Created:
        return s.created;
      case InterventionTypeEnum.Validated:
        return s.validated;
      case InterventionTypeEnum.AssignedToCitizen:
        return s.assignedToCitizens;
      case InterventionTypeEnum.TaskTookByCitizen:
        return s.taskTookByCitizen;
      case InterventionTypeEnum.AssignedToBlueCollar:
        return s.assignedToBlueCollar;
      case InterventionTypeEnum.UnderRepair:
        return s.underRepair;
      case InterventionTypeEnum.DoneRepairing:
        return s.doneRepairing;
      case InterventionTypeEnum.RefusedRepair:
        return s.refusedRepair;
      case InterventionTypeEnum.ApprovedRepair:
        return s.approvedRepair;
    }
  }
}