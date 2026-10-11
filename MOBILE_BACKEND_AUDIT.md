# Báo cáo audit Mobile ↔ Backend LENS

Ngày audit: 2026-10-10
Phạm vi: `Lens-mobile` (Customer), `lens-creator-mobile` (Photographer/Creator), `lens-be`.
Loại công việc: audit source và tạo báo cáo; không triển khai tính năng.

## 1. Executive Summary

- Cả hai ứng dụng đã nối luồng đăng nhập/đăng ký/đăng xuất với API auth ở mức source. Creator còn gửi hồ sơ đăng ký photographer và kiểm tra `verification_status`. Không có bằng chứng gọi Backend deploy trong lượt audit này.
- Trong 28 flow-level feature rows được kiểm kê (14 Customer, 14 Creator), có **2 `API_INTEGRATED`**, **2 `PARTIALLY_INTEGRATED`**, **1 `UI_ONLY`**, **23 `MOCK_ONLY`**, **0 `VERIFIED_LIVE`**. Đây là số flow/domain, không phải số màn hình hay endpoint.
- Các nghiệp vụ đã có API Backend nhưng Mobile vẫn dùng mock gồm discovery/profile, plans, booking, calendar, portfolio/media, reviews, payments/wallet, subscriptions, ranks/badges. Messaging có checkout/service riêng được tham chiếu trong cấu hình, nhưng source của service đó không nằm trong `lens-be`, nên contract chat là `UNVERIFIED`.
- Các mismatch đáng xử lý trước khi thay mock: bộ lọc discovery vượt contract tìm kiếm hiện tại; UI booking dùng trạng thái riêng và payload chưa khớp `POST /bookings`; weekly schedule và collaboration/split-share của Creator chưa có contract đầy đủ; field gói chụp có `deliveryDays` trong Mobile nhưng không có trong DTO Backend.
- Chưa xác định được Backend origin deploy. Mobile yêu cầu `API_BASE_URL` lúc build/runtime; cấu hình Caddy chỉ có default `api-direct.localhost`, còn Swagger chỉ công bố server khi có `API_PUBLIC_URL`. Không gọi endpoint thật, không dùng credentials, không thử payment.
- Giữ nguyên toàn bộ working-tree changes đã có ở hai ứng dụng. Chỉ tạo file báo cáo này; không sửa source, Backend, Git state hoặc môi trường deploy.

## 2. Phạm vi và phương pháp audit

### Phạm vi đã kiểm tra

- Kiểm kê route, feature screen, widget, model, provider và repository trong `lib/features`, `lib/core/router`, `lib/providers`, `lib/data`, `lib/domain` của cả hai Flutter app.
- Đọc các flow đại diện và wiring thực tế của auth/session, profile/settings, discovery/detail, booking, availability, portfolio/media, reviews, messages, wallet/payment, subscriptions/storage, achievements và assistant. Trạng thái được lấy từ provider/repository được screen sử dụng, không suy ra từ tên file `Api...`.
- Kiểm kê toàn bộ HTTP controller dưới `lens-be/src/features/api/http`; đối chiếu các DTO, response schema, use case/domain liên quan cho các capability chính. Kiểm tra thêm auth setup, API bootstrap/config, notification integration và tham chiếu Chat service trong deployment docs.
- `lens-web` sạch và không cần dùng để suy luận contract; không dùng feature Web làm bằng chứng API.

### Giới hạn và cách đọc trạng thái

- `AVAILABLE` nghĩa là route và business implementation có trong source Backend, không xác nhận đã chạy trên môi trường deploy.
- `API_INTEGRATED` nghĩa là Mobile có request, mapping và state flow tương ứng trong source; **không** có nghĩa đã xác minh live.
- `VERIFIED_LIVE` chỉ dùng khi có kết quả gọi đúng môi trường thật. Audit này không có origin deploy hoặc credentials phù hợp, nên số lượng là 0.
- Với Backend capability không thấy trong `lens-be`, báo cáo chỉ kết luận trong phạm vi repo đã kiểm tra. Nếu deployment trỏ tới service checkout khác, trạng thái là `UNVERIFIED`, không kết luận toàn hệ thống chắc chắn thiếu.
- Không chạy test, analyzer hoặc build trong lượt audit chỉ đọc này. Lượt audit ghi nhận các file test hiện có nhưng không coi test/build cũ hoặc test source là bằng chứng live.

### Origin và xác minh môi trường

- Hai app lấy URL từ `String.fromEnvironment('API_BASE_URL')`, không có production URL mặc định: `Lens-mobile/lib/core/network/api_config.dart:5-25`, `lens-creator-mobile/lib/core/network/api_config.dart`.
- `lens-be/src/features/api/setup.ts:38-40` chỉ thêm Swagger server khi có `API_PUBLIC_URL`. `lens-be/deploy/portainer/lens-caddy.yml:14-20,45-47` dùng domain cấu hình môi trường và default `api-direct.localhost`; đó là placeholder/local default, không phải origin deploy xác định.
- Không thấy URL deploy thật được cung cấp trong task hoặc cấu hình đọc được mà không truy cập secret. Không gọi GET an toàn vì thiếu host hợp lệ; không kiểm tra secrets hay giải mã `.enc`.

## 3. Mobile có nhưng Backend chưa hỗ trợ đủ

“Thiếu” dưới đây là thiếu trong contract của `lens-be`; messaging/assistant được đánh dấu riêng vì service Chat nằm ngoài checkout.

| ID | App/Role | Feature/Flow | Mobile fields/actions | Backend hiện hỗ trợ | Khoảng thiếu / không tương thích | Bằng chứng source | Đề xuất |
|---|---|---|---|---|---|---|---|
| G1 | Customer | Discovery/search/filter/sort | Search tên/khu vực/style; lọc giá thấp/cao, ngày rảnh, rating, kinh nghiệm; sort nổi bật/rating/giá/review. | `GET /photographers` nhận `limit`, `offset`, `location`, `keyword`, `min_rating`; `GET /photographers/top-rated`; `GET /customers/me/recommendations` dựa trên preference/location đã lưu. | DTO search không nhận style, price range, available date, experience, sort. Recommendation dùng customer preferences, không thay được bộ lọc tự do UI. Backend `photographer` response không có cover hoặc giá. Đây là contract **partial**, không phải lý do để tự đoán dữ liệu/filter. | `Lens-mobile/lib/features/customer/discovery/models/filter_criteria.dart:5-24`; `.../controllers/discovery_controller.dart:127-170`; `.../repositories/discovery_repository_provider.dart:6-8`; `lens-be/src/features/api/http/photographer.controller.ts:475-588`; `.../dto/photographer.dto.ts:217-269`; `lens-be/src/features/api/http/customer.controller.ts:251`. | Trước tiên chốt filter nào là nghiệp vụ bắt buộc; tích hợp các field API hiện có. Chỉ bổ sung query/backend khi có yêu cầu thực sự cho style/price/date/experience/sort. Không đặt giá, cover hoặc availability giả. |
| G2 | Customer | Photographer detail | UI hiển thị cover, giá khởi điểm, gear/studio/insurance, kinh nghiệm, packages, portfolio, reviews, delivery days. | `GET /photographers/:photographer_id` trả profile cơ bản; plans, portfolios, reviews và availability có endpoint riêng. | Contract profile có fullname/avatar/styles/start year/verified/location/availability/description/rating/rank/badges; không thấy `coverImageUrl`, insurance/gear fields, start price hoặc package delivery days trong public profile schema. Có thể lấy nhiều resource riêng, nhưng một số UI field không có nguồn Backend đã xác định. | `Lens-mobile/lib/features/customer/photographer_detail/models/photographer_detail_model.dart:1-157`; mock source `.../repositories/mock_photographer_detail_repository.dart`; `lens-be/src/features/api/swagger/responses.ts:125-144`; controllers `photographer.controller.ts:598`, `booking-plan.controller.ts:259`, `portfolio.controller.ts:216`, `feedback.controller.ts:164`. | Map profile + plans + portfolio + reviews từ API có sẵn. Team cần quyết định bỏ/ẩn hay bổ sung contract cho cover, gear, insurance và delivery estimate. |
| G3 | Customer | Tạo booking | Wizard thu `photographerId`, `packageId`, `date`, `timeSlot`, `location`, contact name/phone, note, price; kiểm tra slot trước submit. | `POST /bookings` yêu cầu `photographer_id`, UUID `booking_plan_id`, `location`, `from`, `to` dạng ISO-8601 có timezone. Availability public có `from/to`. | Wizard chưa gửi API. Request không truyền plan duration/time range; các trường contact/name/phone/note/price của Mobile không có trong `BookingCreateCommandBodyDto`; chưa có map rõ package mock ID → Backend plan UUID. Cần thống nhất trường nào là snapshot/đọc từ customer profile và `to` tính từ duration thực. | `Lens-mobile/lib/features/customer/booking_flow/models/create_booking_input.dart:1-41`; `.../controllers/booking_wizard_controller.dart:69-131`; `lens-be/src/features/api/http/booking.controller.ts:125-168`; `lens-be/src/features/api/dto/booking.dto.ts:54-94`. | Nối bằng Backend plan UUID và khoảng thời gian timezone-aware; thống nhất contact/note snapshot trước code. Không tự dựng `to` nếu package duration chưa được API load. |
| G4 | Customer + Creator | Booking state | Customer dùng `awaiting_deposit`, `pending`, `confirmed`, `held`, `released`, `cancelled`; Creator có enum tương tự và collaboration states. | Backend `BookingStatus`: `pending`, `accepted`, `rejected`, `cancelled`, `expired`, `in_progress`, `shot`, `completed`. Payment/deposit là payment endpoints/state ngoài enum booking. | Không có adapter/mapping hiện dùng vì toàn bộ booking đang mock. Không map `confirmed→accepted`, `released→completed` hoặc `awaiting_deposit→pending` nếu chưa thống nhất UI flow; Backend còn các trạng thái Creator/Customer chưa biểu diễn. | `Lens-mobile/lib/features/customer/bookings/models/booking_model.dart:3-10`; `lens-creator-mobile/lib/domain/models/models.dart:86-95`; `lens-be/src/shared/domain/values/booking.values.ts:1-27`; booking routes tại `booking.controller.ts:248-658`. | Thiết lập bảng enum/state machine chung, xử lý payment state riêng, sau đó viết mapping và UI action theo role. |
| G5 | Creator | Lịch tuần / availability | Creator chỉnh lịch lặp theo 7 ngày, nửa giờ, và ngày bận; Save hiện ghi vào `MockAvailabilityRepository`. | Backend có `GET /photographers/:id/availability`, `GET /calendar/me`, `POST/DELETE /calendar/blocked-times`, offline-slot queries. | Có thể đọc khoảng trống/chặn khoảng bận theo ngày; chưa thấy endpoint lưu cấu hình recurring weekly hours tương ứng `WorkSchedule.weekly`. Contract hiện có không đủ để persist nguyên trạng editor tuần. | `lens-creator-mobile/lib/features/photographer/availability/work_schedule.dart:3-35`; `.../schedule_provider.dart:8-25`; `.../mock_availability_repository.dart:4-24`; `lens-be/src/features/api/http/calendar.controller.ts:55-105,151-260`. | Nếu recurring schedule là requirement, thống nhất timezone, ngày trong tuần, hiệu lực và rule khi trùng booking rồi bổ sung contract; nếu không, đổi Mobile sang quản lý date ranges/block-time hiện có. |
| G6 | Creator | Packages | Editor quản lý giá, thời lượng, ảnh, deliverables và `deliveryDays`; provider hiện cập nhật profile mock. | CRUD `/photographers/me/booking-plans`, public GET plans. Create DTO có `name`, `description`, `price`, `duration_minutes`, `photo_count`, `retouched_photo_count`, `features`; không có `deliveryDays`. | Phần CRUD cơ bản được Backend hỗ trợ nhưng Mobile chưa nối. Phải map duration/ảnh/retouch/features; delivery estimate không có field, và trạng thái package của Mobile chưa ánh xạ `is_active`. | `lens-creator-mobile/lib/features/photographer/packages/edit_package_screen.dart:69-142`; `lens-creator-mobile/lib/providers/data_providers.dart:26-32`; `lens-be/src/features/api/http/booking-plan.controller.ts:57-206,259`; `lens-be/src/features/api/dto/booking-plan.dto.ts:15-81,84-146`. | Nối các trường tương thích trước; quyết định bỏ `deliveryDays` hoặc thêm field nếu hợp đồng nghiệp vụ cần. |
| G7 | Creator | Collaboration trong booking | Mời creator khác, chia `sharePct`, accept/decline invitation (`invited \| accepted \| declined`). | API booking mô tả một photographer chịu trách nhiệm; routes expose accept/reject/cancel/start/complete/dispute, không thấy collaborator invite/respond hoặc revenue-split route/model trong `lens-be`. | Flow nhiều photographer và chia tiền hiện không có contract trong Backend đã audit. Đây là gap backend rõ ràng nếu collaboration là requirement sản phẩm. | `lens-creator-mobile/lib/domain/models/models.dart:95-107`; `lens-creator-mobile/lib/data/repositories/booking_repository_impl.dart:27-38`; `lens-be/src/features/api/http/booking.controller.ts:125-168,248-658`; `lens-be/src/features/api/dto/booking.dto.ts`. | Chốt quy tắc owner, consent, tiền và trạng thái trước; nếu giữ flow thì thiết kế API/domain collaboration; nếu chưa cần, ẩn action hiện mock. |
| G8 | Customer + Creator | Notification preferences | Hai app có toggle booking/messages/promotions/email/SMS. Customer provider và Creator settings repository dùng mock. | `lens-be` có event/outbox/Kafka notification integration cho server-side delivery; không có HTTP API đọc/ghi preference trong danh sách controller đã kiểm tra. | Preference UI không được lưu đồng bộ với Backend. Event publisher không cung cấp API quản lý preference hay inbox. | `Lens-mobile/lib/providers/data_providers.dart:143-180`; `lens-creator-mobile/lib/features/photographer/settings/settings_provider.dart:8-39`; `lens-be/src/shared/integrations/notification/notification-outbox.publisher.ts`; controller inventory trong Appendix. | Thống nhất channel/event model và quyền opt-in; sau đó bổ sung preference endpoint hoặc bỏ toggle chưa được hỗ trợ. |
| G9 | Customer | Active sessions / 2FA | Settings hiển thị session list và revoke actions; 2FA/session controls là security UI. | Auth có logout, change password; không thấy session list/revoke hay 2FA API trong controller/DTO auth. | Customer API repository cố ý throw cho `getActiveSessions`, revoke một/all; UI không thể hoạt động thật. Không tính `403` hoặc client-side logout là revoke các token trên server. | `Lens-mobile/lib/data/repositories/api_auth_repository.dart:146-166`; `Lens-mobile/lib/providers/data_providers.dart:115-141`; `lens-be/src/features/api/http/auth.controller.ts:163-222`. | Ẩn/đánh dấu chưa hỗ trợ các action này, hoặc thống nhất Keycloak/backend session semantics rồi bổ sung API. |
| G10 | Customer | Ví Lens Xu / cashback / review reward | Wallet mock chứa coins, redeem/cashback, refund item và cộng 10.000 xu sau review. | Backend có số dư ví, ledger, top-up, withdrawal, booking payment/refund; currency/payment amount là VND. | Không thấy endpoint coin earn/redeem/cashback hoặc review reward trong payment API. Không đồng nhất `Lens Xu` với VND wallet nếu business chưa xác nhận. | `Lens-mobile/lib/data/repositories/mock_customer_wallet_repository.dart:3-26,89-207`; `Lens-mobile/lib/providers/data_providers.dart:282-310`; `lens-be/src/features/api/http/payments.controller.ts:509-688`; `lens-be/src/features/api/dto/payment.dto.ts:85-97,134-180`. | Chốt mô hình xu, tỷ lệ/quy đổi và sổ cái; chỉ map refund thực sang request refund Backend. |
| G11 | Customer + Creator | Messaging | Conversation list, unread/read, text send; Creator còn bật/tắt assistant cho cuộc trò chuyện. | Không thấy chat controller trong `lens-be`. Deployment docs tham chiếu checkout/service `../chat-service`, nằm ngoài source audit hiện có. | Contract, transport (REST/WebSocket), auth, message schema và assistant control của service riêng chưa kiểm chứng; không thể kết luận hệ thống hoàn toàn không có chat API. | `Lens-mobile/lib/data/repositories/mock_customer_messages_repository.dart`; `lens-creator-mobile/lib/data/repositories/message_repository_impl.dart`; `lens-be/.docker/README.md:47-58`; `.docker/chat-service/docker-compose.backend.yaml`. | Cần cung cấp source/OpenAPI của chat service và auth contract; sau đó nối inbox/send/read theo state hiện có. |
| G12 | Creator | Assistant/FAQ config | Screen chỉnh FAQ/rules, bật/tắt assistant; repository hiện inject mock datasource. | Không tìm thấy API assistant trong `lens-be`; chat service được cấu hình ngoài checkout. | `lens-be` không đủ bằng chứng để xác định assistant capability ngoài repo có hay không. | `lens-creator-mobile/lib/features/photographer/assistant/assistant_provider.dart`; `lens-creator-mobile/lib/data/repositories/assistant_repository_impl.dart`; `lens-creator-mobile/lib/data/datasources/mock/mock_assistant_data_source.dart`; `lens-be/.docker/README.md:47-58`. | Đánh dấu `UNVERIFIED`; đối chiếu source Chat service trước khi mở gap Backend hoặc triển khai Mobile. |

**Thống kê gap của bảng G1–G12:** 3 `MISSING` trong `lens-be` (G7–G9); 7 `PARTIAL` (G1–G6, G10); 2 `UNVERIFIED` ngoài repo (G11–G12). Các endpoint khác đã có nhưng chưa tích hợp được ghi ở Report 3, không đếm lặp thành gap backend.

## 4. Backend capabilities chưa có Mobile counterpart

`AVAILABLE` ở bảng nghĩa là contract/logic có trong `lens-be` source. Với các flow đã có UI mock, cột Mobile ghi `UI, MOCK`, không coi là đã tích hợp.

| Backend module/API | Method + endpoint | Business capability / role | Customer Mobile | Creator Mobile | Backend | Có cần Mobile hỗ trợ? |
|---|---|---|---|---|---|---|
| Auth recovery / email verify | `POST /auth/forgot-password/send-otp`, `/verify`, `/reset`, `/auth/email/send-otp`, `/verify` | Quên mật khẩu, OTP/verify; public hoặc authenticated tùy route. DTO yêu cầu email/event/OTP/reset token tương ứng. | Không thấy flow reset/OTP. | Không thấy flow reset/OTP. | `AVAILABLE` source (`auth.controller.ts:230-377`, `auth.dto.ts`). | Nên có reset flow nếu account recovery thuộc scope release; không xây API trùng contract đang có. |
| Google auth | `GET /keycloak/google/login`, `/callback`, `/exchange` | OAuth redirect/callback/exchange; không tương đương native email/password POST. | Không thấy nút/flow OAuth. | Không thấy nút/flow OAuth. | `AVAILABLE` source (`google-auth.controller.ts:29-120`). | Quyết định có hỗ trợ Google login native/deep-link; cần redirect URI/app-link trước khi làm Mobile. |
| Customer recommendations | `GET /customers/me/recommendations` | Gợi ý photographer dựa trên `preferred_styles` và location; Customer auth. | Discovery UI có nhưng lấy mock; không gọi recommendation API. | Không có consumer flow. | `AVAILABLE` source (`customer.controller.ts:251`; `customer.use-case.ts:186-211`). | Có thể cấp dữ liệu cho discovery hiện có, không cần màn hình mới; cần quyết định preference onboarding/filter behavior. |
| Reports | `POST /reports`, `GET /reports/me` | User gửi và theo dõi report; auth, không phải admin-only. | Không thấy report form/route. | Không thấy report form/route. | `AVAILABLE` source (`moderation.controller.ts:170-280`). | Thống nhất reportable objects, evidence và trải nghiệm trước; không phải blocker của booking core. |
| Reviews | `POST /bookings/:booking_id/reviews`, `GET /photographers/:id/reviews`, `GET /photographers/:id/rating-summary`, `PUT /reviews/:id/reply` | Customer tạo review; public đọc; Photographer reply. | UI review mock. | UI review/reply mock. | `AVAILABLE` source (`feedback.controller.ts:65-225,327-370`; `review.dto.ts`). | Có UI tương ứng; chỉ cần Mobile mapping và business rules (rating/comment/reply). |
| Photographer / search | `GET /photographers`, `/top-rated`, `/:photographer_id`, `/photographers/me`; `POST /photographers/profile` | Public search/profile, authenticated self/application. Search DTO giới hạn query fields. | UI discovery/profile/apply flow không dùng API. | Creator apply/login gọi self profile; creator public profile/editor mock. | `AVAILABLE` source (`photographer.controller.ts:384-625`; DTO/schema). | Nối discovery/profile; không thêm filter giả hoặc màn hình mới. |
| Booking plans | `GET /photographers/:id/booking-plans`; creator `GET/POST /photographers/me/booking-plans`, `PATCH/DELETE /booking-plans/:id` | Public package read; Photographer CRUD; required fields xem G6. | Package picker/detail mock. | Package editor mock. | `AVAILABLE` source (`booking-plan.controller.ts:57-259`). | Nối Mobile hiện hữu; reconcile field mapping trước. |
| Booking | `POST/GET /bookings`; `GET /bookings/:id`, `/timeline`; POST accept/reject/cancel/start/complete-shoot/confirm-receipt/dispute/complete | Customer create/list/receipt; Photographer list/accept/reject/start/delivery workflow; System/Admin một số transition. Bearer + role/ownership. | List/detail/cancel/confirm mock. | Booking request/decision/delivery mock. | `AVAILABLE` source; roles/specific action tại `booking.controller.ts:125-239,248-658,707`. | Có UI ở cả hai; cần mapping API/state machine, pagination, error/empty/loading state. |
| Calendar | `GET /photographers/:id/availability`, `/calendar/me`; `POST/DELETE /calendar/blocked-times` | Public xem khoảng trống; Photographer xem bookings/blocked times và block/unblock. | Booking slot mock. | Week scheduler mock. | `PARTIAL` cho weekly recurring editor; API date-range/blocking có sẵn (`calendar.controller.ts:55-318`). | Có UI; dùng API date-range/block flow sau khi chốt recurring requirement. |
| Portfolio & media/gallery | `GET/POST/PATCH/DELETE /photographers/me/portfolios`, `/photographers/:id/portfolios`, `/portfolios/:id/items`; `POST /media/upload-url`, `/media/complete-upload`; booking gallery GET/POST/publish/download | Creator upload/quản lý; customer/photographer xem gallery theo booking permissions; upload presigned URL/media state. | Detail/gallery UI mock; download image helper không phải media API. | Portfolio editor/storage/gallery UI mock. | `AVAILABLE` source (`portfolio.controller.ts`, `media.controller.ts:56-451`, `media.dto.ts`). | Nối flow hiện hữu sau khi xử lý upload lifecycle, ownership, visibility và URLs. |
| Payments / wallet | `POST /bookings/:id/payments/deposit`, `/remaining`; payment history/QR; `GET /wallet`, `/wallet/ledger`; top-up/withdrawal/refund | Customer/Photographer bearer + role; payment intent, ledger and request APIs. Payment writes side effect, không được dùng để test thật. | Deposit/payment/wallet UI mock. | Wallet/withdraw mock. | `AVAILABLE` source (`payments.controller.ts:82-228,509-688`; DTO idempotency/payout tại `payment.dto.ts:59-97,113-180`). | Có UI; tích hợp chỉ theo sandbox/contract đã duyệt. Customer Lens Xu chưa map tới VND wallet. |
| Subscription / storage | `GET /subscriptions/plans`, `/me`, `/me/usage`, `/me/history`; `POST /subscriptions`, `POST /subscriptions/:id/cancel` | Photographer subscription, payment and storage/portfolio limits. | Không thấy UI riêng. | Storage/plan UI mock. | `AVAILABLE` source (`subscription.controller.ts:53-338`; schema `responses.ts:370-397`). | Có UI Creator; tích hợp sau khi chốt plan SKU, entitlement và cancel behavior. |
| Ranks / badges | `GET /ranks`, `/badges` | Public read; Admin update riêng. | Không thấy counterpart. | Achievements UI mock. | `AVAILABLE` source (`rank.controller.ts:38-75`, `badge.controller.ts:38-75`). | Có thể dùng screen hiện có; không cần API mới. |
| User profile | `GET/PATCH /users/me`; `GET/PATCH /customers/me` | Authenticated profile; user patch supports fullname/avatar URL/phone/gender/dob; customer patch supports description/styles/location. | Profile settings partial. | Profile settings partial. | `AVAILABLE` source (`user.controller.ts:49-131`; `identity.dto.ts:67-105`; `customer.controller.ts:57-131`). | Dùng API hiện tại; avatar cần upload URL và HTTPS URL flow; address/default address không có field. |

### Backend ngoài phạm vi Mobile

- Admin routes: user management (`admin-user.controller.ts`), admin photographer review (`photographer.controller.ts`), admin booking/review/payment/report/dashboard (`booking.controller.ts`, `feedback.controller.ts`, `payments.controller.ts`, `moderation.controller.ts`), và admin edits cho ranks/badges. Không tính chúng là Mobile gap và không đề xuất Admin screens.
- Webhook/internal operations: `POST /payments/webhooks/:provider`, `/subscriptions/webhooks/:provider`, admin reconcile/refund review, outbox/worker. Đây là service-to-service/back-office; không phải Mobile flow.
- `POST /payments/test/payos` là standalone test endpoint; không gọi.

## 5. Feature có ở cả Mobile và Backend nhưng chưa đồng bộ

| Feature | App | Mobile implementation | Backend implementation | API đã nối? | Contract mismatch / mock | Hoàn thiện và việc cần làm |
|---|---|---|---|---|---|---|
| Auth/session | Customer + Creator | `ApiAuthRepository`, secure session store, bearer interceptor, refresh coalescing. Creator signup nộp `/photographers/profile`, login đọc `/photographers/me`. | `POST /auth/register/login/refresh/logout/change-password`; role/access; response token set + user. | Có trong source; chưa live. | Login/register flows không bao gồm OTP/forgot-password/Google UI. Không có live response evidence. | Giữ luồng API hiện tại; sau khi có base URL kiểm tra response/status thật. `SessionInterceptor` coalesces refresh qua một future, refresh-failure/terminal 401 expires session, GET retry tối đa một lần, write không replay, 403 không refresh/clear. |
| Profile/settings | Customer + Creator | Gọi `PATCH /users/me`; Customer thêm `PATCH /customers/me`; Creator thêm `PATCH /photographers/me/location`. | Các endpoint/DTO profile đã có. | Partial. | Customer address/default-address thay đổi bị từ chối; creator address chi tiết không có API; session/two-factor toggles mock. Hai PATCH profile tuần tự không atomic và Mobile cập nhật session local mà không đọc response authoritative. | Map response/reload profile; chốt address/default fields; giữ unsupported security action không thành success giả. |
| Discovery/profile | Customer | Active providers `MockPhotographerRepository` và `MockPhotographerDetailRepository`; model dùng cover, price, availability dates, years, gear, package deliveryDays. | Public photographer search/detail; separate plan/portfolio/review/calendar APIs. | Không. | Mock records và IDs như `p1` không phải API UUID; search filters nhiều hơn DTO; profile phải compose nhiều endpoint. | Thay mock theo từng resource; map UUID; chỉ render dữ liệu được API cung cấp. |
| Booking packages | Creator + Customer | Creator profile/package uses `MockDatabase`, `MockPhotographerDataSource`; Customer detail/wizard lấy mock packages. | Creator CRUD plans và public plan list. | Không. | Backend create DTO bắt `retouched_photo_count`; Mobile field semantics cần map; Mobile `deliveryDays` chưa có contract. | Xử lý field mapping trước booking; không ghi thành công local nếu API lỗi. |
| Booking lifecycle | Customer + Creator | Customer `MockBookingRepository`/`mockApiService`; Creator `BookingRepositoryImpl(MockBookingDataSource(...))`. | Booking use cases enforce roles, ownership, transitions, reservation and timeline; payment separate. | Không. | Status enums không trùng; Customer booking DTO có contact/note/price; backend create chỉ plan/location/from/to; cancel/reject require `reason`. IDs mock không phải UUID. | Viết canonical status mapper và role-specific action matrix; tích hợp list/detail/create/actions theo pagination; map failures/409/403 đúng. |
| Availability | Customer + Creator | Customer tạo slot 30 ngày với booked/busy values local rồi thêm mock bookings; Creator provider là `MockAvailabilityRepository`. | Public availability calculated from blocks/booking windows; photographer can view/block. | Không. | Customer default booked slots là dữ liệu giả; Creator weekly hours không có endpoint. | Customer chỉ hiện slot từ Backend availability; Creator dùng actual calendar APIs hoặc xin contract recurring hours. |
| Portfolio/media/gallery | Customer + Creator | Creator edits URL/photo arrays locally; Customer detail/gallery mock. Customer `MockDeliveryMediaRepository` chỉ tải remote image về thiết bị. | Portfolio CRUD, upload URL/complete, gallery add/publish/read/download. | Không. | Không có Media ID/ownership/visibility mapping từ UI. Remote image download không đồng nghĩa upload/gallery API. | Thực hiện upload lifecycle (get URL → upload object → complete → attach/publish), sau đó bind gallery read/download; không đánh dấu success trước response. |
| Reviews | Customer + Creator | Customer submissions and reward use mock repositories; Creator reviews provider uses `MockReviewDataSource`. | Customer create/edit/remove; public review/rating; photographer reply. DTO rating has multiple dimensions and backend-owned review policy. | Không. | Local reward 10,000 xu không có tương ứng trong review endpoint/wallet contract. Mobile needs to follow booking eligibility and server response. | Nối create/list/reply; bỏ reward claim khỏi server-confirmed UI nếu chưa có rule/API. |
| Messaging | Customer + Creator | Both mock message repositories/data sources; local read/preview/send. | Chat service code absent in `lens-be`; separate checkout referenced. | Không trong repo này; external status unverified. | No API contract evidence in audited source. | Get Chat service API/auth contract before integration; don't create fake server success. |
| Payment/wallet | Customer + Creator | Customer deposit UI states 30%/70%, Lens Xu wallet; Creator withdrawal mock accepts only amount. | Booking deposit/remaining payment intent require `idempotency_key` and method; wallet uses VND ledger; withdrawal also requires reason, payout destination, idempotency. | Không. | Mobile has no idempotency / provider state mapping; Creator withdraw UI data is insufficient; coin logic does not map to generic wallet. | Agree payment/wallet business rules and sandbox; map immutable transaction states before UI success. No live money tests. |
| Subscription/storage/rank | Creator | Plan/storage and achievements UI use mock models/data. | Subscription plan/me/usage/history/purchase/cancel, plus rank/badge endpoints. | Không. | Mobile storage tier/achievement model may not equal Backend entitlements, rank thresholds or storage bytes. | Map exact plan IDs, usage units/limits and rank/badge fields; otherwise display only API fields. |
| Notifications | Customer + Creator | Local toggles/settings only. | Outbound notification events exist; no user preference HTTP API in `lens-be`. | Không. | A successful local toggle is not persisted server-side. | Hide/label unsupported toggles or create a preference API contract. |

### Auth/API contract findings

- Mobile sends `email/password`, signup sends `role`, `fullname`, `email`, `password`; Backend DTO/controller matches. Customer role normalizes `customer` to app role `client`; Creator validates `photographer`.
- Backend `POST /auth/login` and registration return `{access_token, refresh_token, expires_in, user}` according to controller and `responses.ts` (`AUTH-008/009`); Mobile parses those direct fields. `setupApi.ts` registers validation/Swagger but no global `TransformResponseInterceptor` is wired in the inspected code, so the defined wrapper class is not evidence that live controller responses are wrapped.
- Creator registration first calls `POST /auth/register`, then authenticated `POST /photographers/profile` with `location/styles`; Backend profile creation sets `verification_status: pending`. Creator login checks `/photographers/me` and permits dashboard only for `verified`. The source sequence is present; only live state transitions remain unverified.
- Both apps store token/user through `flutter_secure_storage`, restore before `runApp`, attach Bearer except public auth routes, and share a single in-flight refresh future. Safe replay policy is GET-only to avoid duplicate writes. A `403` is passed through; it is not treated as token expiry. This is source behavior, not a live test result.

## 6. Tổng quan độ phủ

### Ma trận 28 flow-level rows

| Domain / flow | Customer Mobile | Creator Mobile | Backend source | Gap chính |
|---|---|---|---|---|
| Auth login/register/logout/session refresh | `API_INTEGRATED` | `API_INTEGRATED` | `AVAILABLE` | Không có `VERIFIED_LIVE`; reset/OTP/Google chưa có UI. |
| Profile/settings | `PARTIALLY_INTEGRATED` | `PARTIALLY_INTEGRATED` | `AVAILABLE` | Address/default/session/2FA và preference chưa tương thích/thiếu. |
| Discovery/search | `MOCK_ONLY` | `NOT_FOUND` | `AVAILABLE` / `PARTIAL` filters | Customer filters vượt query DTO. |
| Photographer detail/public profile | `MOCK_ONLY` | `MOCK_ONLY` preview/editor | `AVAILABLE` nhiều resource | Một số rich fields chưa có source/contract. |
| Booking create | `MOCK_ONLY` | `NOT_FOUND` | `AVAILABLE` | Request shape, plan UUID, time window. |
| Booking list/detail/actions | `MOCK_ONLY` | `MOCK_ONLY` | `AVAILABLE` | Enum/state mapping, role actions, mock IDs. |
| Calendar/availability | `MOCK_ONLY` | `MOCK_ONLY` | `PARTIAL` | Customer slots giả; weekly recurrence chưa có. |
| Delivery gallery/media | `MOCK_ONLY` | `MOCK_ONLY` | `AVAILABLE` | Upload/attach/publish/read chưa nối. |
| Reviews/ratings | `MOCK_ONLY` | `MOCK_ONLY` | `AVAILABLE` | Reward coins không có contract tương ứng. |
| Messaging | `MOCK_ONLY` | `MOCK_ONLY` | `UNVERIFIED` ngoài repo | Chat service checkout/OpenAPI chưa có trong audit. |
| Payments/wallet | `MOCK_ONLY` | `MOCK_ONLY` | `AVAILABLE` | Idempotency/provider lifecycle; Lens Xu mismatch. |
| Subscription/storage | `NOT_FOUND` | `MOCK_ONLY` | `AVAILABLE` | Creator screen chưa map entitlements/usage. |
| Notifications/preferences | `MOCK_ONLY` | `MOCK_ONLY` | `PARTIAL` (outbound only) | Không có preference API. |
| Active session/2FA | `UI_ONLY` | Cài đặt mock nằm trong flow profile/settings `PARTIALLY_INTEGRATED` | `PARTIAL` | Password/logout có; list/revoke/2FA không thấy API. |
| Creator achievements | `NOT_FOUND` | `MOCK_ONLY` | `AVAILABLE` ranks/badges | Read API chưa nối. |
| Creator assistant/FAQ | `NOT_FOUND` | `MOCK_ONLY` | `UNVERIFIED` ngoài repo | Chat checkout chưa kiểm tra. |

Ma trận trên hiển thị thêm `NOT_FOUND` cho role-flow không có màn hình; số lượng **28** dùng thống kê bên dưới chỉ tính flow hiện hữu, không tính các `NOT_FOUND` role-flow và không đếm từng screen/endpoint riêng.

| Chỉ số | Số lượng | Cách đếm |
|---|---:|---|
| Feature Mobile có nhưng API Backend thiếu rõ ràng | 3 | Notifications preferences; active-session/2FA endpoints; creator collaboration/invite/share. |
| Feature Mobile có nhưng Backend chỉ đáp ứng một phần | 7 | Discovery filter set; detail rich fields; booking request/state mapping; weekly calendar; package fields; Customer Lens Xu/reward wallet mapping. (Booking request và state được tách thành 2 gap rows.) |
| Feature Mobile có nhưng Backend chưa xác minh ngoài repo | 2 | Messaging; Creator assistant/FAQ, do checkout chat-service chưa có. |
| Backend capability có nhưng không có Mobile flow tương ứng | 2 nhóm | Password reset/OTP/Google auth; user report submission/tracking. Admin, webhooks và internal worker bị loại khỏi scope Mobile. |
| Feature có Mobile flow và Backend API tương ứng/related nhưng Mobile còn mock | 18/28 flow rows | 9 Customer + 9 Creator business flows. Một số API đáp ứng một phần contract; xem Report 3. |
| Mobile flow đang mock, bất kể Backend coverage | 23/28 flow rows | 11 Customer + 12 Creator business flows. Trong 23 flow này có 2 notification-preference flows chưa có API và 3 Chat/assistant flows chưa xác minh ngoài repo. |
| Feature tích hợp một phần | 2/28 | Profile/settings ở hai app. |
| Feature API-integrated trong source | 2/28 | Customer auth và Creator auth/onboarding. |
| Feature có xác minh live | 0 | Không có origin deploy hoặc credentials hợp lệ; không gọi HTTP. |
| Chưa đủ bằng chứng để kết luận hệ thống | 2 capability | Chat và assistant vì service ngoài checkout. |

**Lưu ý phép đếm:** 28 = 14 flow-level rows Customer + 14 flow-level rows Creator. Trong đó 23 Mobile rows đang `MOCK_ONLY`; 18 flow rows có API tương ứng hoặc related trong Backend nhưng chưa nối, 2 notification preference rows thiếu API, và 3 rows liên quan Chat/assistant chưa xác minh ngoài repo. Auth 2 rows `API_INTEGRATED`, profile/settings 2 rows `PARTIALLY_INTEGRATED`, Customer active-session 1 row `UI_ONLY`. Creator security toggles được tính trong flow settings đã tích hợp một phần. Capability missing/partial trong gap register là số loại contract gap, có thể liên quan nhiều màn hình nhưng không nhân theo endpoint.

## 7. Thứ tự xử lý đề xuất

Không có gap nào được gán `P0` chỉ vì API chưa tích hợp. Không xác nhận release blocker khi chưa có cấu hình môi trường/release mục tiêu.

### P0

Không xác định P0 với bằng chứng source hiện có. Sau khi team xác định release scope, đánh giá lại nếu booking/auth thật là điều kiện chặn rollout.

### P1

| Repo | Vấn đề / lý do | Phụ thuộc | Phương án | Điều kiện hoàn thành |
|---|---|---|---|---|
| Customer Mobile + Creator Mobile + deploy config | Chưa có Backend origin xác nhận nên không thể kiểm chứng các luồng API hiện có trên môi trường thật. | Chủ dự án cung cấp environment/origin hợp lệ qua cấu hình chuẩn; không commit secret. | Cấu hình `API_BASE_URL` theo môi trường build; chạy GET/auth smoke test chỉ sau khi có endpoint và test account được cấp phép. | Cả hai app xác thực và đọc profile trên staging; kết quả/status/response fields được ghi lại. |
| Customer Mobile | Discovery/profile/booking vẫn dùng mock; các booking request fields/status không khớp. Đây là core flow Customer. | Chốt status state machine, contact/note semantics, timezone, package UUID và UI fields thiếu contract. | Nối `/photographers`, plans, profile resources, availability, bookings; điều chỉnh DTO mapper/state/UI theo contract. | Search/detail/booking/list hoạt động với IDs thật; empty/error/pagination và 401/403/409 được hiển thị đúng; không còn dữ liệu success giả ở flow đó. |
| Creator Mobile | Booking requests, packages, calendar và portfolio vẫn dùng mock dù API đã có. | Chốt state mapping và yêu cầu weekly schedule; xác định package fields. | Nối plan CRUD, bookings, calendar, portfolio/media lần lượt; nếu weekly recurring bắt buộc, chốt Backend contract trước. | Creator tạo/sửa plan, xem/accept/reject booking, chặn ngày và publish portfolio bằng response thật, với ownership/role errors rõ ràng. |
| Customer + Creator | Payments/wallet hiện mock; API yêu cầu idempotency và có external gateway/wallet state. | Sandbox/staging payment provider, amount/method/escrow/refund rules, wallet units. | Tích hợp chỉ trên sandbox sau review contract; không dùng production giao dịch để test. | Idempotent request, callback/polling and final transaction state verified trên sandbox; số dư lấy từ API. |
| Customer + Creator | Messaging không nối và contract chat service không thuộc checkout hiện tại. | Source/OpenAPI/auth của `chat-service`; WebSocket/deep-link details. | Lấy contract rồi bind vào inbox/message providers hiện có. | List/send/read/reconnect verified bằng test accounts; không local-only success. |

### P2

| Repo | Vấn đề | Phụ thuộc / phương án | Điều kiện hoàn thành |
|---|---|---|---|
| Backend + Customer + Creator | Không có notification preference API; toggles mock. | Chốt preference schema, channel/event semantics, consent/persistence rồi bổ sung API hoặc loại bỏ toggle. | Cài đặt lưu/đọc lại server-side, có test giữa thiết bị. |
| Backend + Customer | UI session revoke/2FA không được hỗ trợ; repository chủ động trả lỗi. | Chốt Keycloak/session semantics và có cần thiết bị/session management không. | UI chỉ hiển thị action khi backend có contract và revoke hiệu lực được kiểm chứng. |
| Backend + Creator | Collaboration nhiều photographer và split-share chưa có route/domain được thấy. | Chốt owner, quyền nhận lời mời, chia tiền, hủy và trách nhiệm booking. | API + state tests cover invite/accept/decline/settlement hoặc mobile bỏ flow chưa được chấp thuận. |
| Customer Mobile / Backend | Rich profile fields và discovery filters không hoàn toàn có dữ liệu từ API. | Product quyết định filters/fields thực sự dùng; xác minh profile/portfolio/media model. | Không còn giá, cover, rating, availability hoặc badges hardcode trong production UI; API response đủ hoặc UI ẩn field. |
| Creator Mobile | `deliveryDays`, storage plan tiers, local rank/badges/FAQ chưa map contract. | Plan/entitlement semantics; assistant service ownership. | Mapping được review theo DTO; unknown fields không tự biến thành API result. |
| Customer + Creator | Password reset/OTP/Google auth và reporting API chưa có flow Mobile. | Product/security decision và deep-link/OTP requirements. | Flow có route validation/error/replay safeguards hoặc được ghi rõ ngoài Mobile scope. |

### OUT_OF_SCOPE

- Admin review/dashboard/user/payment/report screens.
- Payment/subscription webhook callbacks, reconciliation jobs, outbox/Kafka/internal worker.
- PayOS standalone test route, migration/database infra, và Chat service nội bộ chưa có source contract trong checkout này.

## 8. Điểm chưa xác minh và blocker

1. **Backend deploy origin:** Chưa xác định được. `BACKEND_DOMAIN` trong Caddy stack có local default; `API_PUBLIC_URL` là runtime env; không đọc secret hoặc `.enc`, không đoán URL. Không gọi API.
2. **Live auth/profile/booking behavior:** Không có origin/credentials/test account; không kiểm tra request-response thực tế. `API_INTEGRATED` chỉ nói source wiring.
3. **Chat/assistant:** `.docker/README.md` trỏ tới checkout kế bên `../chat-service`; repo/service contract đó ngoài phạm vi quyền/source đã cung cấp. Không kết luận capability tổng thể bị thiếu.
4. **Giá, cover, lịch và lọc discovery:** Mobile mock dùng giá/ảnh/lịch; không có bằng chứng đây là dữ liệu thật. Không đề xuất dùng mock như fallback API production.
5. **Payment:** Không gọi deposit, top-up, withdrawal, refund, payment test endpoint hoặc webhook; chỉ đọc DTO/controller/business code.
6. **Tests/build:** Không chạy formatter/analyzer/tests/build trong lượt audit. Trạng thái dirty/generated files được giữ; cần chạy pipeline riêng sau khi coding task được yêu cầu.
7. **Working trees trước/sau audit:** `Lens-mobile` và `lens-creator-mobile` đã có các thay đổi chưa commit; `lens-be` và `Lens-web` sạch tại thời điểm kiểm tra. Audit chỉ tạo báo cáo mới, không thay đổi các thay đổi đó.

## 9. Appendix: module, file và API đã kiểm tra

### Customer Mobile

- Navigation: `lib/core/router/app_router.dart` (auth, discovery, detail, booking, bookings, gallery, messages, payment, reviews, wallet, settings).
- State/providers: `lib/providers/data_providers.dart` (`ApiAuthRepository`; mock wallet/reviews/messages/notifications/bookings); `lib/features/customer/discovery/repositories/discovery_repository_provider.dart`; `lib/features/customer/photographer_detail/repositories/photographer_detail_repository_provider.dart`; `lib/features/customer/bookings/repositories/customer_booking_repository_provider.dart`.
- Network/auth: `lib/core/network/api_config.dart`, `dio_client.dart`, `session_interceptor.dart`, `auth_session_store.dart`, `api_exception.dart`, `lib/data/repositories/api_auth_repository.dart`.
- Feature evidence: `features/customer/discovery/{models,controllers,repositories}`, `photographer_detail/{models,repositories}`, `booking_flow/{models,controllers}`, `bookings/{models,repositories,controllers}`, `payments/deposit_screen.dart`, `wallet/wallet_screen.dart`, `reviews/reviews_screen.dart`, `messages/*`, `settings/settings_screen.dart`.

### Creator Mobile

- Navigation: `lib/core/router/app_router.dart` (auth, photographer shell, bookings, messages, availability, packages, portfolio, storage, reviews, wallet, achievements, assistant, settings).
- State/providers: `lib/providers/data_providers.dart`; `lib/features/photographer/availability/schedule_provider.dart`; `features/photographer/settings/settings_provider.dart`; feature providers/repositories for reviews, achievements, messages, assistant, storage and wallet.
- Network/auth: `lib/core/network/{api_config,dio_client,session_interceptor,auth_session_store,api_exception}.dart`, `lib/data/repositories/api_auth_repository.dart`.
- Feature evidence: `lib/domain/models/models.dart`, `lib/data/repositories/booking_repository_impl.dart`, `lib/data/datasources/mock/mock_booking_data_source.dart`, `features/photographer/availability/*`, `packages/*`, `portfolio/*`, `storage/*`, `wallet/*`, `reviews/*`, `messages/*`, `achievements/*`, `assistant/*`, `settings/*`.

### Backend `lens-be`

- HTTP controllers reviewed (all `src/features/api/http/*.controller.ts`): `auth`, `google-auth`, `user`, `customer`, `photographer`, `booking-plan`, `booking`, `calendar`, `portfolio`, `media`, `feedback`, `payments`, `subscription`, `rank`, `badge`, `moderation`, `admin-user`, `payos-standalone-test`.
- Contract/response: `src/features/api/dto/{auth,identity,customer,photographer,booking-plan,booking,calendar,portfolio,media,review,payment,subscription,moderation}.dto.ts`; `src/features/api/swagger/{responses,record-schemas}.ts`; `src/features/api/setup.ts`.
- Business logic checked: `src/modules/identity/identity.use-case.ts`; `src/modules/customer/customer.use-case.ts`; `src/modules/photographer/{photographer.use-case.ts,photographers.query.ts,booking-plan/*,portfolio.use-case.ts}`; `src/modules/booking/core/*`; `src/modules/calendar/schedule/*`; `src/modules/media/*`; `src/modules/feedback/review/*`; `src/modules/payment/{payment.use-case.ts,wallet/*,refund/*}`; `src/modules/subscription/*`; `src/modules/moderation/report/*`.
- Deployment evidence: `deploy/portainer/lens-caddy.yml`, `deploy/portainer/backend-stack.yml`, `.docker/README.md`, `.docker/chat-service/*`, `src/shared/integrations/notification/*`.

## Tóm tắt trả lời trực tiếp

- **Mobile cần Backend bổ sung gì?** Trong `lens-be`: notification preference endpoints, active-session/2FA management nếu các UI này được giữ, và collaboration/team-share nếu Creator booking collaboration là requirement. Weekly schedule, discovery rich filters/profile fields, package delivery days và Lens Xu cần thống nhất contract; chat/assistant cần audit service riêng trước khi kết luận.
- **Backend có gì mà Customer Mobile còn thiếu?** Forgot-password/OTP/Google auth và report submission/tracking chưa có flow Mobile. Discovery/recommendation, profile, plans, booking/calendar, portfolio/media, reviews, payment/wallet đều có UI nhưng đang mock hoặc chưa gọi API.
- **Backend có gì mà Creator Mobile còn thiếu?** Creator đã có auth/onboarding API source, nhưng chưa tích hợp package CRUD, bookings, calendar, portfolio/media, reviews/reply, wallet, subscription/storage và ranks/badges. Collaboration/weekly recurring schedule chưa đủ contract trong `lens-be`.
- **Việc chỉ cần sửa Mobile, không cần sửa Backend?** Nối các API đã có cho auth/profile, discovery/profile composition, plans, booking lifecycle, date-range calendar, portfolio/media, reviews, wallet/payment, subscription và achievements; thêm response/status/UUID mapping, idempotency, loading/error/empty/pagination. Avatar có thể dùng `PATCH /users/me` sau media upload flow nếu URL/visibility phù hợp; không cần endpoint avatar riêng theo source hiện có.
- **Cần thống nhất nghiệp vụ trước khi code?** Booking state/payment state, contact/note snapshot và timezone; filter/profile fields thật sự cần; recurring weekly hours; `Lens Xu` versus VND wallet/rewards; delivery-days semantics; collaboration/split settlement; notification preferences; Google/OTP/report scope; Chat service ownership/API/auth.


## 10. Kiểm tra live deployment `api.lens.id.vn`

**Ngày kiểm tra:** 2026-10-10. **Base URL:** `https://api.lens.id.vn` (route ở root; ví dụ `/photographers`, không cần `/api/v1`). Live OpenAPI trả `200`, có **119 path / 131 method operations**. Swagger UI: <https://api.lens.id.vn/docs>; JSON: <https://api.lens.id.vn/docs-json>. `GET /` trả `404` vì không có handler root; điều đó không có nghĩa API ngừng chạy.

### Kết quả tổng hợp

- 55 GET: 6 trả `200`; 41 trả `401` khi không gửi token hoặc dùng OAuth code giả; 8 trả `404` vì thử bằng UUID không tồn tại.
- 67 route ghi có Bearer security: tất cả trả `401` khi không gửi token; request bị chặn trước mutation.
- 7 route public auth được gọi bằng body rỗng: 6 trả `400` do validation; `POST /auth/logout` trả `200` idempotently khi không có refresh token. Không tạo account, gửi OTP hay đổi mật khẩu.
- 2 webhook không được gọi vì có thể xử lý sự kiện thanh toán/subscription. Chỉ xác nhận chúng xuất hiện trong live OpenAPI.
- Các response GET public: `/photographers` và `/photographers/top-rated` trả `{items,total,offset,limit}` với 20 items mỗi endpoint; `/ranks` có 5 items; `/badges` có 3 items; `/subscriptions/plans` trả 0 plans hiện tại; `/keycloak/google/login` trả JSON có `authorization_url`.
- Không có request nào dùng access token thật; `401` ở endpoint bảo vệ xác nhận server/auth guard phản hồi, chưa xác minh business flow sau đăng nhập. Không có payment/wallet mutation.

### Ma trận từng operation trong live OpenAPI

| Method | Route | Kết quả | Diễn giải |
|---|---|---:|---|
| `POST` | `/auth/register` | **400** | Gửi `{}`; DTO từ chối vì thiếu dữ liệu, không tạo tài khoản. |
| `POST` | `/auth/login` | **400** | Gửi `{}`; DTO từ chối vì thiếu credentials. |
| `POST` | `/auth/refresh` | **400** | Gửi `{}`; DTO từ chối vì thiếu refresh token. |
| `POST` | `/auth/logout` | **200** | Gửi `{}`; logout idempotent, không có refresh token để revoke. |
| `POST` | `/auth/change-password` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/auth/forgot-password/send-otp` | **400** | Gửi `{}`; thiếu email nên không gửi OTP. |
| `POST` | `/auth/forgot-password/verify` | **400** | Gửi `{}`; thiếu email/OTP. |
| `POST` | `/auth/forgot-password/reset` | **400** | Gửi `{}`; thiếu reset token/password. |
| `POST` | `/auth/email/send-otp` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/auth/email/verify` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/users/me` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `PATCH` | `/users/me` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/users/{user_id}` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/admin/users` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/admin/users/{user_id}` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `PATCH` | `/admin/users/{user_id}/status` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/users/{user_id}/suspend` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/users/{user_id}/unsuspend` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/users/{user_id}/ban` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/keycloak/google/login` | **200** | GET không token: public endpoint trả response. |
| `GET` | `/keycloak/google/callback` | **401** | Request dùng state/code giả; Keycloak từ chối. |
| `GET` | `/keycloak/google/exchange` | **401** | Request dùng code giả; endpoint từ chối code không hợp lệ. |
| `GET` | `/customers/me` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `PATCH` | `/customers/me` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/admin/customers/{customer_id}` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/admin/customers` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/customers/me/summary` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/customers/me/recommendations` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `PATCH` | `/photographers/me/location` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `PATCH` | `/photographers/me/status` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/admin/photographers` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/admin/photographers/{photographer_id}/approve` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/photographers/{photographer_id}/reject` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `PATCH` | `/photographers/me` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/photographers/me` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/photographers/profile` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/photographers/top-rated` | **200** | GET không token: public endpoint trả response. |
| `GET` | `/photographers` | **200** | GET không token: public endpoint trả response. |
| `GET` | `/photographers/{photographer_id}` | **404** | GET với UUID không tồn tại; handler trả lỗi không tìm thấy resource. |
| `POST` | `/photographers/me/booking-plans` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/photographers/me/booking-plans` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `PATCH` | `/booking-plans/{booking_plan_id}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `DELETE` | `/booking-plans/{booking_plan_id}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/photographers/{photographer_id}/booking-plans` | **404** | GET với UUID không tồn tại; handler trả lỗi không tìm thấy resource. |
| `GET` | `/ranks` | **200** | GET không token: public endpoint trả response. |
| `PATCH` | `/admin/ranks/{code}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/badges` | **200** | GET không token: public endpoint trả response. |
| `PATCH` | `/admin/badges/{code}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/photographers/me/portfolios` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/photographers/me/portfolios` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `PATCH` | `/portfolios/{portfolio_id}/items/reorder` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/photographers/{photographer_id}/portfolios` | **404** | GET với UUID không tồn tại; handler trả lỗi không tìm thấy resource. |
| `POST` | `/portfolios/{portfolio_id}/items` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/portfolios/{portfolio_id}` | **404** | GET với UUID không tồn tại; handler trả lỗi không tìm thấy resource. |
| `PATCH` | `/portfolios/{portfolio_id}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `DELETE` | `/portfolios/{portfolio_id}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `DELETE` | `/portfolios/{portfolio_id}/items/{portfolio_item_id}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/admin/bookings` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/bookings` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/bookings` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/bookings/{booking_id}/accept` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/cancel` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/complete` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/confirm-receipt` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/complete-shoot` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/dispute` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/reject` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/start` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/bookings/{booking_id}/timeline` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/bookings/{booking_id}` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/admin/bookings/{booking_id}/cancel` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/payments/deposit` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/payments/remaining` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/bookings/{booking_id}/payments` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/payments/{payment_id}` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/payments/{payment_id}/qr` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/payments/webhooks/{provider}` | **Chưa gọi** | Webhook có thể xử lý payment/subscription event; không gửi event thử. |
| `POST` | `/payments/{payment_id}/refund` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/payments/{payment_id}/refunds` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/wallet` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/wallet/ledger` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/wallet/topups` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/wallet/withdrawals` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/me/refund-requests` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/bookings/{booking_id}/refund-requests` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/admin/payments` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/admin/refund-requests` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/admin/refund-requests/{refund_request_id}/approve` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/refund-requests/{refund_request_id}/reject` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/refund-requests/{refund_request_id}/complete` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/refund-requests/{refund_request_id}/extend-deadline` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/bookings/{booking_id}/escrow/extend-release` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/payments/test/payos` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/calendar/blocked-times` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/calendar/me` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `DELETE` | `/calendar/blocked-times/{offline_slot_id}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/photographers/{photographer_id}/availability` | **404** | GET với UUID không tồn tại; handler trả lỗi không tìm thấy resource. |
| `GET` | `/photographers/{photographer_id}/offline-slots` | **404** | GET với UUID không tồn tại; handler trả lỗi không tìm thấy resource. |
| `GET` | `/calendar/blocked-times/affected` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/media/complete-upload` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/media/upload-url` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/bookings/{booking_id}/gallery/download` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/bookings/{booking_id}/gallery/items` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/gallery/publish` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/gallery` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/bookings/{booking_id}/gallery` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/media/{media_id}` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `DELETE` | `/media/{media_id}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/bookings/{booking_id}/reviews` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/photographers/{photographer_id}/rating-summary` | **404** | GET với UUID không tồn tại; handler trả lỗi không tìm thấy resource. |
| `GET` | `/photographers/{photographer_id}/reviews` | **404** | GET với UUID không tồn tại; handler trả lỗi không tìm thấy resource. |
| `PATCH` | `/reviews/{feedback_id}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `DELETE` | `/reviews/{feedback_id}` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `PUT` | `/reviews/{feedback_id}/reply` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/reviews/{feedback_id}/restore` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/reviews/{feedback_id}/hide` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/admin/reviews` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/subscriptions/me/usage` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/subscriptions/me` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/subscriptions/me/history` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/subscriptions/plans` | **200** | GET không token: public endpoint trả response. |
| `POST` | `/subscriptions` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/subscriptions/{subscription_id}/cancel` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/subscriptions/payments/{subscription_payment_id}/reconcile` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/subscriptions/webhooks/{provider}` | **Chưa gọi** | Webhook có thể xử lý payment/subscription event; không gửi event thử. |
| `GET` | `/admin/dashboard` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/admin/reports` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `GET` | `/reports/me` | **401** | GET không Bearer token; route bảo vệ trả 401. |
| `POST` | `/reports` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `POST` | `/admin/reports/{report_id}/resolve` | **401** | Request không có Bearer token; auth guard chặn trước khi ghi dữ liệu. |
| `GET` | `/admin/reports/{report_id}` | **401** | GET không Bearer token; route bảo vệ trả 401. |
