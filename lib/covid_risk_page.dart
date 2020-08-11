import 'package:flutter/material.dart';
import 'package:covid_risk_app/table.dart' as risk;
import 'package:url_launcher/url_launcher.dart';

class CovidRiskPage extends StatelessWidget {
  final GlobalKey<FormState> _countySelectionFormKey = GlobalKey<FormState>();
  final TextEditingController _countySelectionController = TextEditingController();

  final Function onSetNewCounty;
  final int _countyFipsId;
  final risk.Table _riskTable;
  final num _summaryStandardAvg;
  final num _summaryStandardStdev;

  CovidRiskPage(this._riskTable, this._countyFipsId, this._summaryStandardAvg,
      this._summaryStandardStdev, [this.onSetNewCounty]);

  @override
  Widget build(BuildContext context) {
    var headers = _riskTable.column(_riskTable.headers
        .first); //the actual headers are FIPS codes, so this is atypical
    var countyData = _riskTable.column(_countyFipsId.toString());
    var data = headers
        .asMap()
        .map((index, header) => MapEntry(header, countyData[index]));
    var standardSummaryScore = data['standardSummaryScore'];
    var riskString;
    var riskColor;
    if (standardSummaryScore >
        _summaryStandardAvg + 0.5 * _summaryStandardStdev) {
      riskString = 'low';
      riskColor = Colors.green;
    } else if (standardSummaryScore <
        _summaryStandardAvg - 1 * _summaryStandardStdev) {
      riskString = 'high';
      riskColor = Colors.red;
    } else {
      riskString = 'moderate';
      riskColor = Colors.amber;
    }

    var children = <Widget>[
      Padding(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
        child: Text(
          data['countyName'],
          style: Theme.of(context).textTheme.headline3,
          textAlign: TextAlign.center,
        ),
      ),
      Divider(
        thickness: 1.0,
      ),
      Flexible(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                    riskString,
                    style: Theme.of(context)
                        .textTheme
                        .headline5
                        .copyWith(color: riskColor),
                    textAlign: TextAlign.center,
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              Row(
                children: [
                  Text(
                    'Standard Summary Score\t',
                    style: Theme.of(context).textTheme.headline5,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    standardSummaryScore.toStringAsPrecision(4),
                    style: Theme.of(context)
                        .textTheme
                        .headline5
                        .copyWith(color: riskColor),
                    textAlign: TextAlign.center,
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ],
          ),
        ),
        fit: FlexFit.loose,
        flex: 0,
      ),
      Flexible(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            child: OutlineButton(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit),
                    Text(
                      'Choose a new US County',
                      style: Theme.of(context).textTheme.headline5,
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: Text('Choose a new US County to Analyze'),
                            content: Form(
                                key: _countySelectionFormKey,
                                child: TextFormField(
                                  controller: _countySelectionController,
                                  decoration: const InputDecoration(
                                    hintText: 'FIPS Code (e.g. 24031)',
                                    labelText: 'County FIPS Code',
                                  ),
                                  onSaved: (String value) {
                                    // This optional block of code can be used to run
                                    // code when the user saves the form.
                                  },
                                  validator: (String value) {
                                    var fipsCodes =
                                        List<String>.from(_riskTable.headers)
                                          ..removeAt(0);
                                    return !fipsCodes.contains(
                                            int.tryParse(value).toString())
                                        ? 'Please enter a valid FIPS code'
                                        : null;
                                  },
                                )),
                            actions: [
                              FlatButton(
                                child: Text('Check FIPS Codes'),
                                onPressed: () async {
                                  var urlString =
                                      'https://en.wikipedia.org/wiki/List_of_United_States_FIPS_codes_by_county';
                                  if (await canLaunch(urlString)) {
                                    await launch(urlString);
                                  }
                                },
                              ),
                              FlatButton(
                                child: Text('Set County'),
                                onPressed: () async {
                                  if (_countySelectionFormKey.currentState.validate()) {
                                    //TODO set fips code
                                    onSetNewCounty(int.parse(_countySelectionController.value.text));
                                    Navigator.of(context).pop();
                                  }
                                },
                              )
                            ],
                          ));
                }),
          ), //TODO graph or flag
        ),
        fit: FlexFit.tight,
      ),
      Divider(
        thickness: 1.0,
      ),
      Flexible(
        //TODO make this swipable, revealing correspending averages, stdevs, and values from data?
        child: Padding(
          padding: const EdgeInsets.all(12.0).copyWith(bottom: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Standard Score Values',
                style: Theme.of(context).textTheme.headline5,
              ),
              Padding(padding: const EdgeInsets.symmetric(vertical: 4.0)),
              StatisticRow('14 Day Case Increase per 10,000 people',
                  data['fortnightCases']),
              Spacer(),
              StatisticRow('14 Day Death Increase per 10,000 people',
                  data['fortnightDeaths']),
              Spacer(),
              StatisticRow('State Hospitalizations', data['hospitalizations']),
              Spacer(),
              StatisticRow(
                  'Fatality Rate Per 10,000 People', data['fatalityRate']),
            ],
          ),
        ),
        fit: FlexFit.tight,
        flex: 1,
      ),
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
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
            style: Theme.of(context).textTheme.subtitle1.copyWith(
                color: _statisticValue < 0 ? Colors.red : Colors.green),
            textAlign: TextAlign.right,
          ),
          fit: FlexFit.tight,
        ),
      ],
    );
  }
}
