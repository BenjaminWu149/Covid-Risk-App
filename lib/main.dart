import 'dart:io';

import 'package:backdrop/app_bar.dart';
import 'package:backdrop/backdrop.dart';
import 'package:covid_risk_app/covid_risk_page.dart';
import 'package:covid_risk_app/custom_scaffold.dart';
import 'package:covid_risk_app/data_analysis.dart';
import 'package:covid_risk_app/icons/covid_material_icons.dart';
import 'package:covid_risk_app/information_widgets.dart';
import 'package:covid_risk_app/risk_calculation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:covid_risk_app/table.dart' as risk;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        accentColor: Colors.lightBlueAccent,
      ),
      home: MyHomePage(title: 'County Risk'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _countyFips = 34003;

  Widget _frontLayer = InitialPage();
  final _covidInfo = CovidInfo();
  final _maskHandlingInfo = MaskHandlingInfo();
  final _maskMaintenaceInfo = MaskMaintenanceInfo();
  final _methodInfo = MethodInfo();

  @override
  Widget build(BuildContext context) {
    var createBackdropScaffold = (risk.Table analysisTable,
            num standardSummaryAvg, num standardSummaryStdev) =>
        CustomBackdropScaffold(
          appBar: BackdropAppBar(
            title: Text('COVID Hub'),
          ),
          backLayer: Builder(
            builder: (BuildContext context) => BackdropNavigationBackLayer(
              //TODO make this not seem like a scrollable list (swiping up and down reveals ends)
              items: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Icon(
                      Icons.person_pin_circle,
                      size: 50.0,
                    ),
                    title: Text('County Risk Indicator',
                        style: Theme.of(context).textTheme.headline5),
                    subtitle:
                        Text('COVID risk scores by US county (updated daily)'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Icon(CovidIcons.coronavirus, size: 50.0),
                    title: Text('COVID Information',
                        style: Theme.of(context).textTheme.headline5),
                    subtitle:
                        Text('Safety precuations and how the virus spreads'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                      leading: Icon(CovidIcons.masks, size: 50.0),
                      title: Text('Mask Handling',
                          style: Theme.of(context).textTheme.headline5),
                      subtitle: Text('Wearing and removing masks safely')),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Icon(Icons.loop, size: 50.0),
                    title: Text('Mask Maintenance',
                        style: Theme.of(context).textTheme.headline5),
                    subtitle: Text('Cleaning and storage of masks'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Icon(Icons.poll, size: 50.0),
                    title: Text('Methodology and Sources',
                        style: Theme.of(context).textTheme.headline5),
                    subtitle: Text('Standard score calculation and sources'),
                  ),
                ),
              ],
              onTap: (int tapIndex) async {
                var appDocDir = await getApplicationDocumentsDirectory();
                var riskPage = (fipsCode) => () {
                      _frontLayer = CovidRiskPage(
                          analysisTable,
                          fipsCode,
                          standardSummaryAvg,
                          standardSummaryStdev, (int newFipsCode) {
                        setState(() {
                          _countyFips = newFipsCode;
                          Backdrop.of(context).revealBackLayer();
                          Scaffold.of(context).showSnackBar(SnackBar(content: Text('Reloaded County Data')));
                          File('${appDocDir.path}/fips.txt')..createSync()..writeAsStringSync(newFipsCode.toString());
                        });
                      });
                    };
                var setPage = (Widget page) => () => _frontLayer = page;

                var changes = [
                  riskPage(_countyFips),
                  setPage(_covidInfo),
                  setPage(_maskHandlingInfo),
                  setPage(_maskMaintenaceInfo),
                  setPage(_methodInfo)
                ];
                if (tapIndex < changes.length) {
                  setState(changes[tapIndex]);
                } else {
                  print('tapIndex $tapIndex is out of bounds.');
                }
              },
            ),
          ),
          frontLayer: _frontLayer,
          resizeToAvoidBottomInset: false,
        );
    return FutureBuilder<Map<String, dynamic>>(future:
        Future<Map<String, dynamic>>.sync(() async {
      var appDocDir = await getApplicationDocumentsDirectory();
      
      File fipsFile = File('${appDocDir.path}/fips.txt');
      if (fipsFile.existsSync()) {
        _countyFips = int.parse(fipsFile.readAsStringSync());
      }

      var analysisTable = await analyzeCovidData(appDocDir);
      var summaryScoreRowNum = analysisTable
          .column(analysisTable.headers.first)
          .indexOf('standardSummaryScore');
      var summaryScores =
          analysisTable.row(summaryScoreRowNum).skip(1).toList();
      return {
        'table': analysisTable,
        'standardSummaryScorer':
            StandardScoreCalculator(List<num>.from(summaryScores))
      };
    }), builder:
        (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.hasData) {
        var standardSummaryScorer =
            snapshot.data['standardSummaryScorer'] as StandardScoreCalculator;
        return createBackdropScaffold(snapshot.data['table'],
            standardSummaryScorer.average, standardSummaryScorer.stdev);
      } else if (snapshot.hasError) {
        // if we can't get the data
        var children = <Widget>[
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Error: ${snapshot.error}',
              style: Theme.of(context).textTheme.headline4,
            ),
          )
        ];
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        );
      } else {
        // when we don't have data, show a loading circle
        var children = <Widget>[
          SizedBox(
            child: CircularProgressIndicator(),
            width: 60,
            height: 60,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Loading Data...',
            ),
          )
        ];
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        );
      }
    });
  }
}

class InitialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Choose a topic to get started',
        style: Theme.of(context).textTheme.headline4,
        textAlign: TextAlign.center,
      ),
    );
  }
}
