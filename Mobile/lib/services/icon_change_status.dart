import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StatusIcon extends StatelessWidget {
  final int status;

  const StatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    const double iconSize = 24;

    switch (status) {
      case 0:
        return const FaIcon(
          FontAwesomeIcons.hourglassHalf,
          color: Colors.red,
          size: iconSize,
        );

      case 7:
        return const FaIcon(
          FontAwesomeIcons.hourglassHalf,
          color: Colors.orange,
          size: iconSize,
        );

      case 5:
        return Transform.translate(
          offset: const Offset(-4, 0),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcIn),
            child: Image.asset(
              'assets/icons/worker.png',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        );

      case 2:
        return const FaIcon(
          FontAwesomeIcons.user,
          color: Colors.black,
          size: iconSize,
        );

      case 1:
      case 6:
        return const FaIcon(
          FontAwesomeIcons.clock,
          color: Colors.orange,
          size: iconSize,
        );

      case 3:
        return const FaIcon(
          FontAwesomeIcons.wrench,
          color: Colors.blueGrey,
          size: iconSize,
        );

      case 4:
        return const FaIcon(
          FontAwesomeIcons.circleCheck,
          color: Colors.green,
          size: iconSize,
        );

       case 7:
        return const FaIcon(
          FontAwesomeIcons.hourglassHalf,
          color: Colors.purple,
          size: iconSize,
        );
        break;

      default:
        return const Icon(
          Icons.help_outline,
          color: Colors.grey,
          size: iconSize,
        );
    }
  }
}
