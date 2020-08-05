import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';

import 'app_storage.dart';
import 'place_action.dart';
import 'harvest_tracker_app.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();
final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();
NotificationAppLaunchDetails notificationAppLaunchDetails;

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}

Future<void> setupNotification() async {
  var settingsAndroid = AndroidInitializationSettings('logo');
  // Note: permissions aren't requested here just to demonstrate that can be done later using the `requestPermissions()` method
  // of the `IOSFlutterLocalNotificationsPlugin` class
  var settingsIOS = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        didReceiveLocalNotificationSubject.add(ReceivedNotification(
            id: id, title: title, body: body, payload: payload));
      });

  var initializationSettings =
      InitializationSettings(settingsAndroid, settingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (payload) async {
    if (payload != null) {
      print('notification payload: ' + payload);
    }
    selectNotificationSubject.add(payload);
  });
}

void notificationInitialize(BuildContext context) {
  _requestIOSPermissions();
  _configureDidReceiveLocalNotificationSubject(context);
  _configureSelectNotificationSubject(context);
}

void _requestIOSPermissions() {
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

Future<void> _configureSelectNotificationSubject(BuildContext context) async {
  selectNotificationSubject.stream.listen((payload) async {
    await Navigator.push<void>(context, MaterialPageRoute(builder: (context) {
      return HarvestTrackerApp();
    }));

    /*  await showDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Confirm'),
        content: Text('Please select Navigation or Send Email'),
        actions: [
          CupertinoDialogAction(
            child: Text('Navigate'),
            onPressed: () async {
              await PlaceAction.onNavigationAction();
            },
          ),
          CupertinoDialogAction(
            child: Text('Send Email'),
            onPressed: () async {
              await PlaceAction.onSendEmailAction();
            },
          )
        ],
      ),
    );*/
  });
}

void _configureDidReceiveLocalNotificationSubject(BuildContext context) {
  didReceiveLocalNotificationSubject.stream
      .listen((receivedNotification) async {
    await showDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: receivedNotification.title != null
            ? Text(receivedNotification.title)
            : null,
        content: receivedNotification.body != null
            ? Text(receivedNotification.body)
            : null,
        actions: [
          CupertinoDialogAction(
            child: Text('Navigate'),
            onPressed: () async {
              await PlaceAction.onNavigationAction();
            },
          ),
          CupertinoDialogAction(
            child: Text('Send Email'),
            onPressed: () async {
              await PlaceAction.onSendEmailAction();
            },
          )
        ],
      ),
    );
  });
}

Future<void> showNotificationWithIconBadge(
    String title, String body, String payload, int cnt) async {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'icon badge channel', 'icon badge name', 'icon badge description');
  var iOSPlatformChannelSpecifics = IOSNotificationDetails(badgeNumber: cnt);
  var platformChannelSpecifics = NotificationDetails(
      androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin
      .show(0, title, body, platformChannelSpecifics, payload: payload);
}
