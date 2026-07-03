class WalletEntity {
  final int availableBalance; // centavos
  final int pendingBalance; // centavos
  final int balance; // centavos

  const WalletEntity({
    required this.availableBalance,
    required this.pendingBalance,
    required this.balance,
  });

  factory WalletEntity.fromJson(Map<String, dynamic> json) {
    final availableBalance = (json['availableBalance'] as num?)?.toInt() ?? 0;
    final pendingBalance = (json['pendingBalance'] as num?)?.toInt() ?? 0;
    return WalletEntity(
      availableBalance: availableBalance,
      pendingBalance: pendingBalance,
      balance: (json['balance'] as num?)?.toInt() ??
          availableBalance + pendingBalance,
    );
  }

  double get availableReal => availableBalance / 100;
  double get pendingReal => pendingBalance / 100;
  double get balanceReal => balance / 100;
}
