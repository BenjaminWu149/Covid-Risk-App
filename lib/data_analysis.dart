import 'dart:math';

import 'package:covid_risk_app/table.dart';
import 'package:ml_linalg/vector.dart';

/// Contains COVID data from USA Facts and the Covid Tracking Project
class CovidData {
  final Table _casesTable;
  final Table _deathsTable;
  final Table _populationTable;
  final Table _hospitalizedTable;
  final Table _totalTestResultsTable;

  /// Creates a CovidAnalysis instance.
  /// 
  /// Assumes tables come follow USA Facts row order.
  CovidData(this._casesTable, this._deathsTable, this._populationTable, this._hospitalizedTable, this._totalTestResultsTable);

  /// A map of county FIPS ids to the most recent cumulative confirmed case count per 10,000 in that county.
  Map<int, num> get casesPerTenThousand => _vectorToMap(_casesVector/_populationVector*10000);

  /// A map of county FIPS ids to the most recent cumulative death count per 10,000 in that county.
  Map<int, num> get deathsPerTenThousand => _vectorToMap(_deathsVector/_populationVector*10000);

  /// A map of county FIPS ids to the most recent death count per 10,000 in that county.
  Map<int, num> get fatalityRatePerTenThousand => _vectorToMap(_deathsVector/Vector.fromList(List<num>.from(_casesVector.map((e) => e == 0 ? -1 : e)))*10000);

  /// A map of county FIPS ids to the most current hospitalization count in that state. The value will be -1 if it remains unreported.
  // TODO account for state populations
  Map<int, num> get hospitalizations => _vectorToMap(_hospitalizedVector/_populationVector);

  /// A map of county FIPS ids to the population of that state.
  Map<int, num> get population => _vectorToMap(_populationVector);

  /// A map of county FIPS ids to the total test result count per capita in that state. The value will be -1 if it remains unreported.
  // TODO account for state populations
  Map<int, num> get totalTestResults => _vectorToMap(_totalTestResultsVector);

  /// A map of county FIPS ids to the most recent 14 day case increase count per 10,000 in that county.
  Map<int, num> get fortnightCaseIncreasePerTenThousand => _vectorToMap(_fortnightIncrease(_casesTable)/_populationVector*10000);

  /// A map of county FIPS ids to the most recent 14 day death increase count per 10,000 in that county.
  Map<int, num> get fortnightDeathIncreasePerTenThousand => _vectorToMap(_fortnightIncrease(_deathsTable)/_populationVector*10000);

  /// Returns a map that outputs a county's name given its FIPS id.
  Map<int, String> get countyFipsToName {
    var casesTable = _casesTable;
    var countyFips = casesTable.column('countyFIPS');
    var names = casesTable.column('County Name');
    var states = casesTable.column('State');
    var entries = List.generate(countyFips.length, (index) => index).map((i) => MapEntry<int, String>(countyFips[i], '${names[i]}, ${states[i]}'));
    return Map.fromEntries(entries)..remove(0);
  }

  /// Returns the raw population vector with 0s replaced by -1s.
  Vector get _populationVector => Vector.fromList(List<num>.from(_populationTable.column(_populationTable.headers.last).map((e) => e == 0 ? -1 : e)));

  /// Returns the raw cases vector
  Vector get _casesVector => Vector.fromList(List<num>.from(_casesTable.column(_casesTable.headers.last)));

  /// Returns the raw deaths vector
  Vector get _deathsVector => Vector.fromList(List<num>.from(_deathsTable.column(_deathsTable.headers.last)));

  /// Returns the raw hospitalized in state vector
  Vector get _hospitalizedVector => Vector.fromList(List<num>.from(_hospitalizedTable.column(_hospitalizedTable.headers.last).map((e) => e ?? -1)));

  /// Returns the raw total test results in state vector
  Vector get _totalTestResultsVector => Vector.fromList(List<num>.from(_totalTestResultsTable.column(_totalTestResultsTable.headers.last).map((e) => e ?? -1)));

  /// Returns the increase in [table]'s measurement over the last 14 days.
  /// 
  /// Expects USA Facts format.
  static Vector _fortnightIncrease(Table table) {
    var latestColumnDate = table.headers.last;
    var fortnightAgoColumnDate = _dateTimeToColumnDate(_columnDateToDateTime(table.headers.last).subtract(Duration(days: 13)));
    return Vector.fromList(List<num>.from(table.column(latestColumnDate)))-Vector.fromList(List<num>.from(table.column(fortnightAgoColumnDate)));
  }

  /// Converts a USA Facts format vector into a map that maps county FIPS to a statistic
  /// 
  /// Ignores statewide unallocated data (counties with a FIPS id of 0).
  Map<int, num> _vectorToMap(Vector countyData) {
    var map = <int, int>{};
    var counties = List<int>.from(_casesTable.column('countyFIPS'));
    for (var i = 0; i < counties.length; i++) {
      map[counties[i]] = countyData[i].toInt();
    }
    return map..remove(0);
  }

  /// Returns a DateTime instance containing the date of [columnDate].
  /// 
  /// Expects month/day/year format.
  static DateTime _columnDateToDateTime(String columnDate) {
    var fields = columnDate.split('/').map((field) => int.parse(field)).toList();
    return DateTime(fields[2], fields[0], fields[1]);
  }

  /// Returns a month/day/year string containing the same date as [dateTime].
  static String _dateTimeToColumnDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}

/// A calculator for Daniel Kahneman's standard score metric.
class StandardScoreCalculator {

  /// Average of the supplied metric across the whole data set.
  final double average;

  /// Standard deviation of the supplied metric across the whole data set.
  final double stdev;

  /// Creates a standard score calculator. 
  StandardScoreCalculator(List<num> list)
    : average = Vector.fromList(list).mean(),
      stdev = sqrt((Vector.fromList(list)-Vector.filled(list.length, Vector.fromList(list).mean())).pow(2).sum()/list.length);

  /// Calculates the standard score of the supplied metric by comparing [singleCase] to the average.
  double score(num singleCase) => (singleCase-average)/stdev;
}