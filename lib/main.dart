import 'package:flutter/material.dart';

import 'app_notification.dart';
import 'app_storage.dart';
import 'harvest_tracker_app.dart';
import 'schedule_task.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var isReg = await AppStorage.isRegisteredNotification();
  if (!isReg) {
    setupNotification();
    workManagerInitialize();
    AppStorage.setRegisteredNotification();
  }

  runApp(HarvestTrackerApp());
}
