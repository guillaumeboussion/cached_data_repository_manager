import 'dart:developer' as dev;
import 'package:cached_data_repository_manager/auth/entities/access_tokens.dart';
import 'package:cached_data_repository_manager/auth/entities/auth.dart';
import 'package:cached_data_repository_manager/services/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql/client.dart';

final graphqlServiceProvider = Provider((ref) => GraphqlService(read: ref));

class GraphqlService {
  final Ref _ref;

  GraphqlService({required read}) : _ref = read;

  AccessTokens tokens() => _ref.read(accessTokensProvider);

  Future<Map<String, String>> getHeaders(Auth auth) async {
    // TODO : set your headers here if you need to set custom ones
    return <String, String>{
      'User-Agent': 'userAgent',
      'Authorization': auth == Auth.guest ? tokens().guestToken.toHeader : tokens().userToken!.toHeader,
    };
  }

  bool isUnauthenticatedException(OperationException exception) {
    return exception.linkException != null && exception.linkException is HttpLinkServerException && (exception.linkException as HttpLinkServerException).response.statusCode == 401;
  }

  Future<QueryResult?> query(QueryOptions document, {Auth auth = Auth.guest}) async {
    // Setting headers
    HttpLink http = HttpLink(_ref.read(configurationProvider).config!.graphqlEndpoint, defaultHeaders: await getHeaders(auth));

    // Logging query performance
    DateTime startTime = DateTime.now();

    GraphQLClient client = GraphQLClient(link: http, cache: GraphQLCache());
    QueryResult queryResult = await client.query(document);

    if (!queryResult.hasException) {
      dev.log("[GraphQL] request success (${DateTime.now().difference(startTime).inMilliseconds} ms)");
    } else {
      if (isUnauthenticatedException(queryResult.exception!)) {
        // TODO : set an action on logout
        return null;
      }
    }

    return queryResult;
  }
}
