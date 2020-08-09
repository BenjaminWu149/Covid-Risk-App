import 'package:flutter/material.dart';

class MaskHandlingInfo extends StatelessWidget {
  //Note: this is wearing and removing
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
          child: Center(
            child: Text(
              'Mask Handling',
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Divider(
          thickness: 1.0,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0.0),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Wearing',
                  style: Theme.of(context).textTheme.headline5.copyWith(
                      fontSize: Theme.of(context).textTheme.headline4.fontSize),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '''
• Wash your hands before putting on your mask.
• Put it over your nose and mouth and secure it under your chin.
• Try to fit it snugly against the sides of your face.
• Make sure you can breathe easily.
• Do not put the mask around your neck or up on your forehead.
• Do not touch the mask, and, if you do, wash your hands or use hand sanitizer to disinfect.''',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: Theme.of(context).textTheme.headline5.fontSize),
                textAlign: TextAlign.left,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0)
                    .copyWith(top: 16.0),
                child: Text(
                  'Removing',
                  style: Theme.of(context).textTheme.headline5.copyWith(
                      fontSize: Theme.of(context).textTheme.headline4.fontSize),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '''
• Wash your hands prior to removal.
• Do not touch the front of the mask or your face.
• Carefully remove your mask by grasping the ear loops or untying the ties. For masks with a pair of ties, unfasten the bottom ones first, then the top ones.
• Make sure you can breathe easily
• If your mask has filters, remove them and throw them away. Fold the mask and put it directly into the laundry or into a disposable or washable bag for laundering.
• Clean your hands again.''',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: Theme.of(context).textTheme.headline5.fontSize),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        )
      ],
    );
  }
}

class MaskMaintenanceInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
          child: Center(
            child: Text(
              'Mask Maintenance',
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Divider(
          thickness: 1.0,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0.0),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Cleaning bandannas, face scarves, and masks made of fabric',
                  style: Theme.of(context).textTheme.headline5.copyWith(
                      fontSize: Theme.of(context).textTheme.headline4.fontSize),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '''
• Wash your hands before putting on your mask.
• Put it over your nose and mouth and secure it under your chin.
• Try to fit it snugly against the sides of your face.
• Make sure you can breathe easily.
• Do not put the mask around your neck or up on your forehead.
• Do not touch the mask, and, if you do, wash your hands or use hand sanitizer to disinfect.''',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: Theme.of(context).textTheme.headline5.fontSize),
                textAlign: TextAlign.left,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0)
                    .copyWith(top: 16.0),
                child: Text(
                  'Cleaning disposable, blue surgical masks, and N95 respirators',
                  style: Theme.of(context).textTheme.headline5.copyWith(
                      fontSize: Theme.of(context).textTheme.headline4.fontSize),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '• Do not clean, throw away the mask when it is visibly soiled or damaged. These masks are designed to be used once.',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: Theme.of(context).textTheme.headline5.fontSize),
                textAlign: TextAlign.left,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0)
                    .copyWith(top: 16.0),
                child: Text(
                  'Storage',
                  style: Theme.of(context).textTheme.headline5.copyWith(
                      fontSize: Theme.of(context).textTheme.headline4.fontSize),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '''
• Store masks in a covered container or bag until you are ready to wear them.
• Exposure to UV rays (e.g. sunlight) will kill the virus more quickly''',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: Theme.of(context).textTheme.headline5.fontSize),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        )
      ],
    );
  }
}

class CovidInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
          child: Center(
            child: Text(
              'COVID Information',
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Divider(
          thickness: 1.0,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0.0),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Transmission',
                  style: Theme.of(context).textTheme.headline5.copyWith(
                      fontSize: Theme.of(context).textTheme.headline4.fontSize),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '''
• COVID can be transmitted before a person starts showing symptoms.
• The virus is an airborne.
• Transmission through infected surfaces is unlikely if you wash your hands regularly.
• The virus can stay in the air for hours.
• Social distancing helps less when ventilation is poor.''',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: Theme.of(context).textTheme.headline5.fontSize),
                textAlign: TextAlign.left,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Risk Mitigation',
                  style: Theme.of(context).textTheme.headline5.copyWith(
                      fontSize: Theme.of(context).textTheme.headline4.fontSize),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '''
• Always wear a mask when in the vicinity of others. Masks reduce (potentially infected) particle spread.
• Practice social distancing; attempt to stand at least 6 feet away from others.
• Stay home if you are sick.
• Maximize time spent in well ventilated areas, such as outdoors.''',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: Theme.of(context).textTheme.headline5.fontSize),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        )
      ],
    );
  }
}

class MethodInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
          child: Center(
            child: Text(
              'Methodology and Sources',
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Divider(
          thickness: 1.0,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0.0),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Standard Scores',
                  style: Theme.of(context).textTheme.headline5.copyWith(
                      fontSize: Theme.of(context).textTheme.headline4.fontSize),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '''
• Standard scores are a statistical tool for calculating how far a number is from the mean.
• They are calculated by subtracting the raw score (e.g. number of cases) from the mean and divided by standard deviations. Therefore, they effectively range from -3 to +3.
• Summary scores are calculated by summing standard scores. They allow you to compare cases (e.g. county risk measures).
• The summary standard score is the standard score of the county among all US counties.''',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: Theme.of(context).textTheme.headline5.fontSize),
                textAlign: TextAlign.left,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Sources',
                  style: Theme.of(context).textTheme.headline5.copyWith(
                      fontSize: Theme.of(context).textTheme.headline4.fontSize),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '''
• County Risk Data is sourced from USA Facts and the Covid Tracking Project.
• Mask maintenance and cleaning information is sourced from the FDA and the CDC.
• COVID information is sourced from news articles containing advice from professionals. Sources may include Slate, the Atlantic, Business Insider, etc.''',
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: Theme.of(context).textTheme.headline5.fontSize),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        )
      ],
    );
  }
}
