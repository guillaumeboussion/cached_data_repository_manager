import 'package:cached_data_repository_manager/utils/typedefs.dart';

class UnauthorizedException implements Exception {
  UnauthorizedException(Json? response);
}