enum PaymentMethod { bank, card, momo }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.bank => 'Chuyển khoản ngân hàng',
    PaymentMethod.card => 'Thẻ tín dụng / ghi nợ',
    PaymentMethod.momo => 'Ví MoMo',
  };

  String get hint => switch (this) {
    PaymentMethod.bank => 'Quét mã QR hoặc chuyển khoản thủ công',
    PaymentMethod.card => 'Visa, Mastercard, JCB',
    PaymentMethod.momo => 'Thanh toán qua ứng dụng MoMo',
  };
}
