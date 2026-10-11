enum PaymentMethod { bank, wallet }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.bank => 'Cổng thanh toán',
    PaymentMethod.wallet => 'Ví LENS',
  };

  String get hint => switch (this) {
    PaymentMethod.bank => 'Thanh toán qua cổng Backend cấu hình',
    PaymentMethod.wallet => 'Backend xác định số dư ví VND',
  };

  String get backendMethod =>
      this == PaymentMethod.wallet ? 'wallet' : 'gateway';
}
