import 'dart:convert';

import 'package:cached_data_repository_manager/graphql/entities/gql_query.dart';
import 'package:cached_data_repository_manager/utils/typedefs.dart';

/// Class used to send multiple queries in a single one.
///
/// Useful to avoid multiple request pending time.
///
/// **Note :** Be careful when using it, because request will not resolve **until ALL queries resolved.**
/// Consider the pros & cons before use a Batch Query depending on the complexity of the total amount of requests.
class GraphQlBatchQuery {
  final List<GQLQuery> queries;

  GraphQlBatchQuery(this.queries);

  /// Transform a list of `GQLQuery` into a valid GraphQL schema body (to be sent as JSON array)
  String prepareBody() {
    JsonArray body = [];

    for (var query in queries) {
      String normalizedASTDocument = query.document.replaceAll("\n", " ");
      Json queryBody = <String, dynamic>{};

      queryBody['query'] = normalizedASTDocument;

      if (query.variables.isNotEmpty || query.first != null || query.page != null) {
        queryBody['variables'] = query.variables;
      }

      body.add(queryBody);
    }

    return jsonEncode(body).replaceAll("\\n", "\n");
  }
}
