class GQLResult {
  /// Data returned either from the database or cache as raw data
  Map<String, dynamic>? _rawData;

  /// Getter to allow mutation on property use
  Map<String, dynamic>? get rawData => _rawData != null ? Map.of(_rawData!) : null;

  /// Data from the given [documentName]
  dynamic data;

  /// Potential exceptions being throw by GraphQL client on a remote query
  Exception? exception;

  /// Synchronization datetime, null if returned directly from the server
  DateTime? _syncAt;
  DateTime? get syncAt => _syncAt;

  /// If the record has been retrieved from the internal cache
  late bool fromCache;

  GQLResult.fromException(this.exception) {
    fromCache = false;
  }

  GQLResult(Map<String, dynamic> rawData, String documentName, {DateTime? syncAt, this.fromCache = false})
      : _rawData = rawData,
        data = rawData[documentName],
        _syncAt = syncAt;
}
