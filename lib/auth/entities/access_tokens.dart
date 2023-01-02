import 'package:cached_data_repository_manager/auth/entities/basic_token.dart';
import 'package:cached_data_repository_manager/auth/entities/bearer_token.dart';
import 'package:cached_data_repository_manager/services/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accessTokensProvider = StateProvider((ref) => AccessTokens(ref: ref));

class AccessTokens {
  late final Ref _ref;

  late BasicToken guestToken;
  final BearerToken? userToken;

  AccessTokens({required Ref ref, BasicToken? guest, this.userToken}) {
    _ref = ref;
    guestToken = guest ?? BasicToken(_ref.read(configurationProvider).config!.basicUsername!, _ref.read(configurationProvider).config!.basicPassword!);
  }

  AccessTokens copyWith({BearerToken? bearerToken}) {
    return AccessTokens(ref: _ref, userToken: bearerToken);
  }

  Map<String, dynamic> toJson() {
    return {
      'guest-token': guestToken.toJson(),
      'user-token': userToken?.toJson(),
    };
  }
}
