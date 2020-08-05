import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

import 'app_notification.dart';
import 'app_storage.dart';
import 'google_drive_task.dart';

const notificationTask = 'Harvest Notification';
const backupTask = 'Harvest Backup';

void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    if (task == notificationTask) {
      await checkForHarvest();
    }
    return true;
  });
}

Future<void> checkForHarvest() async {
  var now = DateTime.now();
  /* if (now.hour != 5 && now.hour != 20) {
    AppStorage.setRunNotification(true, false);
    AppStorage.setRunNotification(false, false);
    return;
  }
  if ((now.hour == 5 && (await AppStorage.isRunNotification(true))) ||
      (now.hour == 20 && (await AppStorage.isRunNotification(false)))) {
    return;
  } */
  var today = DateFormat('dd/MM/yyyy').format(now);
  var tmrw = DateFormat('dd/MM/yyyy').format(now.add(Duration(days: 1)));

  var plList = await AppStorage.getFromStorage();
  var cnt = 0;
  for (var place in plList) {
    var readyDate = DateFormat('dd/MM/yyyy').parse(place.readyDate);
    if ((now.hour == 20) &&
        (place.readyDate == tmrw || readyDate.isBefore(now))) {
      cnt += place.countTrees;
    } else if (now.hour == 5 &&
        (place.readyDate == today || readyDate.isBefore(now))) {
      cnt += place.countTrees;
    }
  }
  cnt = 3;

  var msg = '';
  if (cnt != 0) {
    msg = now.hour == 5
        ? '$cnt Trees are ready for harvesting, click here to see them'
        : '$cnt Trees will be ready to harvest tomorrow, click here to see them';
    var title = 'Note: ' + DateFormat('dd/MM/yyyy hh:mm').format(now);
    AppStorage.setRunNotification(now.hour == 5, true);
    await showNotificationWithIconBadge(title, msg, '', cnt);
  }
}

Future<void> backupHarvest() async {
  var plList = await AppStorage.getFromStorage();
  var gDriveMng = GoogleDriveManager();
  await gDriveMng.loginWithGoogle();
  if (signedIn) gDriveMng.uploadFileToGoogleDrive(jsonEncode(plList));
}

// start background service
void workManagerInitialize() {
  var now = DateTime.now();
  var delayNotify = (60 - now.minute) + 10;

  Workmanager.initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager.registerPeriodicTask(
    '2',
    notificationTask,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    /* frequency: Duration(minutes: 15),
    initialDelay: Duration(seconds: 30), */
    frequency: Duration(minutes: 15),
    initialDelay: Duration(minutes: delayNotify),
  );
}
