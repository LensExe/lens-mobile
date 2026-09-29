/// DTO gửi thông tin tạo đơn đặt lịch
class CreateBookingInput {
  final String photographerId;
  final String photographerName;
  final String style;
  final String packageId;
  final String date; // "yyyy-MM-dd"
  final String timeSlot; // "14:00"
  final String location; // "Hồ Gươm, Hà Nội"
  final String contactName;
  final String contactPhone;
  final String? note;
  final int price;

  const CreateBookingInput({
    required this.photographerId,
    required this.photographerName,
    required this.style,
    required this.packageId,
    required this.date,
    required this.timeSlot,
    required this.location,
    required this.contactName,
    required this.contactPhone,
    this.note,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'photographerId': photographerId,
    'photographerName': photographerName,
    'style': style,
    'packageId': packageId,
    'date': date,
    'timeSlot': timeSlot,
    'location': location,
    'contactName': contactName,
    'contactPhone': contactPhone,
    'note': note,
    'price': price,
  };
}
