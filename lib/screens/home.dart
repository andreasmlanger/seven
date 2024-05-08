import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:seven/services/mvg_api.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Timer? _timer;
  Map<String, dynamic> result = {'message': 'Searching', 'loading': true};
  bool idle = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), updateScreen);
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  Future<void> updateScreen(Timer timer) async {
    if (idle) {
      setState(() {
        idle = false;
      });
      final apiResult = await getNextDeparture();
      setState(() {
        result = apiResult;
        idle = true;
      });
    }
  }

  Widget personIcon(time, distanceInMeters) {
    int differenceInMinutes = time.difference(DateTime.now()).inMinutes;
    int walkingTimeInMinutes = differenceInMinutes > 2 ? differenceInMinutes - 2 : 0;  // subtract 2 minutes preparation time
    double minutesPerHundredMeters = walkingTimeInMinutes / distanceInMeters * 100;
    if (distanceInMeters < 50) {
      return Icon(
        FontAwesomeIcons.trainSubway,
        color: Colors.green,
        size: 28.0,
      );
    } else if (minutesPerHundredMeters > 3) {
      return Icon(
        FontAwesomeIcons.person,
        color: Colors.blue,
        size: 28.0,
      );
    } else if (minutesPerHundredMeters > 2) {
      return Icon(
        FontAwesomeIcons.personWalking,
        color: Colors.green,
        size: 28.0,
      );
    } else if (minutesPerHundredMeters > 1) {
      return Icon(
        FontAwesomeIcons.personRunning,
        color: Colors.orange,
        size: 28.0,
      );
    } else {
      return Icon(
        FontAwesomeIcons.personDrowning,
        color: Colors.red,
        size: 28.0,
      );
    }
  }

  Widget departureTimeWidget() {
    if (result.containsKey('message')) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (result['loading'])
            const SpinKitChasingDots(
              color: Colors.white,
              size: 40.0,
            ),
          SizedBox(height: 25.0, width: MediaQuery.of(context).size.width),
          Text(
            result['message']!,
            style: customTextStyle(32.0),
          ),
        ],
      );
    } else {  // S7 was found
      return Padding(
        padding: const EdgeInsets.only(left: 35.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next', style: customTextStyle(28.0)),
                Image.asset('assets/s7.png', height: 48.0),
                Text('from', style: customTextStyle(28.0)),
              ],
            ),
            Text(
              "${result['name']} (${result['distanceInMeters']} m)",
              style: customTextStyle(28.0),
            ),
            SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: personIcon(result['realtimeDepartureTime'], result['distanceInMeters']),
                        ),
                      ),
                    ],
                  ),
                  TextSpan(
                    text: DateFormat('HH:mm').format(result['realtimeDepartureTime']),
                    style: customTextStyle(100.0),
                  ),
                  TextSpan(
                    text: " +${result['delayInMinutes']}",
                    style: customTextStyle(
                      50.0,
                      color: result['delayInMinutes'] != 0 ? Colors.red : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  TextStyle customTextStyle(double fontSize, {Color color = Colors.white}) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      fontFamily: 'IndieFlower',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: departureTimeWidget(),
        ),
      ),
    );
  }
}
