import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:municipalgo/models/intervention_type_enum.dart';

class InterventionTypeIcon extends StatelessWidget {
  final int? interventionTypeIndex;
  final double size;

  const InterventionTypeIcon({ super.key, required this.interventionTypeIndex, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;
    InterventionTypeEnum? interventionType;

    try {
      interventionType = InterventionTypeEnum.values[interventionTypeIndex!];
    } catch (_) {
      interventionType = null;
    }

    switch (interventionType) {
      case InterventionTypeEnum.Created:
        iconData = FontAwesomeIcons.circlePlus;
        color = Colors.blue;
        break;

      case InterventionTypeEnum.Validated:
        iconData = FontAwesomeIcons.circleCheck;
        color = Colors.green;
        break;

      case InterventionTypeEnum.AssignedToCitizen:
        iconData = FontAwesomeIcons.userTag;
        color = Colors.orange;
        break;

      case InterventionTypeEnum.TaskTookByCitizen:
        iconData = FontAwesomeIcons.hand;
        color = Colors.teal;
        break;

      case InterventionTypeEnum.AssignedToBlueCollar:
        iconData = FontAwesomeIcons.userGear;
        color = Colors.deepPurple;
        break;

      case InterventionTypeEnum.UnderRepair:
        iconData = FontAwesomeIcons.screwdriverWrench;
        color = Colors.amber;
        break;

      case InterventionTypeEnum.DoneRepairing:
        iconData = FontAwesomeIcons.circleCheck;
        color = Colors.green;
        break;

      case InterventionTypeEnum.RefusedRepair:
        iconData = FontAwesomeIcons.circleXmark;
        color = Colors.red;
        break;

      case InterventionTypeEnum.ApprovedRepair:
        iconData = FontAwesomeIcons.thumbsUp;
        color = Colors.lightGreen;
        break;

      default:
        iconData = Icons.help_outline;
        color = Colors.grey;
    }

    return FaIcon(
      iconData,
      color: color,
      size: size,
    );
  }
}