/// Пользователь в доменном слое (без привязки к Firebase).
class AuthUser {
  const AuthUser({required this.id, this.email});

  final String id;
  final String? email;
}
