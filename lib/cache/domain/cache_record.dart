import 'package:cached_data_repository_manager/utils/typedefs.dart';
import 'package:sembast/sembast.dart';

class CachedRecord {
  int key;
  String query;
  Map<String, dynamic> variables;
  Map<String, dynamic> data;
  DateTime syncAt;

  CachedRecord({
    required this.key,
    required this.variables,
    required this.query,
    required this.data,
    required this.syncAt,
  });

  void updateData(Map<String, dynamic> data) {
    this.data = data;
    syncAt = DateTime.now();
  }

  static CachedRecord? fromCache(RecordSnapshot? record) {
    if (record == null) {
      return null;
    }
    return CachedRecord(
      key: record.key,
      query: record['query'] as String,
      variables: record['variables'] as Json,
      // To mutable map
      data: record.value['data'] != null ? Map.of(record.value['data']) : {},
      syncAt: DateTime.fromMillisecondsSinceEpoch(record.value['syncAt']),
    );
  }

  Map<String, dynamic> toRecordable() {
    return <String, dynamic>{
      "query": query,
      "variables": variables,
      "data": data,
      "syncAt": syncAt.millisecondsSinceEpoch
    };
  }
}
