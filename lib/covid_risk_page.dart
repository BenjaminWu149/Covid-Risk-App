import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:covid_risk_app/table.dart' as risk;
import 'package:csv/csv.dart';
import 'package:covid_risk_app/data_analysis.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CovidRiskPage extends StatelessWidget {
  final int _countyFipsId;

  CovidRiskPage(this._countyFipsId);

  /// Downloads a file from [url] and stores it in the
  /// default permanent directory using [fileName].
  Future<File> _downloadFile(String fileName, dynamic url) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadedFile = File('${appDocDir.path}/$fileName')..createSync();
    var response = await http.get(url);
    var data = response.body;
    return downloadedFile.writeAsString(data);
  }

  /// Downloads COVID data into files and returns a future which completes with a map containing the data.
  /// Also creates a lastUpdated file containing the DateTime of the last download.
  // TODO setup caching and put it in the FutureBuilder
  Future<Map<String, File>> _downloadData() async {
    var downloadCompleter = Completer<Map<String, File>>();
    var confirmedCasesFile = await _downloadFile('cases.csv',
        'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_confirmed_usafacts.csv');
    var deathsFile = await _downloadFile('deaths.csv',
        'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_deaths_usafacts.csv');
    var populationFile = await _downloadFile('population.csv',
        'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_county_population_usafacts.csv');
    var stateFile = await _downloadFile(
        'stateData.csv', 'https://covidtracking.com/api/v1/states/daily.csv');
    File('${(await getApplicationDocumentsDirectory()).path}/lastUpdated.txt')
      ..createSync()
      ..writeAsStringSync(DateTime.now().toIso8601String());

    downloadCompleter.complete(<String, File>{
      'cases': confirmedCasesFile,
      'deaths': deathsFile,
      'populations': populationFile,
      'states': stateFile
    });
    return downloadCompleter.future;
  }

  /// Uses state data specified by [covidTrackingHeader] to create a USA Facts county ordered table.
  /// The table will container a single header named [covidTrackingHeader].
  risk.Table _stateToCountyMap(risk.Table covidTrackingTable,
      String covidTrackingHeader, List stateFipsList) {
    // note: utilizing fips column would be somewhat easier
    const postalCodeToFips = {
      'AL': 1,
      'AK': 2,
      'AZ': 4,
      'AR': 5,
      'CA': 6,
      'CO': 8,
      'CT': 9,
      'DE': 10,
      'DC': 11,
      'FL': 12,
      'GA': 13,
      'HI': 15,
      'ID': 16,
      'IL': 17,
      'IN': 18,
      'IA': 19,
      'KS': 20,
      'KY': 21,
      'LA': 22,
      'ME': 23,
      'MD': 24,
      'MA': 25,
      'MI': 26,
      'MN': 27,
      'MS': 28,
      'MO': 29,
      'MT': 30,
      'NE': 31,
      'NV': 32,
      'NH': 33,
      'NJ': 34,
      'NM': 35,
      'NY': 36,
      'NC': 37,
      'ND': 38,
      'OH': 39,
      'OK': 40,
      'OR': 41,
      'PA': 42,
      'RI': 44,
      'SC': 45,
      'SD': 46,
      'TN': 47,
      'TX': 48,
      'UT': 49,
      'VT': 50,
      'VA': 51,
      'WA': 53,
      'WV': 54,
      'WI': 55,
      'WY': 56,
      'AS': 60,
      'GU': 66,
      'MP': 69,
      'PR': 72,
      'VI': 78,
    };

    // map postal codes (state abbrievations) to state FIPS ids
    var states = covidTrackingTable.column('state');
    var metric = covidTrackingTable.column(covidTrackingHeader);
    var fipsToMetric = <String, int>{};
    for (var i = 0; i < states.length; i++) {
      var key = postalCodeToFips[states[i]].toString().padLeft(2, '0');
      fipsToMetric[key] = int.tryParse(metric[i].toString());
    }

    // generate table
    var metricCountyList = stateFipsList
        .map((stateFips) => fipsToMetric[stateFips.toString().padLeft(2, '0')])
        .toList();
    return risk.Table.fromRows([
      ...<dynamic>[
        [covidTrackingHeader]
      ],
      ...metricCountyList.map((e) => [e]),
    ]);
  }

  /// Returns a map providing tables made from inputted data files.
  ///
  /// Expects cases, deaths, and population data from USA Facts.
  /// Expects state data from the Covid Tracking Project.
  Future<Map<String, risk.Table>> _organizeFiles(File confirmedCases,
      File deathsFile, File populationFile, File stateFile) async {
    var csvToListConverter = CsvToListConverter(eol: '\n');
    var fileToRows =
        (File file) => csvToListConverter.convert(file.readAsStringSync());
    var map = {
      'cases': risk.Table.fromRows(fileToRows(confirmedCases)
          .map((row) => row..removeRange(4, row.length - 16))
          .toList()),
      'deaths': risk.Table.fromRows(fileToRows(deathsFile)
          .map((row) => row..removeRange(4, row.length - 16))
          .toList()),
      'populations': risk.Table.fromRows(fileToRows(populationFile)),
    };

    // map state fips codes to hospitalized
    var rows = await stateFile
        .openRead()
        .transform(utf8.decoder)
        .transform(CsvToListConverter(eol: '\n'))
        .take(57)
        .toList();
    var covidTrackingTable = risk.Table.fromRows(rows);
    var stateFipsColumn = map['cases'].column('stateFIPS');
    map['hospitalized'] = _stateToCountyMap(
        covidTrackingTable, 'hospitalizedCurrently', stateFipsColumn);
    map['totalTests'] = _stateToCountyMap(
        covidTrackingTable, 'totalTestResults', stateFipsColumn);
    return map;
  }

  @override
  Widget build(BuildContext context) {
    //TODO futurebuilder the app as a loading screen and save analysis as a csv for the future
    return FutureBuilder<CovidData>(
      future: Future<CovidData>.sync(() async {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        var lastUpdatedFile = File('${appDocDir.path}/lastUpdated.txt');
        var fileMap = lastUpdatedFile.existsSync() &&
                DateTime.now().isBefore(
                    DateTime.parse(lastUpdatedFile.readAsStringSync())
                        .add(Duration(hours: 24)))
            ? <String, File>{
                'cases': File('${appDocDir.path}/cases.csv'),
                'deaths': File('${appDocDir.path}/deaths.csv'),
                'populations': File('${appDocDir.path}/population.csv'),
                'states': File('${appDocDir.path}/stateData.csv'),
              }
            : await _downloadData();
        var tableMap = await _organizeFiles(fileMap['cases'], fileMap['deaths'],
            fileMap['populations'], fileMap['states']);
        return CovidData(
            tableMap['cases'],
            tableMap['deaths'],
            tableMap['populations'],
            tableMap['hospitalized'],
            tableMap['totalTests']);
      }),
      builder: (BuildContext context, AsyncSnapshot<CovidData> snapshot) {
        List<Widget> children;
        if (snapshot.hasData) {
          var covidData = snapshot.data;
          var getStandardScore = (Map<int, num> map) {
            var scorer = StandardScoreCalculator(
                map.values.where((element) => element >= 0).toList());
            return scorer.score(map[_countyFipsId]);
          };

          // county scores
          //TODO low is good sometimes
          var standardScores = {
            'population': getStandardScore(covidData.population),
            'fortnightCases':
                getStandardScore(covidData.fortnightCaseIncreasePerTenThousand),
            'fortnightDeaths': getStandardScore(
                covidData.fortnightDeathIncreasePerTenThousand),
            'hospitalizations': getStandardScore(covidData.hospitalizations),
            'fatalityRate':
                getStandardScore(covidData.fatalityRatePerTenThousand),
          };
          var summaryScore =
              standardScores.values.reduce((value, element) => value + element);

          // when the data is obtained
          children = <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
              child: Text(
                covidData.countyFipsToName[_countyFipsId],
                style: Theme.of(context).textTheme.headline3,
                textAlign: TextAlign.center,
              ),
            ),
            Divider(
              thickness: 1.0,
            ),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Risk is\t',
                        style: Theme.of(context).textTheme.headline5,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Variable',
                        style: Theme.of(context)
                            .textTheme
                            .headline5
                            .copyWith(color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                  ),
                  Row(
                    children: [
                      Text(
                        'Summary Score\t',
                        style: Theme.of(context).textTheme.headline5,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        summaryScore.toStringAsPrecision(4),
                        style: Theme.of(context).textTheme.headline5.copyWith(
                            color:
                                summaryScore >= 0 ? Colors.green : Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                  ),
                ],
              ),
              fit: FlexFit.loose,
              flex: 0,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Placeholder(), //TODO graph or flag
              ),
              fit: FlexFit.tight,
            ),
            Divider(
              thickness: 1.0,
            ),
            Flexible(
              //TODO make this swipable, revealing correspending averages, stdevs, and values from data?
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Standard Score Values',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 4.0)),
                    StatisticRow('Population', standardScores['population']),
                    Spacer(),
                    StatisticRow('14 Day Case Increase per 10,000 people',
                        standardScores['fortnightCases']),
                    Spacer(),
                    StatisticRow('14 Day Death Increase per 10,000 people',
                        standardScores['fortnightDeaths']),
                    Spacer(),
                    StatisticRow('State Hospitalizations',
                        standardScores['hospitalizations']),
                    Spacer(),
                    StatisticRow('Fatality Rate Per 10,000 People',
                        standardScores['fatalityRate']),
                  ],
                ),
              ),
              fit: FlexFit.tight,
              flex: 1,
            ),
          ];
        } else if (snapshot.hasError) {
          // if we can't get the data
          children = <Widget>[
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Error: ${snapshot.error}'),
            )
          ];
        } else {
          // when we don't have data, show a loading circle
          children = <Widget>[
            SizedBox(
              child: CircularProgressIndicator(),
              width: 60,
              height: 60,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Loading Data...'),
            )
          ];
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}

/// A widget that displays a named statistic and a value.
class StatisticRow extends StatelessWidget {
  final String _statisticName;
  final double _statisticValue;

  /// Creates a StatisticRow widget.
  StatisticRow(this._statisticName, this._statisticValue);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            _statisticName,
            style: Theme.of(context).textTheme.subtitle1,
            textAlign: TextAlign.left,
          ),
          fit: FlexFit.tight,
          flex: 2,
        ),
        Flexible(
          //TODO take in average and stdev and apply color
          child: Text(
            _statisticValue.toStringAsPrecision(4),
            style: Theme.of(context).textTheme.subtitle1.copyWith(color: _statisticValue < 0 ? Colors.red : Colors.green),
            textAlign: TextAlign.right,
          ),
          fit: FlexFit.tight,
        ),
      ],
    );
  } 
}