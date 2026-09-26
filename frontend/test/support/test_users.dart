import 'package:freebay/features/auth/data/entities/user_entity.dart';

UserEntity testUser({
  required String id,
  String? displayName,
  String? username,
  String? email,
}) => UserEntity(
  id: id,
  displayName: displayName,
  username: username,
  email: email,
);
