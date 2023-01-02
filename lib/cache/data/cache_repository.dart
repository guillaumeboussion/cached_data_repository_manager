import 'package:cached_data_repository_manager/cache/domain/cache_record.dart';
import 'package:cached_data_repository_manager/constants/sembast_stores.dart';
import 'package:cached_data_repository_manager/graphql/entities/gql_query.dart';
import 'package:cached_data_repository_manager/services/sembast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

final cacheRepository = Provider((ref) => CacheRepository(read: ref));

class CacheRepository {
  final Ref _ref;

  /// Each repository set its own cache duration.
  /// Note: In the future, will be good to have control on the request level.
  CacheRepository({required Ref read}) : _ref = read;

  /// Return null if cache data can't be used or query is not matching any result.
  ///
  /// Check in the cache if a similar request has been done in the last [cacheValidity] duration.
  /// If [GQLQuery.document] and [GQLQuery.variables] are matching store data but [cacheValidity] has expired,
  /// row is deleted from the store.
  Future<CachedRecord?> query(GQLQuery searchQuery, {Duration? cacheDuration}) async {
    CachedRecord? cachedRecord = await searchMatchingRecord(searchQuery.document.trim(), searchQuery.variables);
    Duration cacheValidity = cacheDuration ?? const Duration(minutes: 10);

    if (cachedRecord != null) {
      if (DateTime.now().difference(cachedRecord.syncAt) > cacheValidity) {
        await deleteOutdatedRecord(cachedRecord);
        return null;
      }
    }

    return cachedRecord;
  }

  /// Synchronize the given query into the cache Sembast store.
  ///
  /// This will first look into the store for a similar query, updating its result if a record match.
  /// Otherwise, will insert the query as a new record.
  Future<void> syncQuery(GQLQuery query) async {
    CachedRecord? recordRef = await searchMatchingRecord(query.document.trim(), query.variables);

    if (recordRef == null) {
      await record(query);
    } else {
      recordRef.updateData(query.result!);
      await updateRecord(recordRef);
    }
  }

  /// Add a given [query] with its data into the cache store.
  ///
  /// Queries fetched from the server are stored as raw request into the main store. The main purpose
  /// of this cache management is to save remote requests as if they came directly from the server as long as
  /// they are up to date. This allows a common data process whether data is fetched from server or from the cache.
  ///
  /// Thus, uncacheable attributes are not handled here, Model constructor is responsible for removing them.
  Future<void> record(GQLQuery query) async {
    await _ref.read(sembastService).storeOne(
      value: query.toRecordable(),
      storeName: SembastStores.graphqlCache,
    );
  }

  /// Search whether [graphQLDocument] and [variables] are matching a row in the [store].
  ///
  /// Returns null if no matching data was found.
  Future<CachedRecord?> searchMatchingRecord(String graphQLDocument, Map<String, dynamic> variables) async {
    Finder finder = Finder(
      filter: Filter.and(
        [
          Filter.equals('query', graphQLDocument),
          Filter.equals('variables', variables),
        ],
      ),
    );

    final recordSnapshot = await _ref.read(sembastService).getOne(finder: finder, storeName: SembastStores.graphqlCache);

    return recordSnapshot != null ? CachedRecord.fromCache(recordSnapshot) : null;
  }

  /// Update a [CachedRecord] by its key.
  Future<void> updateRecord(CachedRecord record) async {
    Finder finder = Finder(filter: Filter.byKey(record.key));
    await _ref.read(sembastService).updateOne(
      value: record.toRecordable(),
      finder: finder,
      storeName: SembastStores.graphqlCache,
    );
  }

  /// Delete the [CachedRecord] by its key.
  Future<void> deleteOutdatedRecord(CachedRecord record) async {
    Finder finder = Finder(filter: Filter.byKey(record.key));
    await _ref.read(sembastService).deleteOne(
      finder: finder,
      storeName: SembastStores.graphqlCache,
    );
  }
}
