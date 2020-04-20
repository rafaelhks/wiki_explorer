import 'datamodel.dart';

class Favorite extends DataModel{
  final String tableName = 'favorite', colId = 'fav_id', colLink='fav_link', colName='fav_name';

  int id;
  String link;
  String name;

  Favorite();

  Map<String , dynamic> toMap(){
      var map = new Map<String , dynamic>();
      map[colLink]= link;
      map[colName] = name;
      if(id != null){
        map[colId] = id;
      }
      return map;
  }

  Favorite.fromMap(Map<String , dynamic>map){
    this.id = map[colId];
    this.link = map[colLink];
    this.name = map[colName];
  }

  static String createTable(){
      var t = new Favorite();
      return '''CREATE TABLE ${t.tableName} (
            ${t.colId} INTEGER PRIMARY KEY,
            ${t.colName} TEXT NOT NULL,
            ${t.colLink} TEXT NOT NULL
          )''';
  } 
}