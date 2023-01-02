import 'package:cached_data_repository_manager/services/sembast_database_service.dart';
import 'package:cached_data_repository_manager/utils/typedefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

final sembastService = Provider((ref) => SembastService(read: ref));

class SembastService {
  final Ref _ref;

  SembastService({required Ref read}) : _ref = read;

  Future<List<SembastRecord>> get({required String storeName, Finder? finder}) async {
    final store = intMapStoreFactory.store(storeName);
    final database = _ref.read(sembastDatabaseService).database!;

    return await store.find(database, finder: finder);
  }

  Future<SembastRecord?> getOne({required Finder finder, required String storeName}) async {
    final store = intMapStoreFactory.store(storeName);
    final database = _ref.read(sembastDatabaseService).database!;

    return await store.findFirst(database, finder: finder);
  }

  Future<void> updateOne({required Json value, required Finder finder, required String storeName}) async {
    final store = intMapStoreFactory.store(storeName);
    final database = _ref.read(sembastDatabaseService).database!;

    await store.update(database, value, finder: finder);
  }

  Future<void> storeOne({required Json value, required String storeName}) async {
    final store = intMapStoreFactory.store(storeName);
    final database = _ref.read(sembastDatabaseService).database!;

    await store.add(database, value);
  }

  Future<void> deleteOne({required Finder finder, required String storeName}) async {
    final store = intMapStoreFactory.store(storeName);
    final database = _ref.read(sembastDatabaseService).database!;

    await store.delete(database, finder: finder);
  }
}
