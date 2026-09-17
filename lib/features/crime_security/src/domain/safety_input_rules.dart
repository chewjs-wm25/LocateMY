void validateSafetyInputs(Map<String, Object?> data, DateTime now) {
  if (data['version'] != 1 ||
      data['dataset_id'] != 'crime_district' ||
      data['source_url'] !=
          'https://storage.data.gov.my/publicsafety/crime_district.csv' ||
      data['source_sha256'] !=
          '800d488b426cd02f068179c626f7b4d2c5ba024f5b4b838fb0986fb7001c31be' ||
      data['verified'] != true ||
      data['latest_complete_year'] != 2023 ||
      (data['latest_complete_year'] as int) >= now.year) {
    throw const FormatException('Unverified safety inputs');
  }
  final Object? rawRows = data['rows'];
  bool valid = rawRows is List;
  final Set<String> keys = <String>{};
  if (rawRows is List) {
    for (final Object? row in rawRows) {
      if (row is! Map ||
          row['year'] is! int ||
          (row['year'] as int) < 1900 ||
          (row['year'] as int) > (data['latest_complete_year'] as int) ||
          row['state'] is! String ||
          !_reportingStates.contains(row['state']) ||
          (row['category'] != 'assault' && row['category'] != 'property') ||
          row['type'] is! String ||
          (row['type'] as String).isEmpty ||
          row['crimes'] is! int ||
          (row['crimes'] as int) < 0) {
        valid = false;
        break;
      }
      if (!keys.add(
        '${row['year']}|${row['state']}|${row['category']}|${row['type']}',
      )) {
        valid = false;
        break;
      }
    }
  }
  if (!valid) {
    throw const FormatException('Unverified safety inputs');
  }
}

const Set<String> _reportingStates = <String>{
  'Johor',
  'Kedah',
  'Kelantan',
  'Melaka',
  'Negeri Sembilan',
  'Pahang',
  'Perak',
  'Perlis',
  'Pulau Pinang',
  'Sabah',
  'Sarawak',
  'Selangor',
  'Terengganu',
  'W.P. Kuala Lumpur',
  'Malaysia',
};
