import 'package:backdrop/app_bar.dart';
import 'package:backdrop/backdrop.dart';
import 'package:backdrop/scaffold.dart';
import 'package:covid_risk_app/covid_risk_page.dart';
import 'package:covid_risk_app/custom_scaffold.dart';
import 'package:covid_risk_app/icons/covid_material_icons.dart';
import 'package:covid_risk_app/information_widgets.dart';
import 'package:flutter/material.dart';

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
  var _countyIndex = 0;
  final _countyFips = [34003, 24031, 36001, 39035, 9007];

  Widget _frontLayer = InitialPage();
  final _covidInfo = CovidInfo();
  final _maskHandlingInfo = MaskHandlingInfo();
  final _maskMaintenaceInfo = MaskMaintenanceInfo();
  final _methodInfo = MethodInfo();

  @override
  Widget build(BuildContext context) {
    var backdropScaffold = CustomBackdropScaffold(
      appBar: BackdropAppBar(
        title: Text('COVID Hub'),
      ),
      backLayer: BackdropNavigationBackLayer(
        //TODO make this not seem like a scrollable list (swiping up and down reveals ends)
        items: [
          //TODO make this a dropdown with a list of counties (one of them will be an add county dialog trigger)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Icon(
                Icons.person_pin_circle,
                size: 50.0,
              ),
              title: Text('County Risk Indicator',
                  style: Theme.of(context).textTheme.headline5),
              subtitle: Text('COVID risk scores by US county (updated daily)'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Icon(CovidIcons.coronavirus, size: 50.0),
              title: Text('COVID Information',
                  style: Theme.of(context).textTheme.headline5),
              subtitle: Text('Safety precuations and how the virus spreads'),
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
        onTap: (int tapIndex) {
          var riskPage = () {
            _countyIndex = (_countyIndex + 1) % _countyFips.length;
            _frontLayer = CovidRiskPage(_countyFips[_countyIndex]);
          };
          var setPage = (Widget page) => () => _frontLayer = page;

          var changes = [
            riskPage,
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
      frontLayer: _frontLayer,
    );
    return backdropScaffold;
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
