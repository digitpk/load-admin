// database.dart
import 'dart:async';

import 'package:floor/floor.dart';
import 'package:load_admin/dao/barcode_dao.dart';
import 'package:load_admin/model/barcode.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [Barcode])
abstract class AppDatabase extends FloorDatabase {
  BarcodeDao get barcodeDao;
}
