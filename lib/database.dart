import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

import 'model/datamodel.dart';
import 'model/favorite.dart';

class DatabaseHelper {
  static final _databaseName = "MyDatabase.db";
  static final _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }
  
  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(Favorite.createTable());
  }

  Future<int> insert(DataModel i) async{
      var dbClient = await instance.database;
      print('Insert: '+i.toMap().toString());
      int result = await dbClient.insert(i.tableName, i.toMap());
      return result;
  }

  Future<int> delete(DataModel m, int id) async{
    var dbClient = await instance.database;
    return  await dbClient.delete(
        m.tableName, where: m.colId+" = ?" , whereArgs: [id]
    );
  }

  Future<int> deleteWhere(DataModel m, String where, List<dynamic> whereArgs) async{
    var dbClient = await instance.database;
    return  await dbClient.delete(
        m.tableName, where: where , whereArgs: whereArgs
    );
  }

  Future<int> update(DataModel u, Object id) async{
    var dbClient = await instance.database;
    print('Update: '+u.toString());
    return  await dbClient.update(
        u.tableName ,u.toMap(), where: u.colId+" = ?" , whereArgs: [id]
    );
  }

  Future<List<int>> insertAll(List<DataModel> models) async{
    var dbClient = await instance.database;
    dbClient.execute("BEGIN TRANSACTION;");
    List<int> res = new List();
    for (var item in models) {
      int result = await dbClient.insert(item.tableName, item.toMap());
      if(result!=null && result>0){
        print("inseriu");
        res.add(result);
      }
    }

    if(res.length == models.length){
      dbClient.execute("COMMIT;");
      print("comitou");
    }else{
      dbClient.execute("ROLLBACK;");
      print("rollbacou");
    }
    return res;
  }

  Future<List> listWhere(DataModel tableModel, String where) async{
    try {
      var dbClient = await instance.database;
      var result = await dbClient.query(tableModel.tableName, where: where);
      return result.toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List> list(DataModel tableModel) async{
    var dbClient = await instance.database;
    var result = await dbClient.query(tableModel.tableName);
    print(result.length);
    return result.toList();
  }

  Future<Map<String, dynamic>> select(String table, String where) async{
    var dbClient = await instance.database;
    var result = await dbClient.query(table, where: where);
    var list = result.toList();
    if(list.length>0){
      return list[0];
    }
    return null;
  }

  Future<int> count(String table, String where) async{
    var dbClient = await instance.database;
    var result = Sqflite.firstIntValue(await dbClient.rawQuery('SELECT COUNT(*) FROM $table WHERE $where'));
    print(result);
    return result;
  }

  Future<void> close() async{
    var dbClient = await instance.database;
    return  await dbClient.close();
  }
}