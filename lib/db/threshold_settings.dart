import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

class ThresholdDatabase {
  static final ThresholdDatabase instance = ThresholdDatabase._init();

  static Database? _database;
  ThresholdDatabase._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB("thresh.db");

    return _database!;
  }

  Future<Database> _initDB(String filepath) async {
    final dbpath = await getDatabasesPath();
    final path = '$dbpath/$filepath';

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    final textType = "TEXT NOT NULL";
    final integerType = "INTEGER NOT NULL";
    await db.execute('''
    CREATE TABLE IF NOT EXISTS thresh(
      _id $textType PRIMARY KEY,
      _threshVal $textType)''');
  }

  Future<Map> add(Map<String, dynamic> map) async {
    final db = await instance.database;
    final id = await db.insert(
      "thresh",
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return {
      "id": id,
      "val": map,
    };
  }

  Future<List> getAllAvailableThresh() async {
    final db = await instance.database;
    final orderby = '_id DESC';
    final result = await db.query('thresh', orderBy: orderby);

    return result;
  }

  Future<dynamic> getThresh(String id) async {
    final db = await instance.database;
    String enc = sha1.convert(utf8.encode(id)).toString();
    final result = await db.query(
      'thresh',
      where: '_id = ?',
      whereArgs: [enc],
    );
    if (result.isEmpty) {
      // print("Get id $id");
      if (id.contains("NPK")) {
        return {
          "N": 100000.0,
          "P": 100000.0,
          "K": 100000.0,
        };
      }

      return 100000.0;
    }
    // print("[DB] $result , $id");
    // String to num
    bool isConvertableToMap = result[0]["_threshVal"].toString().contains("/");
    if (isConvertableToMap) {
      List<String> numMap = result[0]["_threshVal"].toString().split("/");
      // Create map
      Map<String, num> multiVal = {
        "N": num.parse(numMap[0]),
        "P": num.parse(numMap[1]),
        "K": num.parse(numMap[2]),
      };

      return multiVal;
    }

    return num.parse(result[0]["_threshVal"].toString());
  }

  Future<Map> edit(Map<String, dynamic> map) async {
    final db = await instance.database;
    final id =
        await db.update('thresh', map, where: '_id = ?', whereArgs: map["_id"]);

    return {
      "id": id,
      "val": map,
    };
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
