class WalletModel {
  final String id;
  final String userId;
  final int availableBalance; // centavos
  final int pendingBalance; // centavos
  final int totalEarned; // centavos
  final String? recipientId;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarned,
    this.recipientId,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      availableBalance: json['availableBalance'] as int,
      pendingBalance: json['pendingBalance'] as int,
      totalEarned: json['totalEarned'] as int,
      recipientId: json['recipientId'] as String?,
    );
  }

  double get availableReal => availableBalance / 100;
  double get pendingReal => pendingBalance / 100;
  double get totalEarnedReal => totalEarned / 100;
}
