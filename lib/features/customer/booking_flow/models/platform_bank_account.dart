/// Dữ liệu tài khoản ngân hàng của sàn Lens để hiển thị ở bước cọc
class PlatformBankAccount {
  static const String bank = "Vietcombank";
  static const String accountNumber = "1023 4567 89";
  static const String accountHolder = "CONG TY TNHH LENS VIET NAM";

  static String getTransferMemo(String bookingId) {
    final cleanId = bookingId.replaceAll(RegExp(r'^bk-'), '').toUpperCase();
    return "LENS $cleanId";
  }
}
