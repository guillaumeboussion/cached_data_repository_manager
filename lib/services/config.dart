import 'package:cached_data_repository_manager/config/entities/configuration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final configurationProvider = Provider((ref) => ConfigurationProvider());

class ConfigurationProvider {
  Configuration? _config;

  Configuration? get config {
    if (config == null) {
      throw UnimplementedError('Configuration has not been set');
    }

    return _config;
  }

  ConfigurationProvider();

  void init({required Configuration config}) {
    _config = config;
  }
}
