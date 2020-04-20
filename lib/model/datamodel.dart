abstract class DataModel {
  DataModel();
  Map<String , dynamic> toMap();
  DataModel.fromMap(Map<String , dynamic>obj);
  String get tableName;
  String get colId;
}