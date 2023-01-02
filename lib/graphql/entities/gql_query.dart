import 'package:cached_data_repository_manager/auth/entities/auth.dart';
import 'package:cached_data_repository_manager/graphql/entities/filter.dart';
import 'package:graphql/client.dart';

class GQLQuery {
  final String document;
  final String documentName;
  final Map<String, dynamic>? _variables;
  final Filter? filter;
  final int? first;
  final int? page;
  final Auth authType;
  List<SortOrder>? sortOrders;
  Map<String, dynamic>? result;

  GQLQuery({
    required this.document,
    required this.documentName,
    Map<String, dynamic>? variables,
    this.filter,
    this.sortOrders,
    this.first,
    this.authType = Auth.guest,
    this.page,
  }) : _variables = variables {
    sortOrders ??= [];
  }

  /// Cast the entire [GQLQuery] to a [QueryOptions] object.
  ///
  /// **NOTE : it requires to perfectly respect naming convention when creating GraphQL query on the server side.**
  ///
  /// E.g : if a limit must be specified for a query, no other variable name than "limit" would be allowed in the top
  /// object
  ///
  /// In case variables are null, they're still inserted into the request, but they would not be read by the Laravel GraphQL client
  QueryOptions toQueryOptions() {
    return QueryOptions(
      document: gql(document),
      variables: variables,
    );
  }

  /// Instantiate [GQLQuery.result] if either one of remote or cache request succeed.
  void setResult(Map<String, dynamic> data) {
    result = data;
  }

  /// Return the query to be recordable in the Sembast query store.
  ///
  /// Do not provide [syncAt] unless it's for testing purpose.
  Map<String, dynamic> toRecordable({DateTime? syncAt}) {
    return <String, dynamic>{
      'query': document.trim(),
      'variables': variables,
      'data': result,
      'syncAt': syncAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> get variables {
    Map<String, dynamic> variables = {};

    if (filter != null) {
      variables['filter'] = filter!.toGraphQLFilter;
    }

    if (sortOrders != null && sortOrders!.isNotEmpty) {
      List<Map<String, dynamic>> jsonSortOrders = [];

      for (int i = 0; i < sortOrders!.length; i++) {
        jsonSortOrders.add(sortOrders![i].toJsonObject);
      }

      variables['orderBy'] = jsonSortOrders;
    }

    if (first != null) {
      variables['first'] = first;
    }

    if (page != null) {
      variables['page'] = page;
    }

    if (_variables != null) {
      // Adding already referenced variables
      variables.addAll(_variables!);
    }

    return variables;
  }

  GQLQuery copy() {
    return GQLQuery(
      document: document,
      documentName: documentName,
      filter: filter,
      sortOrders: sortOrders,
      first: first,
      page: page,
    );
  }
}
