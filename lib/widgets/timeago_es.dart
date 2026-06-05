import 'package:flutter/widgets.dart';

String timeAgoEs(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) return 'hace ${diff.inSeconds} s';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 30) return 'hace ${diff.inDays} d';

  final months = (diff.inDays / 30).floor();
  if (months < 12) return 'hace $months mes${months == 1 ? '' : 'es'}';

  final years = (diff.inDays / 365).floor();
  return 'hace $years año${years == 1 ? '' : 's'}';
}

