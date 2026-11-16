class CustomerBookingReport {
  const CustomerBookingReport({
    required this.id,
    required this.bookingId,
    required this.issueType,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.resolution,
  });

  final String id;
  final String bookingId;
  final String? issueType;
  final String reason;
  final String status;
  final DateTime? createdAt;
  final String? resolution;
}
