class DocumentNameNotFoundException implements Exception {
  final String documentName;

  DocumentNameNotFoundException(this.documentName);

  @override
  String toString() {
    return "GraphQL document name $documentName not found in batch query response";
  }
}
