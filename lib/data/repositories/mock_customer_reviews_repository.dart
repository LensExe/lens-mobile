import '../../domain/models/customer_review_model.dart';
import '../../features/customer/discovery/repositories/photographer_repository.dart';

String _dateFromNow(int days) {
  final date = DateTime.now().add(Duration(days: days));
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

abstract class CustomerReviewsRepository {
  Future<List<SubmittedCustomerReview>> getMyReviews();
  Future<SubmittedCustomerReview> submitReview({
    required String bookingId,
    required String photographerId,
    required String photographerName,
    required String photographerAvatar,
    required String style,
    required String date,
    required double rating,
    required String comment,
  });
}

class MockCustomerReviewsRepository implements CustomerReviewsRepository {
  MockCustomerReviewsRepository({
    required this.accountId,
    required this.photographers,
    bool demo = false,
  }) {
    _byAccount.putIfAbsent(accountId, () => demo ? _demoReviews() : []);
  }

  final String accountId;
  final PhotographerRepository photographers;
  static final Map<String, List<SubmittedCustomerReview>> _byAccount = {};
  List<SubmittedCustomerReview> get _reviews => _byAccount[accountId]!;

  static List<SubmittedCustomerReview> _demoReviews() => [
    SubmittedCustomerReview(
      bookingId: 'bk-84610',
      photographerId: 'p5',
      photographerName: 'Tuấn Đạt',
      photographerAvatar: 'https://i.pravatar.cc/150?u=tuandat',
      style: 'Ẩm thực & Nhà hàng',
      date: _dateFromNow(-18),
      rating: 5.0,
      comment: 'Nhiếp ảnh gia làm việc đúng giờ, ảnh món ăn sắc nét và màu sắc tự nhiên. Tôi rất hài lòng với buổi chụp.',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  @override
  Future<List<SubmittedCustomerReview>> getMyReviews() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_reviews);
  }

  @override
  Future<SubmittedCustomerReview> submitReview({
    required String bookingId,
    required String photographerId,
    required String photographerName,
    required String photographerAvatar,
    required String style,
    required String date,
    required double rating,
    required String comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final trimmed = comment.trim();
    if (rating < 1 ||
        rating > 5 ||
        trimmed.length < 10 ||
        trimmed.length > 500) {
      throw StateError(
        'Đánh giá phải có 1–5 sao và nhận xét từ 10 đến 500 ký tự.',
      );
    }
    if (_reviews.any((review) => review.bookingId == bookingId)) {
      throw StateError('Lịch chụp này đã được đánh giá.');
    }
    final newReview = SubmittedCustomerReview(
      bookingId: bookingId,
      photographerId: photographerId,
      photographerName: photographerName,
      photographerAvatar: photographerAvatar,
      style: style,
      date: date,
      rating: rating,
      comment: trimmed,
      createdAt: DateTime.now(),
    );
    await photographers.recordReview(photographerId, rating);
    _reviews.insert(0, newReview);
    return newReview;
  }
}
