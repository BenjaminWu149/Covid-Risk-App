import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:covid_risk_app/data_analysis.dart';
import 'package:covid_risk_app/table.dart';

/// Downloads a file from [url] and stores it in the
/// default permanent directory using [fileName].
Future<File> _downloadFile(
    String fileName, Directory parentFolder, dynamic url) async {
  File downloadedFile = File('${parentFolder.path}/$fileName')..createSync();
  var response = await http.get(url);
  var data = response.body;
  return downloadedFile.writeAsString(data);
}

/// Downloads COVID data into files and returns a future which completes with a map containing the data.
/// Also creates a lastUpdated file containing the DateTime of the last download.
Future<Map<String, File>> downloadData(Directory parentFolder) async {
  var downloadCompleter = Completer<Map<String, File>>();
  var confirmedCasesFile = await _downloadFile('cases.csv', parentFolder,
      'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_confirmed_usafacts.csv');
  var deathsFile = await _downloadFile('deaths.csv', parentFolder,
      'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_deaths_usafacts.csv');
  var populationFile = await _downloadFile('population.csv', parentFolder,
      'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_county_population_usafacts.csv');
  var stateFile = await _downloadFile('stateData.csv', parentFolder,
      'https://covidtracking.com/api/v1/states/daily.csv');
  File('${parentFolder.path}/lastUpdated.txt')
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
Table stateToCountyMap(
    Table covidTrackingTable, String covidTrackingHeader, List stateFipsList) {
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
  return Table.fromRows([
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
Future<Map<String, Table>> organizeFiles(File confirmedCases, File deathsFile,
    File populationFile, File stateFile) async {
  var csvToListConverter = CsvToListConverter(eol: '\n');
  var fileToRows =
      (File file) => csvToListConverter.convert(file.readAsStringSync());
  var map = {
    'cases': Table.fromRows(fileToRows(confirmedCases)
        .map((row) => row..removeRange(4, row.length - 16))
        .toList()),
    'deaths': Table.fromRows(fileToRows(deathsFile)
        .map((row) => row..removeRange(4, row.length - 16))
        .toList()),
    'populations': Table.fromRows(fileToRows(populationFile)),
  };

  // map state fips codes to hospitalized
  var rows = await stateFile
      .openRead()
      .transform(utf8.decoder)
      .transform(CsvToListConverter(eol: '\n'))
      .take(57)
      .toList();
  var covidTrackingTable = Table.fromRows(rows);
  var stateFipsColumn = map['cases'].column('stateFIPS');
  map['hospitalized'] = stateToCountyMap(
      covidTrackingTable, 'hospitalizedCurrently', stateFipsColumn);
  map['totalTests'] =
      stateToCountyMap(covidTrackingTable, 'totalTestResults', stateFipsColumn);
  return map;
}

Future<Table> analyzeCovidData(Directory parentDir, [bool forceRefresh = false]) async {
  // get files
  //TODO record version number in lastUpdated because if changes are made, we can't use the old file
  var appDocDir = parentDir;
  var lastUpdatedFile = File('${appDocDir.path}/lastUpdated.txt');
  var dataAnalysisFile = File('${appDocDir.path}/data_analysis.csv');

  // Don't reanalyze if we have the analysis already
  var analysisExists = !forceRefresh && lastUpdatedFile.existsSync() &&
      dataAnalysisFile.existsSync() &&
      DateTime.now().isBefore(DateTime.parse(lastUpdatedFile.readAsStringSync())
          .add(Duration(hours: 24)));
  Table table;
  if (analysisExists) {
    var dataRows =
        CsvToListConverter().convert(dataAnalysisFile.readAsStringSync());
    table = Table.fromRows(dataRows);
  } else {
    var fileMap = await downloadData(appDocDir);

    // organize data
    var tableMap = await organizeFiles(fileMap['cases'], fileMap['deaths'],
        fileMap['populations'], fileMap['states']);
    var covidData = CovidData(
        tableMap['cases'],
        tableMap['deaths'],
        tableMap['populations'],
        tableMap['hospitalized'],
        tableMap['totalTests']);

    // set up standard score calculation
    var getStandardScorer = (
      Map<int, num> countyValues,
    ) {
      return StandardScoreCalculator(
          countyValues.values.where((element) => element >= 0).toList());
    };
    var metricToDataset = {
      'fortnightCases': covidData.fortnightCaseIncreasePerTenThousand,
      'fortnightDeaths': covidData.fortnightDeathIncreasePerTenThousand,
      'hospitalizations': covidData.hospitalizations,
      'fatalityRate': covidData.fatalityRatePerTenThousand,
    };
    var metricToStandardScorer = metricToDataset
        .map((key, value) => MapEntry(key, getStandardScorer(value)));
    var multipliers = [-1, -1, -1, -1];
    assert(multipliers.length == metricToDataset.length);
    var metricToMultiplier = metricToDataset.keys
        .toList()
        .asMap()
        .map((index, metric) => MapEntry(metric, multipliers[index]));

    // gather standard scores
    var rows = <dynamic>[
      ...['countyFips', 'countyName'],
      ...metricToDataset.keys,
      ...['summaryScore', 'standardSummaryScore'],
    ].map((e) => [e]).toList();
    var summaryScores = <num>[];

    for (int countyFipsId in covidData.counties) {
      //add scores to rows
      var standardScoreMap = metricToStandardScorer.map((key, value) =>
          MapEntry(
              key,
              metricToMultiplier[key] *
                  value.score(metricToDataset[key][countyFipsId])));
      var summaryScore =
          standardScoreMap.values.reduce((value, element) => value + element);
      [
        ...[countyFipsId, covidData.countyFipsToName[countyFipsId]],
        ...standardScoreMap.values,
        ...[summaryScore],
      ].asMap().forEach((index, value) => rows[index].add(value));
      summaryScores.add(summaryScore);
    }

    // calculate summary standard scores
    var summaryStandardScorer = StandardScoreCalculator(summaryScores);
    for (var i = 1; i < rows[0].length; i++) {
      var summaryScoreRowNum = rows.map((row) => row[0]).toList().indexOf('summaryScore');
      var summaryScore = rows[summaryScoreRowNum][i];
      rows.last.add(summaryStandardScorer.score(summaryScore));
    }
    table = Table.fromRows(rows);

    // output file
    File('${appDocDir.path}/data_analysis.csv')
      ..createSync()
      ..writeAsStringSync(ListToCsvConverter().convert(rows));

    // this is a debug function for examining the data in a format
    // that is choropleth-construction-friendly
    // ignore: unused_local_variable
    var outputChloroplethData = () {
      // calculate standard scores
      var rows = <List<dynamic>>[];
      var summaryScores = <num>[];
      for (int countyFipsId in covidData.counties) {
        var standardScoreMap = metricToStandardScorer.map((key, value) =>
            MapEntry(
                key,
                metricToMultiplier[key] *
                    value.score(metricToDataset[key][countyFipsId])));
        var summaryScore =
            standardScoreMap.values.reduce((value, element) => value + element);
        var row = [
          ...[countyFipsId, covidData.countyFipsToName[countyFipsId]],
          ...standardScoreMap.values,
          ...[summaryScore],
        ];
        rows.add(row);
        summaryScores.add(summaryScore);
      }

      // calculate summary standard scores
      var summaryStandardScorer = StandardScoreCalculator(summaryScores);
      rows.forEach((row) {
        row.add(summaryStandardScorer.score(row.last));
      });

      var rowsWithHeaders = [
        <dynamic>[
          ...['countyFips', 'countyName'],
          ...metricToDataset.keys,
          ...['summaryScore', 'standardSummaryScore'],
        ]
      ]..addAll(rows);

      // output csv for choropleth analysis
      var csvString = ListToCsvConverter().convert(rowsWithHeaders);
      File('${appDocDir.path}/data_analysis_choropleth.csv')
        ..createSync()
        ..writeAsStringSync(csvString);
    };
    outputChloroplethData();
  }

  return table;
}
