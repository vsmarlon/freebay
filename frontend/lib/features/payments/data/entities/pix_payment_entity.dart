class PixPaymentEntity {
  final String orderId;
  final String pixQrCode;
  final String pixImage;
  final DateTime expiresAt;

  const PixPaymentEntity({
    required this.orderId,
    required this.pixQrCode,
    required this.pixImage,
    required this.expiresAt,
  });

  factory PixPaymentEntity.fromJson(Map<String, dynamic> json) {
    return PixPaymentEntity(
      orderId: json['orderId'] as String,
      pixQrCode: json['pixQrCode'] as String? ?? '',
      pixImage: json['pixImage'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
