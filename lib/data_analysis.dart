import 'dart:math';

import 'package:covid_risk_app/table.dart';
import 'package:ml_linalg/vector.dart';

/// Contains COVID data from USA Facts and the Covid Tracking Project
class CovidData {
  final Table _cases;
  final Table _deaths;
  final Table _population;

  /// Creates a CovidAnalysis instance.
  /// 
  /// Assumes tables come from USA Facts.
  CovidData(this._cases, this._deaths, this._population);

  /// A map of county FIPS ids to the most recent confirmed case count in that county.
  Map<int, num> get cases => _vectorToMap(Vector.fromList(List<num>.from(_cases.column(_cases.headers.last))));

  /// A map of county FIPS ids to the most recent death count in that county.
  Map<int, num> get deaths => _vectorToMap(Vector.fromList(List<num>.from(_deaths.column(_deaths.headers.last))));

  /// A map of county FIPS ids to the most recent population count in that county.
  Map<int, num> get population => _vectorToMap(Vector.fromList(List<num>.from(_population.column(_population.headers.last))));

  /// A map of county FIPS ids to the most recent 14 day case increase count in that county.
  Map<int, num> get fortnightCaseIncrease => _vectorToMap(_fortnightIncrease(_cases));

  /// A map of county FIPS ids to the most recent 14 day death increase count in that county.
  Map<int, num> get fortnightDeathIncrease => _vectorToMap(_fortnightIncrease(_deaths));

  /// Returns the increase in [table]'s measurement over the last 14 days.
  /// 
  /// Expects USA Facts format.
  static Vector _fortnightIncrease(Table table) {
    var latestColumnDate = table.headers.last;
    var fortnightAgoColumnDate = _dateTimeToColumnDate(_columnDateToDateTime(table.headers.last).subtract(Duration(days: 13)));
    return Vector.fromList(List<num>.from(table.column(latestColumnDate)))-Vector.fromList(List<num>.from(table.column(fortnightAgoColumnDate)));
  }

  /// Converts a USA Facts format vector into a map that maps county FIPS to a statistic.
  /// 
  /// Ignores statewide unallocated data (counties with a FIPS id of 0).
  Map<int, num> _vectorToMap(Vector countyData) {
    var map = <int, int>{};
    var counties = List<int>.from(_cases.column('countyFIPS'));
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
  final Map<int, num> _countyData;
  final double _average;
  final double _stdev;

  /// Creates a standard score calculator.
  /// 
  /// [_countyData] should map county FIPS ids to a given metric.
  StandardScoreCalculator(this._countyData)
    : _average = Vector.fromList(_countyData.values.toList()).mean(),
      _stdev = sqrt((Vector.fromList(_countyData.values.toList())-Vector.filled(_countyData.values.length, Vector.fromList(_countyData.values.toList()).mean())).pow(2).sum()/_countyData.values.length);

  /// Calculates the standard score of the supplied metric for a single county identified by its [countyFips].
  double county(int countyFips) => (_countyData[countyFips]-_average)/_stdev;
}