import 'dart:io';
import 'package:csv/csv.dart';
import 'package:covid_risk_app/table.dart';
import 'package:ml_linalg/vector.dart';
import 'package:path_provider/path_provider.dart';

class CovidAnalysis {
  Table _cases;
  Table _deaths;
  Table _population;

  CovidAnalysis(this._cases, this._deaths, this._population);

  Map<String, double> get cases {
    throw UnimplementedError();
  }

  /// Returns the increase in [table]'s measurement over the last 14 days.
  /// 
  /// Expects USA Facts format.
  static Vector _fortnightIncrease(Table table) {
    var latestColumnDate = table.headers.last;
    var fortnightAgoColumnDate = _dateTimeToColumnDate(_columnDateToDateTime(table.headers.last).subtract(Duration(days: 14)));
    return Vector.fromList(List<num>.from(table.column(latestColumnDate))) - Vector.fromList(List<num>.from(table.column(fortnightAgoColumnDate)));
  }

  /// Converts a USA Facts format vector into a map that maps county FIPS to a statistic
  static Map<String, double> _vectorToMap(Vector countyData) {
    
  }

  static DateTime _columnDateToDateTime(String columnDate) {
    var fields = columnDate.split('/').map((field) => int.parse(field)).toList();
    return DateTime(fields[2], fields[0], fields[1]);
  }

  static String _dateTimeToColumnDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}

/*
//TODO convert this into something usable
void main(List<String> arguments) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  var csvString = File('$appDocDir/cases.csv').readAsStringSync();
  var rows = CsvToListConverter().convert(csvString);
  var rowsCleaned = rows.map((row) => row..removeRange(3, row.length-15)).toList();
  var table = Table.fromRows(rowsCleaned);
  var latestColumnDate = table.headers.last;
  var fortnightAgoColumnDate = _dateTimeToColumnDate(_columnDateToDateTime(rowsCleaned[0].last).subtract(Duration(days: 14)));
  var confirmedIncrease = Vector.fromList(List<num>.from(table.column(latestColumnDate))) - Vector.fromList(List<num>.from(table.column(fortnightAgoColumnDate)));
  print(confirmedIncrease.take(10));
}
*/