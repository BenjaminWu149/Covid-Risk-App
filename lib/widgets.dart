import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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