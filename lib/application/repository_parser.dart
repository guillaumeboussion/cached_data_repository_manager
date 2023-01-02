import 'package:cached_data_repository_manager/graphql/entities/gql_result.dart';
import 'package:cached_data_repository_manager/utils/typedefs.dart';

mixin RepositoryParser {
  /// Return an list of element of type `T` or null if [gqlResult] or its [gqlResult.data]
  /// is null. Will return an empty array if raw data is empty.
  ///
  /// Model is parsed using the provided [modelBuilder].
  List<T> parseMultiple<T>(GQLResult? gqlResult, T Function(Json data) modelBuilder) {
    if (gqlResult?.data != null && (gqlResult!.data as List).isNotEmpty) {
      return (gqlResult.data as List<dynamic>).map((e) => modelBuilder(e)).toList();
    }

    return [];
  }

  /// Return an element of type `T` or null if [gqlResult] or its [gqlResult.data]
  /// is null.
  ///
  /// Model is parsed using the provided [modelBuilder].
  T? parseOne<T>(GQLResult? gqlResult, T Function(Json data) modelBuilder) {
    if (gqlResult?.data != null) {
      return modelBuilder(gqlResult!.data);
    }

    return null;
  }
}
