class Configuration {
  final String graphqlEndpoint;
  final String? basicUsername;
  final String? basicPassword;

  Configuration({
    required this.graphqlEndpoint,
    required this.basicUsername,
    required this.basicPassword,
  });
}
