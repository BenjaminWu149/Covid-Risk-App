import 'dart:async';
import 'dart:io';

import 'package:backdrop/app_bar.dart';
import 'package:backdrop/scaffold.dart';
import 'package:covid_risk_app/widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

  Future<File> _downloadFile(String fileName, dynamic url) async {
    // downloads data from a url and stores it in the
    // default permanent directory using the fileName
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadedFile = File('${appDocDir.path}/$fileName')..createSync();
    var response = await http.get(url);
    var data = response.body;
    return downloadedFile.writeAsString(data);
  }

  Future<Map<String, File>> _downloadData() async {    
    // downloads the data into files and returns a future containing a map with the data
    var downloadCompleter = Completer<Map<String, File>>();
    var confirmedCasesFile = await _downloadFile('cases.csv', 'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_confirmed_usafacts.csv');
    var deathsFile = await _downloadFile('deaths.csv', 'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_deaths_usafacts.csv');
    var populationFile = await _downloadFile('population.csv', 'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_county_population_usafacts.csv');
    downloadCompleter.complete(<String, File>{'countyConfirmedCases': confirmedCasesFile, 'countyDeaths': deathsFile, 'countyPopulations': populationFile});
    return downloadCompleter.future;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      appBar: BackdropAppBar(
        title: Text('COVID Risk Analysis'),
      ),
      backLayer: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Divider(thickness: 1.0,),
            ListTile(
              leading: Icon(
                Icons.place, 
                size: 50.0,
              ),
              title: Text('County Risk Indicator', style: Theme.of(context).textTheme.headline5),
              subtitle: Text('COVID risk scores by US county (updated daily)'),
              onTap: () {},
            ),
            Divider(thickness: 1.0,),
            ListTile(
              leading: Icon(
                Icons.security, 
                size: 50.0,
              ),
              title: Text('Mask Information', style: Theme.of(context).textTheme.headline5),
              subtitle: Text('Proper mask wearing, cleaning, and maintenance'),
              onTap: () {},
            ),
            Divider(thickness: 1.0,),
            ListTile(
              leading: Icon(
                Icons.library_books, 
                size: 50.0,
              ),
              title: Text('Further Reading', style: Theme.of(context).textTheme.headline5),
              subtitle: Text('Calculation methodology and data sources'),
              onTap: () {},
            ),
            Divider(thickness: 1.0,),
          ],
        ),
      ),
      frontLayer: FutureBuilder<Map<String, File>>(
        future: _downloadData(),  /* TODO make this a fetcher for something that points to saved data if possible */
        builder: (BuildContext context, AsyncSnapshot<Map<String, File>> snapshot) {
          //TODO swipe down functionality to reveal back layer
          List<Widget> children;
          if (snapshot.hasData) {
            // when the data is obtained
            children = <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
                child: Text(
                  'Montgomery County, MD',
                  style: Theme.of(context).textTheme.headline3,
                  textAlign: TextAlign.center,
                ),
              ),
              Divider(thickness: 1.0,),
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
                          'Low',
                          style: Theme.of(context).textTheme.headline5.copyWith(color: Colors.green),
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
                          '0.492',
                          style: Theme.of(context).textTheme.headline5.copyWith(color: Colors.green),
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
              Divider(thickness: 1.0,),
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
                      StatisticRow('Population', 2.31),
                      Spacer(),
                      StatisticRow('14 Day Case Increase per Capita', -0.24),
                      Spacer(),
                      StatisticRow('14 Day Death Increase per Capita', 0.23),
                      Spacer(),
                      StatisticRow('Fatality Rate', 1.23),
                      Spacer(),
                      StatisticRow('Current Hospitalizations per Capita', -2.01),
                      Spacer(),
                      StatisticRow('Total Test Results per Capita', 0.12),
                    ],
                  ),
                ),
                fit: FlexFit.tight,
                flex: 1,
              ),
            ];
          }
          else if (snapshot.hasError) {
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
          }
          else {
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
      ),
    );
  }
}
