import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import '../http/lib_http.dart';
import '../services/quartiersService.dart';

class FilterDialogs {
  FilterDialogs._();

  static Future<String?> pickQuartier(BuildContext context, S s) async {
    final names = await QuartiersService.polygons.keys.toList()..sort();

    return showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.quartier),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(s.all),
          ),
          for (final name in names)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, name),
              child: Text(name),
            ),
        ],
      ),
    );
  }

  static Future<String?> pickStatus(BuildContext context, S s) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.status),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(s.all),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '1'),
            child: Text(s.waitingAssignment),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '6'),
            child: Text(s.availableForCitizens),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '2'),
            child: Text(s.assignedToCitizen),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '5'),
            child: Text(s.assignedBlueCollar),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '3'),
            child: Text(s.underRepair),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '7'),
            child: Text(s.waitingForConfirmation),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '4'),
            child: Text(s.done),
          ),
        ],
      ),
    );
  }

  static Future<int?> pickCategory(BuildContext context, S s) {
    return showDialog<int?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.category),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(s.all),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 0),
            child: Text(getCategoryLabel(0, s)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 1),
            child: Text(getCategoryLabel(1, s)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 2),
            child: Text(getCategoryLabel(2, s)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 3),
            child: Text(getCategoryLabel(3, s)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 4),
            child: Text(getCategoryLabel(4, s)),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 5),
            child: Text(getCategoryLabel(5, s)),
          ),
        ],
      ),
    );
  }

  static Future<String?> pickDistance(BuildContext context, S s) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.distance),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'Closest'),
            child: Text(s.closest),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'Farthest'),
            child: Text(s.farthest),
          ),
        ],
      ),
    );
  }

  static String getCategoryLabel(int categoryId, S s) {
    switch (categoryId) {
      case 0:
        return s.cleanliness;
      case 1:
        return s.furniture;
      case 2:
        return s.roadSigns;
      case 3:
        return s.greenSpaces;
      case 4:
        return s.seasonal;
      case 5:
        return s.social;
      default:
        return 'Unknown';
    }
  }
}