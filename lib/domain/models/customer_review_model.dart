class SubmittedCustomerReview {
  final String bookingId;
  final String photographerId;
  final String photographerName;
  final String photographerAvatar;
  final String style;
  final String date;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const SubmittedCustomerReview({
    required this.bookingId,
    required this.photographerId,
    required this.photographerName,
    required this.photographerAvatar,
    required this.style,
    required this.date,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}
