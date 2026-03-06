import 'package:flutter/material.dart';
import 'package:municipalgo/generated/l10n.dart';

class TimeAgo {
  const TimeAgo._();

  static String format(BuildContext context, DateTime date) {
    final s = S.of(context);
    final diff = DateTime.now().difference(date);

    if (diff.isNegative || diff.inSeconds < 5) {
      return s.timeNow;
    }

    if (diff.inSeconds < 60) {
      return s.timeSecond(diff.inSeconds);
    }

    if (diff.inMinutes < 60) {
      return s.timeMinute(diff.inMinutes);
    }

    if (diff.inHours < 24) {
      return s.timeHour(diff.inHours);
    }

    if (diff.inDays < 30) {
      return s.timeDay(diff.inDays);
    }

    if (diff.inDays < 365) {
      return s.timeMonth((diff.inDays / 30).floor());
    }

    return s.timeYear((diff.inDays / 365).floor());
  }
}