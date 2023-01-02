import 'package:cached_data_repository_manager/auth/entities/token.dart';

class BearerToken extends Token {
  String token;
  String refreshToken;
  DateTime expiresAt;

  BearerToken({required this.token, required this.refreshToken, required this.expiresAt});

  @override
  String get toHeader => "Bearer $token";

  bool get isExpired => expiresAt.compareTo(DateTime.now()) < 0;

  BearerToken.fromResponseJson(Map<String, dynamic> json)
      : token = json['access_token'],
        refreshToken = json['refresh_token'],
        expiresAt = DateTime.now().add(Duration(seconds: json['expires_in'] - 60));

  @override
  BearerToken.fromJson(Map<String, dynamic> json)
      : token = json['token'],
        refreshToken = json['refreshToken'],
        expiresAt = DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] * 1000);

  @override
  Map<String, dynamic> toJson() => {
        'token': token,
        'refreshToken': refreshToken,
        'expiresAt': (expiresAt.millisecondsSinceEpoch / 1000).round(),
      };

  @override
  bool operator ==(Object other) => other is BearerToken && other.token == token && other.refreshToken == refreshToken && other.expiresAt == expiresAt && other.hashCode == hashCode;

  @override
  int get hashCode => Object.hash(token, refreshToken, expiresAt);
}