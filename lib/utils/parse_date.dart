import 'package:intl/intl.dart';

DateTime? parseDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  return DateFormat('dd.MM.yyyy').parse(dateString);
}
