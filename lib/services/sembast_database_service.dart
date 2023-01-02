import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

final sembastDatabaseService = Provider(((ref) => SembastDatabaseService()));

class SembastDatabaseService {
  Database? database;
  String? _databasePath;

  Future<void> initialize() async {
    Directory appDirectory = await getApplicationDocumentsDirectory();
    await appDirectory.create(recursive: true);

    _databasePath = "${appDirectory.path}/app.db";
    database = await databaseFactoryIo.openDatabase(_databasePath!);
  }

  Future<void> deleteDatabase() async {
    await database!.close();
    await databaseFactoryIo.deleteDatabase(_databasePath!);
  }
}