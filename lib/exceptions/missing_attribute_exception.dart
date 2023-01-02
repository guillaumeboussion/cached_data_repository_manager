class MissingAttributeException implements Exception {
  final String attribute;
  final Type model;

  MissingAttributeException(this.attribute, this.model);
}
