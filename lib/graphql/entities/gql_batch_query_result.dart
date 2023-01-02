import 'dart:developer';

import 'package:cached_data_repository_manager/exceptions/document_name_not_found.dart';

class GraphQlBatchQueryResult {
  List<dynamic>? data;
  bool fromCache;
  DateTime lastSync;

  /// Possible errors catched during request
  Exception? exception;

  bool get hasException => exception != null;

  /// Return a dynamic element (Map or List) of one of the batch query result.
  ///
  /// Throws a [DocumentNameNotFoundException] if the document name couldn't be
  /// resolved in the current [data].
  Object? dataForDocumentName(String documentName, {bool paginated = false}) {
    if (data != null && data!.isNotEmpty) {
      for (Map<String, dynamic> element in data!) {
        if (element.keys.contains("errors")) {
          // Send error to server
          log('[GraphQL BatchQuery] : failed while querying $documentName');
        } else if (element['data'].keys.contains(documentName)) {
          return paginated ? element['data'][documentName]['data'] : element['data'][documentName];
        }
      }
      throw DocumentNameNotFoundException(documentName);
    }
    return null;
  }

  T parseModel<T>(String documentName, T Function(Map<String, dynamic> data) modelFn) {
    Map<String, dynamic> data = dataForDocumentName(documentName) as Map<String, dynamic>;

    return modelFn(data);
  }

  /// Returns a list of `T` elements from the raw query result.
  ///
  /// Models are built from the [modelFn] parameter, assuming the given
  /// [documentName] exists in the query result.
  ///
  /// Case `GraphQL` result is returned paginated, it is mandatory to provide
  /// the [paginated] parameter as true.
  List<T> parseModels<T>(
    String documentName,
    T Function(Map<String, dynamic> data) modelFn, {
    bool paginated = false,
  }) {
    List<dynamic> data = dataForDocumentName(documentName, paginated: paginated) as List<dynamic>;
    List<T> models = [];

    for (Map<String, dynamic> element in data) {
      models.add(modelFn(element));
    }

    return models;
  }

  GraphQlBatchQueryResult(this.data, this.fromCache, this.lastSync);
}
