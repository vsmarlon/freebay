class WalletModel {
  final int availableBalance; // centavos
  final int pendingBalance; // centavos
  final int balance; // centavos

  const WalletModel({
    required this.availableBalance,
    required this.pendingBalance,
    required this.balance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final availableBalance = (json['availableBalance'] as num?)?.toInt() ?? 0;
    final pendingBalance = (json['pendingBalance'] as num?)?.toInt() ?? 0;
    return WalletModel(
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
