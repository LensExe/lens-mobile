# 07 — Final verification

Ngày: 2026-10-24. Đây là vòng đối chiếu độc lập sau implementation; trạng thái ghi theo source và kiểm thử thực tế.

## Route → Mobile screen

Đã đọc lại Customer/shared route list trong `Lens-web/apps/portal/src/App.tsx` và so với GoRouter routes. Customer destinations có test điều hướng/render trong `test/customer_flows_test.dart`: login/signup, home, discovery, photographer detail/booking, booking list/detail/gallery/deposit/payment, reviews, wallet, profile/account/notifications, messages/conversation. Test resize discovery trên 320, 390 và 430 px không ghi nhận layout exception.

## Web service → API → Mobile repository

- Auth/profile/discovery/detail/booking/payment/gallery/review/wallet endpoint mappings nằm trong `03-api-integration-map.md`.
- Contract controllers/DTO được kiểm tra trực tiếp; response envelope là hợp đồng chung Backend.
- Production Riverpod providers dùng API repositories. Các `mock_*` còn lại phục vụ tests/previews và không thay thế API provider mặc định.
- Inbox/realtime notification và chat phụ thuộc URL service riêng, do đó không được đánh dấu live-verified.

## Business state, actions và scan

- Booking creation/cancellation/payment/review UI dùng action phù hợp API; cancellation preview lấy estimate từ Backend. Payment success chỉ được xác nhận sau khi status endpoint cho trạng thái settled. Wallet withdrawal gửi DTO/idempotency key theo Web/Backend và không xác nhận payout trước admin.
- Discovery map `starting_price`/`starting_plan` và style codes sang nhãn Web; lọc multi-style OR, city/rating/search/price/experience/sort rồi pagination. URL có thể khôi phục criteria. Viewport 320 px dùng sort icon rút gọn và route rendering test không còn overflow.
- Scan source: không có `TODO`/`FIXME`/`UnimplementedError` trong production Customer flows. `UnimplementedError` còn lại chỉ ở test doubles của signup; no-op buttons nằm trong `LandingScreen` chưa được route và `/gallery` component showcase “Awesomic UI Gallery”, không phải Customer delivery gallery. Không có no-op action trong các route Customer đã đối chiếu.
- Không phát hiện thêm mock response trong production feature providers thay thế API có sẵn. Fixture/mock repositories chỉ nằm trong test/demo code.
- Các lỗi/giới hạn được cố ý giữ tường minh: Google callback, detailed/default address, per-session revoke, date availability (Web mapper hiện để trống và Backend chưa có aggregate filter), Web style options “Ẩm thực”/“Kiến trúc” không có BE code tương ứng; legacy `payRemaining` với Lens Xu bị từ chối vì Backend không hỗ trợ Lens Xu. Giao diện thanh toán thực dùng payment-intent API.

## Kết quả cuối

- `flutter analyze`: pass, không có issue.
- `flutter test`: pass, 50 tests.
- Các API integration assertions là fake-adapter tests, không phải real Backend E2E.
- Readiness: Customer Mobile có thể tiếp tục staging integration cho các contract hiện hữu. Chưa đạt tiêu chí “toàn bộ Customer feature E2E verified” vì OAuth handoff/API gaps và môi trường test thật chưa sẵn sàng. Việc tiếp theo: Backend cung cấp mobile OAuth redirect; quyết định/bổ sung address, session-management và aggregate availability APIs nếu cần parity; đồng bộ style catalog; cấu hình staging credentials cùng notification/chat services rồi chạy smoke/E2E, không dùng production transactions.
