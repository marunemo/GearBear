import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'models/camp_site.dart';

Future<List<CampSite>> loadCampSites() async {
  final csvString = await rootBundle.loadString('assets/mapData/Camp_Map.csv');
  final List<List<dynamic>> rows = const CsvToListConverter(
    fieldDelimiter: ',',
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(csvString);

  return rows.skip(1).map((row) {
    final name = row[0] as String;
    final lat = double.tryParse(row[11].toString()) ?? 0.0;
    final lng = double.tryParse(row[12].toString()) ?? 0.0;
    final address = row[14] as String;
    return CampSite(name: name, latitude: lat, longitude: lng, address: address);
  }).toList();
}