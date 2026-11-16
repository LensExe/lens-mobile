# 01 — Source audit

Ngày audit: 2026-10-24. Phạm vi: Customer flow của `Lens-web`, các API/controller nghiệp vụ liên quan trong `lens-be`, và implementation Flutter trong `Lens-mobile`. Chỉ `Lens-mobile` được chỉnh sửa trong lượt này.

## Lens-web — feature và hành vi tham chiếu

`apps/portal/src/App.tsx` là route inventory chính:

- Public: `/login`, `/signup`, `/auth/google/callback`, photographer browse `/`, detail `/photographers/:photographer_id` và booking `/photographers/:photographer_id/book` (yêu cầu role `client`).
- Customer workspace: `/client`, `/client/bookings`, `/client/bookings/:booking_id`, `/deposit`, `/pay`, `/gallery`, `/client/reviews`.
- Shared authenticated routes: `/messages`, `/wallet`, `/settings/profile`, `/settings/account`, `/settings/notifications`.

Photographer directory tại `/` tải danh sách rồi lọc/sắp xếp/phân trang ở client. Bộ lọc gồm nhiều style (OR), city, giá, ngày, rating, kinh nghiệm và sort. `mapPhotographerSummary` trả `availableDates: []`, nên bộ lọc ngày hiện luôn rỗng; Web có defect hành vi này. Web style catalog còn có “Ẩm thực” và “Kiến trúc” nhưng Backend photography-style vocabulary hiện không có code tương ứng.

Các route trên được truy tiếp qua route components trong `apps/portal/src/routes/customer/`, `routes/shared/settings/`, queries trong `apps/portal/src/queries/` và service adapters trong `apps/portal/src/services/`. Ví dụ: `BookingFlow.tsx` → `useCreateBooking` (`queries/useBookings.ts`) → `services/bookings.ts` → `services/backend/bookings.ts` → `POST /bookings`. Booking detail và cancellation dùng query/mutation hook; dialog hủy tải `GET /bookings/:id/cancellation-preview` trước khi gọi hủy. Payment/Deposit polling payment status/QR và chỉ coi khoản tiền đã thanh toán khi trạng thái Backend xác nhận. Reviews dùng `useReviews` và service reviews để tải lịch sử/gửi nhận xét. Profile/settings dùng `useProfile`; notifications và messages dùng queries riêng, trong đó messages/notifications kết nối service tách biệt.

## lens-be — contract và business rules

Đã truy controller, DTO và response interceptor, không chỉ dựa vào Swagger:

- Auth/session: `features/api/http/auth.controller.ts`, `google-auth.controller.ts`, `dto/auth.dto.ts`, `dto/google-auth.dto.ts`; register/login/refresh/logout, password change/reset và email verification đều có contract cụ thể. Google OAuth trả authorization URL và dùng callback URI cấu hình ở Backend.
- Profile: `user.controller.ts`, `customer.controller.ts`, `dto/identity.dto.ts`, `dto/customer.dto.ts`. `/users/me` quản lý fullname/avatar/phone/gender/dob/notification preferences; `/customers/me` quản lý description/preferred styles/location. DTO không có địa chỉ chi tiết hay địa chỉ mặc định.
- Discovery/detail: `photographer.controller.ts`, `booking-plan.controller.ts`, `portfolio.controller.ts`, `calendar.controller.ts`, `feedback.controller.ts`; browse/top-rated, profile, booking plans, portfolios, availability và review summary/list. `GET photographers` có keyword/location/min-rating và pagination, không có dedicated multi-style/price/experience/sort hay aggregate availability filter.
- Booking: `booking.controller.ts`, `dto/booking.dto.ts` và booking domain/use cases. Customer tạo booking bằng photographer, booking plan, địa điểm và khoảng `from`/`to`; Backend quyết định state/eligibility. Có cancellation preview, cancellation, timeline, confirm receipt và các transition khác có giới hạn role/state.
- Payment: `payments.controller.ts`, `dto/payment.dto.ts`, payment/wallet use cases. Deposit/remaining là payment intents; status/history/QR lấy từ Backend/provider; wallet, ledger và `POST wallet/withdrawals` là các endpoint riêng. Withdrawal yêu cầu amount, reason, payout destination và idempotency key; request chờ admin xử lý. Không có thao tác Lens Xu trong contract booking của Mobile.
- Gallery/media: `media.controller.ts`, `dto/media.dto.ts`; signed upload URL, complete upload, media status, gallery và download URL có kiểm soát booking/role.
- Reviews: `feedback.controller.ts`, `dto/review.dto.ts`; booking review, danh sách review của customer, rating summary và photographer review. Customer list endpoint tồn tại; UI Web hiện dùng submit/history, không đưa review reply/admin vào phạm vi Customer.

`shared/common/interceptors/transform-response.interceptor.ts` bọc kết quả thành `{success, statusCode, data, timestamp}`. Các lỗi nghiệp vụ vẫn là HTTP errors với code/message qua exception filters.

## Lens-mobile — architecture và trạng thái đầu vào

- Điều hướng dùng GoRouter trong `lib/core/router/app_router.dart`; state dùng Riverpod; Dio client/config/interceptors ở `lib/core/network/` và providers ở `lib/providers/`.
- Access/refresh token nằm trong `AuthSessionStore`; `SessionInterceptor` đồng bộ refresh, chỉ retry GET sau refresh và không replay write. Các production providers hiện inject API repositories. `mock_*` còn lại dành cho tests/demo, không phải provider production mặc định.
- Có sẵn màn hình Customer cho auth, browse/detail/booking, booking list/detail, deposit/payment, gallery, reviews, wallet, settings, notifications và chat.
- Trước lượt sửa này, login/refresh/wallet/recommendations/discovery chưa xử lý đầy đủ response envelope. Lịch sử review rỗng ở mọi lần khởi tạo; notification settings báo Backend chưa hỗ trợ dù DTO có trường; profile chưa có luồng upload avatar; dialog hủy không tải cancellation preview; hồ sơ chưa đọc/sửa gender và ngày sinh; wallet chưa có withdrawal flow. Discovery chưa có multi-style, price, experience và sort parity.

## Giới hạn đã xác minh

- Google code exchange có API nhưng không có mobile callback/deep-link handoff; Backend dùng một frontend redirect URI cố định. Mobile không thể tự hoàn tất OAuth end-to-end bằng contract hiện tại.
- Backend không có API cho địa chỉ chi tiết/default address và quản lý/thu hồi từng session.
- Web date filter không hoạt động vì directory mapper luôn trả danh sách ngày rảnh rỗng; Backend chỉ có availability theo từng photographer, chưa có aggregate filter theo ngày. Không thực hiện N+1 request để giả lập bộ lọc directory.
- Notifications và chat cần `NOTIFICATION_API_URL`/`CHAT_API_URL` tương ứng; đây không phải luồng REST Customer trong API chính để xác minh bằng test server hiện có.
- Không có test account/staging credentials trong môi trường. Không thực hiện E2E hoặc giao dịch tài chính với hệ thống thật.
- Working tree của cả ba repository đã có thay đổi trước khi bắt đầu. Các thay đổi đó được giữ nguyên; Web và Backend không được sửa.
