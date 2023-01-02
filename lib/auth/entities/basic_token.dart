import 'dart:convert';

import 'package:cached_data_repository_manager/auth/entities/token.dart';

class BasicToken extends Token {
  final String username;
  final String password;

  BasicToken(this.username, this.password);

  @override
  String get toHeader {
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode("$username:$password");

    return "Basic $encoded";
  }

  @override
  Map<String, dynamic> toJson() => {'usernmae': username, 'password': password, 'tokenForHeader': toHeader};
}
