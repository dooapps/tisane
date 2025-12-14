String buildQueryParams(Map<String, dynamic> params) {
  if (params.isEmpty) return "";

  final queryString = params.entries
      .where(
        (entry) => entry.value != null && entry.value.toString().isNotEmpty,
      )
      .map(
        (entry) =>
            "${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}",
      )
      .join("&");

  return "?$queryString";
}

double? toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String && isNumeric(value)) return double.parse(value);
  return null;
}

bool isNumeric(String str) {
  return double.tryParse(str) != null;
}
