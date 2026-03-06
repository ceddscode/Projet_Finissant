import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static String formatDateTime(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'fr') {
      // Format français: 26 janvier 2026, 14:03
      final day = date.day;
      final month = _getFrenchMonth(date.month);
      final year = date.year;
      final time = DateFormat('HH:mm').format(date);

      return '$day $month $year, $time';
    } else {
      // Format anglais: January 26th 2026, 14:03
      final day = date.day;
      final dayWithSuffix = _getDayWithSuffix(day);
      final month = DateFormat('MMMM', 'en').format(date);
      final year = date.year;
      final time = DateFormat('HH:mm').format(date);

      return '$month $dayWithSuffix $year, $time';
    }
  }

  static String _getFrenchMonth(int month) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return months[month - 1];
  }

  static String _getDayWithSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }

    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}

