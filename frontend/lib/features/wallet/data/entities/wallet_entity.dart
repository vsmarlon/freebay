import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_entity.freezed.dart';
part 'wallet_entity.g.dart';

@freezed
abstract class WalletEntity with _$WalletEntity {
  const WalletEntity._();

  const factory WalletEntity({
    @Default(0) int availableBalance,
    @Default(0) int pendingBalance,
    int? balance,
  }) = _WalletEntity;

  factory WalletEntity.fromJson(Map<String, dynamic> json) =>
      _$WalletEntityFromJson(json);

  int get totalBalance => balance ?? (availableBalance + pendingBalance);

  double get availableReal => availableBalance / 100;
  double get pendingReal => pendingBalance / 100;
  double get balanceReal => totalBalance / 100;
}
