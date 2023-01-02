import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cached_data_repository_manager/application/repository_parser.dart';
import 'package:cached_data_repository_manager/cache/data/cache_repository.dart';
import 'package:cached_data_repository_manager/cache/domain/cache_record.dart';
import 'package:cached_data_repository_manager/exceptions/document_name_not_found.dart';
import 'package:cached_data_repository_manager/graphql/entities/gql_batch_query.dart';
import 'package:cached_data_repository_manager/graphql/entities/gql_batch_query_result.dart';
import 'package:cached_data_repository_manager/graphql/entities/gql_query.dart';
import 'package:cached_data_repository_manager/graphql/entities/gql_result.dart';
import 'package:cached_data_repository_manager/graphql/entities/repository_policy.dart';
import 'package:cached_data_repository_manager/services/graphql_service.dart';
import 'package:cached_data_repository_manager/utils/typedefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql/client.dart';

/// Base class for all GraphQL requests to be made through the app.
///
/// This allow cache save and query on requests through the [RepositoryPolicy] provided by the child class / caller.
///
class BaseRepository with RepositoryParser {
  @protected
  late final Ref ref;

  BaseRepository({required this.ref});

  /// Basic maximum [Duration] while HTTP client will wait for response before checking data in internal store.
  Duration maxTimerDelay = const Duration(seconds: 6);

  /// How the repository should behave for queries. Default set to [RepositoryPolicy.cacheFirst]
  RepositoryPolicy policy = RepositoryPolicy.cacheFirst;

  Duration cacheDuration = const Duration(minutes: 10);

  @protected
  @visibleForTesting
  Future<GQLResult?> fetchOne(GQLQuery query, {RepositoryPolicy? policyOverride, Duration? cacheDurationOverride}) async {
    return await runQuery(
      query,
      query.documentName,
      policyOverride: policyOverride,
      cacheDurationOverride: cacheDurationOverride,
    );
  }

  @protected
  @visibleForTesting
  Future<GQLResult?> fetchMultiple(GQLQuery query, {RepositoryPolicy? policyOverride, Duration? cacheDurationOverride}) async {
    return await runQuery(
      query,
      query.documentName,
      manyResults: true,
      policyOverride: policyOverride,
      cacheDurationOverride: cacheDurationOverride,
    );
  }

  /// Fetch a list or a single element returned as raw result (set in the [GQLResult.rawData]).
  /// (`EmptyRepositoryException`, `SocketException` or `TimeoutException`) if no data available.
  ///
  /// If remote request did not success in the defined [maxTimerDelay], will check cache (if [RepositoryPolicy] allows it) to return data.
  /// Otherwise, throws an error and displays a message to the user regardless of his connectivity.
  ///
  /// Fetch order and permission depend on the [BaseRepository.policy]. If the request needs a special behaviour
  /// for this request, providing `policyOverride` will override the instance policy.
  ///
  /// [GQLQuery] argument allows to specify chunk sizes, order, filters & offset.
  @visibleForTesting
  Future<GQLResult?> runQuery(
    GQLQuery query,
    String documentName, {
    bool manyResults = false,
    RepositoryPolicy? policyOverride,
    Duration? cacheDurationOverride,
  }) async {
    RepositoryPolicy queryPolicy = policyOverride ?? policy;
    bool cacheQueryFailed = false;
    bool remoteQueryFailed = false;
    GQLResult? networkResult;
    GQLResult? cacheResult;

    /// Check in cache if query has already been fetched and save to cache in the last [invalidCacheDuration]
    if (shouldFirstFetchInCache(queryPolicy)) {
      cacheResult = await runCacheQuery(query, cacheDurationOverride: cacheDurationOverride);

      cacheQueryFailed = cacheResult?.rawData == null;
    }

    if (shouldFetchNetwork(cacheQueryFailed, queryPolicy)) {
      networkResult = await runRemoteQuery(query);

      // Case network fetch is successful, we could unawait the task but due to concurrent read/write operations
      // we have to wait for cache to be synchronized
      if (shouldSaveToCache(queryPolicy)) {
        if (networkResult?.rawData != null) {
          query.setResult(networkResult!.rawData!);
          await runCacheSync(query);
        }
      }
      if (networkResult == null) {
        return null;
      } else if (networkResult.exception == null) {
        return networkResult;
      } else {
        remoteQueryFailed = true;
      }
    }

    // If cache query succeed -> now update the cache from network
    if (!cacheQueryFailed && queryPolicy == RepositoryPolicy.cacheFirst) {
      // Voluntary not awaiting this task, so that cache result is returned without waiting for network fetch
      updateCacheFromNetwork(query);

      return cacheResult;
    }

    // Case data must be fetched from cache after Network fetch was tried
    if (remoteQueryFailed && willExecuteOnCacheIfNetworkFails(queryPolicy)) {
      cacheResult = await runCacheQuery(query, cacheDurationOverride: cacheDurationOverride);
    } else {
      // Cache must not try to fetch data, so throw catched exceptions
      throw networkResult!.exception!;
    }

    // If none of the fetch succeed, returns null
    if (cacheResult?.rawData == null) {
      return null;
    }

    return cacheResult;
  }

  /// Run a GraphQL batch query.
  ///
  /// Depending on the authentication state of the user, this will either send the
  /// request as anonymous, or as authenticated.
  ///
  /// Any error can be additionnally handled here, but must be handled into UI
  /// components to be shown to the user
  Future<GraphQlBatchQueryResult> runBatchQuery(GraphQlBatchQuery query, String url) async {
    // ignore: unused_local_variable
    String body = query.prepareBody();

    DateTime startTime = DateTime.now();
    JsonArray result;

    // Somehow call your api service to get your data
    result = await Future.value([{}]);

    log("[GraphQL batch query] request success (${DateTime.now().difference(startTime).inMilliseconds} ms)");

    return GraphQlBatchQueryResult(result, false, DateTime.now());
  }

  /// Request the specified [query] to the network.
  ///
  /// Once it's done, depending on [RepositoryPolicy], will seek for a similar query previously requested
  /// to update its data result and syncAt value. If the query has never been requested
  @protected
  Future<void> updateCacheFromNetwork(GQLQuery query) async {
    try {
      GQLResult? networkResult = await runRemoteQuery(query);

      // Case network fetch is successful, saving to cache
      if (networkResult?.rawData != null) {
        query.setResult(networkResult!.rawData!);
        await runCacheSync(query);
      }
    } catch (_) {
      // Not handling error as we just try to update cache as a background task
      return;
    }
  }

  /// Delegates the cache data sync to the [CacheRepository].
  @visibleForTesting
  Future<void> runCacheSync(GQLQuery query) async {
    await ref.read(cacheRepository).syncQuery(query);
  }

  @visibleForTesting
  Future<GQLResult?> runRemoteQuery(GQLQuery query) async {
    try {
      log("[GraphQL] request to document ${query.documentName}", level: 10);

      QueryResult? result = await ref.read(graphqlServiceProvider).query(query.toQueryOptions(), auth: query.authType).timeout(maxTimerDelay, onTimeout: () {
        throw TimeoutException('Server could not be reached, please check your internet connection and retry', maxTimerDelay);
      });

      // Can be null if user is unauthenticated
      if (result != null) {
        result.parserFn = (data) => sanitizeResult(data);

        // Handling http exceptions
        if (result.hasException) {
          // Parser errors
          if (result.exception!.graphqlErrors.isNotEmpty) {
            for (GraphQLError error in result.exception!.graphqlErrors) {
              log(error.message);
            }
          }

          // Remote error
          if (result.exception!.linkException != null) {
            // Log.write(result.exception.linkException.originalException.toString());
            return GQLResult.fromException(result.exception!.linkException!.originalException);
          }
        }

        // Server response is null
        if (result.data == null) {
          throw Exception("API returned empty data");
        }

        if (result.data!.containsKey(query.documentName)) {
          return GQLResult(result.parsedData! as Json, query.documentName);
        } else {
          throw DocumentNameNotFoundException(query.documentName);
        }
      }

      return null;
    } on Exception catch (e) {
      if (e is TimeoutException || e is SocketException || e is HandshakeException) {
        return GQLResult.fromException(e);
      } else {
        rethrow;
      }
    }
  }

  @visibleForTesting
  Object? sanitizeResult(Object? rawData) {
    if (rawData != null) {
      JsonArray array = [if (rawData is List) ...rawData else rawData as Json];
      JsonArray newArray = [];

      for (Json json in array) {
        if (json.keys.toSet().containsAll({'data', '__typename'}) && (json['__typename'] as String).contains("Paginator")) {
          dynamic data = json['data'];

          return data is Map<String, dynamic> || data is List ? sanitizeResult(data) : data;
        } else {
          Map<String, dynamic> result = {};

          for (final entry in json.entries) {
            dynamic value = entry.value;

            result[entry.key] = value is Map<String, dynamic> || value is List ? sanitizeResult(value) : value;
          }
          if (rawData is Map<String, dynamic>) {
            return result;
          } else {
            newArray.add(result);
          }
        }
      }

      return newArray;
    }

    return null;
  }

  /// Delegates the cache query to the [cacheRepository].
  ///
  /// Returns null if no matching record has been found, or if cache data is outdated.
  /// Cache duration depends on the [cacheDurationOverride] class property, or can be overriden
  /// by
  @protected
  @visibleForTesting
  Future<GQLResult?> runCacheQuery(GQLQuery query, {Duration? cacheDurationOverride}) async {
    CachedRecord? record = await ref.read(cacheRepository).query(
          query,
          cacheDuration: cacheDurationOverride ?? cacheDuration,
        );
    return record != null
        ? GQLResult(
            record.data,
            query.documentName,
            syncAt: record.syncAt,
            fromCache: true,
          )
        : null;
  }
}
