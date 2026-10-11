# Audit tương thích API Mobile–Backend LENS trước khi tích hợp

Ngày audit: 2026-10-10  
Phạm vi: Lens-mobile (Customer), lens-creator-mobile (Photographer/Creator), lens-be và Lens-web/apps/portal làm nguồn tham chiếu.  
Trạng thái: chỉ đọc source; không tích hợp API, không sửa UI, không chạy test/build/analyze, không gọi endpoint production trong lượt audit này.

## 1. Tóm tắt điều hành

Hai app Mobile hiện kết nối API thật cho authentication ở mức source. Creator còn tạo hồ sơ Photographer và kiểm tra trạng thái xét duyệt. Session được lưu bằng secure storage và có refresh interceptor. Chưa có bằng chứng trong lượt audit này về một phiên đăng nhập thật đã chạy thành công từ Mobile.

Các flow nghiệp vụ còn lại chủ yếu vẫn lấy dữ liệu từ mock repository/provider. Backend đã có API cho phần lớn các capability cốt lõi, nhưng thay mock bằng API không phải chỉ đổi URL: Mobile còn dùng ID mẫu, model/status khác Backend, một số field không có trong DTO, và các thao tác có điều kiện về role, payment, ownership hoặc trạng thái booking.

Portal Web có nhiều chuỗi UI → React Query → service → endpoint Backend thật trong source. Tuy vậy, source wiring không chứng minh deployment Portal hiện tại đang gọi đúng Backend: local env không có VITE_BACKEND_API_URL; Docker yêu cầu biến này; DEPLOY.md hướng dẫn VITE_API_MOCKING=enabled; trong khi apps/portal/src/main.tsx không khởi tạo MSW. Cần xác minh cấu hình build production trước khi dùng hành vi Web làm bằng chứng runtime.

| Feature | Quyết định đề xuất | Owner | Lý do | Cần tôi duyệt? |
|---|---|---|---|---|
| Auth/session | Giữ tích hợp API source hiện tại; cấu hình API_BASE_URL theo môi trường và kiểm chứng bằng tài khoản QA | Mobile + DevOps/QA | Request/response khớp DTO cơ bản; không có API_BASE_URL mặc định và chưa xác minh authenticated live flow | Có, chọn môi trường và tài khoản kiểm thử |
| Customer discovery | Kết nối keyword, khu vực, rating và top-rated; quyết định riêng về filter giá, style, kinh nghiệm, ngày rảnh | Product + Mobile; Backend nếu giữ đủ filter | Search DTO chỉ có limit/offset/location/keyword/min_rating | Có |
| Photographer detail và packages | Ghép profile, booking plans, portfolio, reviews/rating; không tạo giá/cover/lịch từ mock | Mobile; Product cho field còn thiếu | Backend tách dữ liệu thành nhiều endpoint; không có cover/gear/insurance/deliveryDays trong contract public đã kiểm tra | Có, chốt field nào bắt buộc |
| Booking | Chốt state machine, dữ liệu contact/note và quy tắc thời gian trước khi nối create/action | Product + Mobile; Backend nếu cần snapshot fields | Create body là photographer_id, booking_plan_id, location, from, to; trạng thái Backend khác enum Mobile | Có |
| Creator calendar | Nối xem calendar và tạo/xóa blocked time; quyết định có giữ lịch tuần lặp lại không | Product + Mobile; Backend nếu cần recurring rules | API date-range/block đã có; chưa thấy API lưu weekly template | Có |
| Portfolio/gallery/media | Nối theo chuỗi media upload → complete → attach → publish → customer read/download sau khi có booking IDs thật | Mobile | Backend có workflow, nhưng hiện Mobile dùng URL/ảnh mock | Không cần quyết định nghiệp vụ mới, cần duyệt ưu tiên |
| Payments/wallet | Chốt 30/70, wallet VND so với Lens Xu, payout/refund; chỉ thử trên sandbox | Product + Backend + Mobile | Backend tự tính amount, cần idempotency; Creator withdrawal yêu cầu bank destination/reason | Có |
| Reviews | Nối public list/summary, submit theo booking đủ điều kiện; bỏ reward xu khỏi trạng thái thành công cho đến khi có contract | Mobile; Product cho reward | Backend có review API nhưng không có Lens Xu reward trong review contract | Có với reward |
| Messaging/AI/collaboration | BLOCKED cho đến khi có contract chat service; collaboration cần API/domain nếu vẫn là yêu cầu | Team Chat/Backend + Product | Portal cũng có service chủ động throw unsupported; không thấy các API này trong lens-be | Có |
| Notification preferences và quản lý session | Nếu giữ toggle/revoke/2FA actions, yêu cầu contract Backend/Keycloak; nếu chưa cần thì không hiển thị như đã lưu thật | Product + Backend/Security | lens-be có outbound notification, logout/change-password; không có preference/session-list/revoke/2FA HTTP route | Có |

**Kết luận để bắt đầu giai đoạn tích hợp:** Có thể triển khai nhóm C trong source cho auth/profile cơ bản, discovery/profile/resources, booking plans, booking/calendar, portfolio/gallery, reviews, payment/wallet, subscription/achievements. Trước khi triển khai booking và payment UI cần duyệt các mục nhóm D bên dưới. Không nên coi thao tác local/mock là kết quả thành công của API.

## 2. Phạm vi, phương pháp và cách đọc kết quả

### Đã kiểm tra

- Lens-mobile: router, screens/widgets, models, providers, repository implementations và mock repositories liên quan đến Customer.
- lens-creator-mobile: router, screens, Riverpod providers, domain/data repositories và mock data sources liên quan đến Photographer.
- lens-be: controller HTTP, DTO validation, Swagger response schemas, role guards, use cases/domain state transitions và các module booking/calendar/media/payment/feedback/subscription/profile.
- Lens-web: apps/portal, theo chuỗi route/screen → query hook → facade service → services/backend → backend-api client. Admin và Landing không được xét như ứng dụng Mobile.
- Git status của bốn repo: Lens-mobile và lens-creator-mobile đã có thay đổi chưa commit từ trước; Lens-web và lens-be không có thay đổi được hiển thị tại lần kiểm tra đầu. Không thay đổi hoặc xóa bất kỳ thay đổi nào trong working tree.

### Trạng thái được dùng trong báo cáo

- **Mobile API source**: provider đang inject repository gọi HTTP và có mapping/state tương ứng; không đồng nghĩa request đã thành công trên production.
- **Mock**: UI hiện lấy dữ liệu hoặc thực hiện action thông qua mock repository/data source, local provider hoặc MockDatabase.
- **Backend có**: controller, DTO và đường đi service/use case có trong source lens-be; không đồng nghĩa đã triển khai đúng trên mọi môi trường.
- **Portal gọi API trong source**: UI đang dùng query/service đi tới backendApi; không đồng nghĩa deployment đã được cấu hình đúng.
- **Partial**: một phần field/flow đã nối, phần còn lại local/mock/unsupported.
- **Unverified**: capability có thể nằm ở service khác ngoài các source được kiểm tra.

Không dùng tên file Api... để kết luận đã tích hợp; trạng thái được suy từ provider mà screen thực sự inject. Không chạy test/analyzer/build vì giai đoạn này chỉ audit, không thay code và không cần xác nhận runtime. Không gọi API production trong lượt này.

### Backend origin và môi trường Web/Mobile

- Base URL đã được bạn cung cấp trước đó: https://api.lens.id.vn. Tệp MOBILE_BACKEND_AUDIT.md đã có sẵn trong working tree trước lượt này và ghi lại lần kiểm tra trước: public GET /photographers, /photographers/top-rated, /ranks, /badges, /subscriptions/plans trả 200; các protected route không token trả 401; không có token tài khoản để kiểm chứng flow nghiệp vụ. Báo cáo cũ có phần mở đầu nói chưa xác định origin/no live calls nhưng phần 10 lại ghi kết quả live; đây là mâu thuẫn nội bộ. Báo cáo mới này dùng origin theo thông tin bạn đã cung cấp, không lặp lại request production.
- Hai app Flutter đọc String.fromEnvironment('API_BASE_URL'); ApiConfig yêu cầu URL tuyệt đối HTTPS và báo lỗi nếu giá trị rỗng. Source không có production URL mặc định. Khi chạy app cần truyền API_BASE_URL cho build/run; không commit token/secret.
- Portal dùng import.meta.env.VITE_BACKEND_API_URL. Trong các file .env của portal/admin/landing chỉ thấy các tên biến VITE_*_URL và VITE_API_MOCKING; không có VITE_BACKEND_API_URL.
- Dockerfile.frontend yêu cầu VITE_BACKEND_API_URL khi build. DEPLOY.md lại liệt kê VITE_API_MOCKING=enabled trong hướng dẫn Vercel; Portal main.tsx không bật MSW, còn Landing main.tsx có bật. Vì vậy cần kiểm tra cấu hình production đã build VITE_BACKEND_API_URL vào Portal chưa. Không suy luận từ việc một số service trong source gọi Backend rằng site production đang gọi Backend.

## 3. Customer Mobile: feature và wiring hiện tại

| Feature/screen | Nhu cầu UI/flow hiện tại | Wiring hiện tại | Finding |
|---|---|---|---|
| Auth: login, signup, logout | Tạo tài khoản/đăng nhập, giữ user role và điều hướng app | authRepositoryProvider dùng ApiAuthRepository | Source gửi POST /auth/login và /auth/register; signup map client/customer sang role customer; response yêu cầu access_token, refresh_token, expires_in, user |
| Session và mật khẩu | Khôi phục session, refresh token, change password, logout | flutter_secure_storage + SessionInterceptor + API repository | Refresh được coalesce thành một Future; sau 401 chỉ replay GET một lần; write không replay để tránh lặp mutation; 403 không refresh; logout gọi Backend với refresh token rồi xóa local session |
| Hồ sơ Customer | Họ tên, số điện thoại, thành phố, địa chỉ, địa chỉ mặc định, avatar | Một phần gọi PATCH /users/me và PATCH /customers/me; field address/default và avatar local path bị từ chối | Backend không có address detail/default address; avatar cần URL HTTPS và media upload; active-session list/revoke không có endpoint |
| Notification preferences | Toggle thông báo booking, message, SMS/promotion | MockNotificationPreferencesRepository | Không có preference API trong lens-be; local toggle không đồng bộ giữa thiết bị |
| Discovery/search/filter/sort | Thành phố, price min/max, ngày rảnh, rating, experience, keyword, styles, featured/rating/price/reviews sorting | MockPhotographerRepository; filter áp lên data mock | IDs như p1 không phải UUID Backend; query Backend không hỗ trợ toàn bộ filter/sort; không có API trả giá hoặc cover trực tiếp |
| Photographer detail | Avatar/cover, mô tả, khu vực, verified, năm kinh nghiệm, giá, gói, gear/studio/insurance, portfolio, reviews, lịch | MockPhotographerDetailRepository dựa trên mock discovery directory | Backend profile, plans, portfolio, reviews, availability là resource riêng; field cover/gear/insurance/giá mặc định/deliveryDays không có trong public photographer response |
| Package picker | Chọn plan và xem giá, thời lượng, số ảnh, thời gian giao | Dữ liệu package trong detail mock | GET /photographers/:photographer_id/booking-plans đã có; cần Backend UUID và mapping plan fields; deliveryDays không có DTO |
| Chọn lịch | UI dựng các ngày và slot free/booked/busy | Mock detail/repository tạo sẵn ngày/slot | Không gọi GET /photographers/:id/availability; không được hiển thị slot mock như lịch thật |
| Tạo booking | Wizard gửi photographer/package/date/time/location/contact/note/price | BookingWizardController dùng mock detail và MockBookingRepository | Payload Mobile có contactName/contactPhone/note/price nhưng POST /bookings chỉ nhận photographer_id, booking_plan_id, location, from, to; thời gian cần ISO-8601 kèm offset |
| Booking list/detail/actions | Xem timeline/status/escrow; hủy; xác nhận đã nhận ảnh | MockBookingRepository và mockApiService | Backend có GET /bookings, GET /bookings/:id, /timeline, POST /cancel, /confirm-receipt; ID và enum mock không tương thích trực tiếp |
| Deposit/remaining payment | UI mô phỏng đặt cọc, thanh toán nốt và status payment | State/mock/local flow | Backend có POST deposit/remaining và GET payment history/status/QR; body bắt buộc idempotency_key, payment_method gateway hoặc wallet; API không nhận amount từ client |
| Gallery/download | Xem ảnh giao và lưu ảnh vào thiết bị | Mock booking/gallery; download repository chỉ GET file URL rồi ghi ảnh vào thư viện máy | Đây không phải gọi Backend gallery. Backend có gallery create/add/publish/read/download với media UUID và quyền xem |
| Reviews | Xem/ghi đánh giá và có reward coin | MockCustomerReviewsRepository | Backend có public reviews/summary và POST /bookings/:id/reviews; không có endpoint customer review list và không có reward Lens Xu trong review contract |
| Wallet/Lens Xu | Coins, cashback, redeem, refund/reward history | MockCustomerWalletRepository | Backend /wallet và /wallet/ledger là VND wallet/ledger; top-up/withdrawal/refund không tương đương coin/cashback/review reward |
| Messages | Inbox, conversation, unread, gửi text | MockCustomerMessagesRepository | lens-be không có message controller; chat service được tham chiếu ngoài repo nhưng chưa có contract được kiểm tra |

**Bằng chứng chính:** Lens-mobile/lib/core/router/app_router.dart; lib/providers/data_providers.dart; lib/features/customer/discovery/repositories/discovery_repository_provider.dart và mock_photographer_repository.dart; lib/features/customer/photographer_detail/repositories/photographer_detail_repository_provider.dart; lib/features/customer/booking_flow/models/create_booking_input.dart và controllers/booking_wizard_controller.dart; lib/features/customer/bookings/repositories/customer_booking_repository_provider.dart; lib/features/customer/bookings/repositories/delivery_media_repository.dart; lib/data/repositories/api_auth_repository.dart; lib/data/repositories/mock_customer_wallet_repository.dart; lib/data/repositories/mock_customer_reviews_repository.dart; lib/data/repositories/mock_customer_messages_repository.dart.

## 4. Creator Mobile: feature và wiring hiện tại

| Feature/screen | Nhu cầu UI/flow hiện tại | Wiring hiện tại | Finding |
|---|---|---|---|
| Auth/login/register | Email/password; đăng ký role Photographer với location/styles; xử lý pending/verified | authRepositoryProvider dùng ApiAuthRepository | POST /auth/register tạo tài khoản Photographer; tiếp theo POST /photographers/profile; login đọc GET /photographers/me và kiểm tra verification_status. Backend đăng ký mới ở trạng thái pending; chưa được xem dashboard verified |
| Session/password | Lưu token, refresh, logout, change password | Secure storage + shared interceptor; AuthRepository API-backed | Phần auth source đã có; không có reset-password/OTP/Google UI và chưa xác minh phiên live |
| Photographer profile/location | Sửa tên, phone, location, styles, description, career year, avatar | User profile update có API một phần; photographerRepositoryProvider vẫn dùng MockPhotographerDataSource cho domain profile | PATCH /users/me, PATCH /photographers/me, PATCH /photographers/me/location có contract; avatar cần upload URL; role/verification constraints phải hiển thị |
| Booking plans/packages CRUD | Tạo, chỉnh sửa, xóa gói gồm price, duration, photo count, delivery days/features | MockDatabase/MockPhotographerDataSource | Backend CRUD /photographers/me/booking-plans và public GET; DTO gồm price VND, duration_minutes, photo_count, retouched_photo_count, features; update có is_active; không có deliveryDays |
| Booking requests/list | Nhóm pending/accepted/active/completed, xem booking detail | BookingRepositoryImpl(MockBookingDataSource) | GET /bookings có pagination/filters và response role-aware; Backend IDs UUID, status enum khác; Mobile có collaboration fields không nằm trong response contract |
| Accept/reject | Chấp nhận hoặc từ chối yêu cầu | Mock booking state transition | POST /bookings/:id/accept và /reject; reject yêu cầu reason; accept theo use case yêu cầu deposit đã thanh toán và slot còn hợp lệ |
| Start/complete shoot | Đánh dấu bắt đầu và hoàn tất buổi chụp | Mock booking state transition | POST /start: accepted → in_progress; POST /complete-shoot: in_progress → shot; POST /complete và /confirm-receipt complete phần sau của lifecycle | Không gộp start, shoot complete, final order complete thành một local state; điều kiện payment/gallery áp dụng |
| Calendar/availability | Lịch 7 ngày với recurring weekly intervals, 30 phút, bận cả ngày/khung giờ | MockAvailabilityRepository | Backend có GET /calendar/me, GET public availability, POST/DELETE blocked-times. Chưa thấy API lưu tuần lặp lại. Block API có thể ảnh hưởng pending bookings và trả 409 nếu không dùng decline_pending phù hợp |
| Portfolio | Public profile, editor, uploads/thumbnails/stats | Mock profile/database and photo URLs | Backend có portfolio CRUD/items/reorder cùng media upload; cần map portfolio UUID/media UUID, upload permissions và response URLs |
| Booking delivery gallery | Upload ảnh theo booking, preview, publish, Customer download | Mock booking/gallery arrays | Backend có POST gallery, upload-url, complete-upload, add gallery items, publish, GET/download; Customer chỉ xem gallery đã publish |
| Reviews/ratings | Danh sách đánh giá và số liệu | MockReviewDataSource/ReviewRepositoryImpl | GET public reviews/rating-summary và PUT /reviews/:id/reply tồn tại; cần xác nhận UI có reply action thực sự hay chỉ read. Review policy thuộc Backend |
| Wallet/withdrawal | Số dư, giao dịch, yêu cầu rút tiền | MockWalletRepository | Backend GET /wallet, /wallet/ledger, POST /wallet/withdrawals; body gồm amount, reason, payout_destination bank_code/account_number/account_name và idempotency_key; min 10.000 VND |
| Storage/subscription | Quản lý gallery, gói/dung lượng và nâng cấp | MockStorageRepository | Backend có subscription plans/me/usage/history/create/cancel; Storage Mobile chưa map entitlement/usage hoặc SKU sang API |
| Achievements | Rank, badges, chỉ số | MockAchievementDataSource | Backend public GET /ranks và /badges; photographer profile trả rank/badges; có thể nối screen hiện tại, không cần màn hình mới |
| Messages | Conversation list/thread, read/send | MockMessageDataSource | Không có API trong lens-be; Chat service ngoài checkout chưa được contract-audit |
| Assistant/FAQ | Bật trợ lý, chỉnh FAQ/rules, trạng thái theo conversation | MockAssistantDataSource | Không thấy API assistant trong lens-be; Chat service chưa được kiểm tra |
| Notifications/security settings | Notification toggles, active sessions, 2FA/security | MockSettingsDataSource và local toggles | Backend có change password/logout nhưng không có notification preference/session listing/revoke/2FA API |

**Bằng chứng chính:** lens-creator-mobile/lib/core/router/app_router.dart; lib/providers/data_providers.dart; lib/data/repositories/api_auth_repository.dart; lib/features/photographer/availability/schedule_provider.dart, work_schedule.dart, mock_availability_repository.dart; lib/data/repositories/booking_repository_impl.dart; lib/data/datasources/mock/mock_booking_data_source.dart; features/photographer/packages, portfolio, storage, wallet, reviews, achievements, messages, assistant, settings.

## 5. Portal Web: chuỗi UI → query → service → endpoint đã thấy trong source

| Feature | UI/query | Service/client | Endpoint Backend | Điều kiện và caveat |
|---|---|---|---|---|
| Auth | Login/Signup/Google callback → useAuth | services/auth.ts → services/backend/auth.ts → lib/backend-api.ts | POST /auth/login, /auth/register; GET /keycloak/google/login, /exchange; POST /auth/refresh tự động khi 401 | response parser cần access_token/refresh_token/user và role. Token browser lưu localStorage; không dùng pattern đó cho Mobile |
| Profile/settings | ProfileSettings/AccountSettings → useProfile | services/profile.ts → identity/customers/photographers/auth service | GET/PATCH /users/me; Customer GET/PATCH /customers/me; Photographer GET /photographers/me và PATCH location/profile; POST change-password | Profile fetch swallow lỗi customer/photographer profile thành null; addressDetail rỗng; notification preference hardcoded; AccountSettings 2FA là local state |
| Discovery | Photographers page → usePhotographers | services/photographers.ts → photographerApi | GET /photographers; list all pages bằng limit/offset. Featured → GET /photographers/top-rated | UI filter controls phần lớn lọc client-side trên danh sách đã tải; request đang gửi pagination, không chuyển mọi filter sang Backend. Search DTO chỉ hỗ trợ location/keyword/min_rating |
| Photographer public profile | PhotographerProfile → usePhotographer, reviews/achievements hooks | photographers service ghép profile + plans + portfolio items; reviews/achievements services | GET /photographers/:id; GET booking-plans; GET portfolios và portfolio detail; GET reviews/rating-summary; GET /ranks, /badges; availability riêng | Giá được tính min từ booking plans; cover chọn portfolio image đầu tiên rồi fallback avatar. Đây là mapping từ dữ liệu API thật, không phải field cover/price trong profile response |
| Booking tạo | BookingFlow → useAvailability/usePhotographer/useCreateBooking/useMyProfile | services/photographers.ts và services/bookings.ts | GET /photographers/:id/availability; GET booking plans; GET /users/me; POST /bookings | Web tính from/to theo timezone Việt Nam và duration của Backend plan trước khi gửi. Request Backend không nhận contact/note/price fields |
| Booking list/actions | Customer Bookings, Creator Overview/Bookings → useMyBookings/useIncomingBookings | services/bookings.ts + services/dashboard.ts | GET /bookings; GET /bookings/:id; POST accept/reject/start/complete-shoot/cancel/confirm-receipt; timeline API có trong service | Mapping trạng thái được viết riêng theo payment history; cancel/reject gửi reason cố định trong facade. getMyEarnings trả null vì không có API báo cáo thu nhập |
| Payment | Deposit/Payment → usePayDeposit/usePayBooking/usePaymentStatus/usePaymentQr | services/bookings.ts → paymentApi | POST deposit/remaining; GET /payments/:id, /qr, /bookings/:id/payments | Query hook poll status mỗi 5 giây khi pending; payment create truyền idempotency key và payment_method. Không phải bằng chứng giao dịch production đã hoàn tất |
| Calendar | Photographer Availability → useMyCalendar/useCreateCalendarBlock/useRemoveCalendarBlock | services/calendar.ts → calendarApi | GET /calendar/me; POST/DELETE /calendar/blocked-times; affected-bookings preview có service | Week view trong Portal là read-only; biểu đồ dùng default 07:00–24:00 và lấy bookings/blocked ranges. API không lưu recurring weekly availability |
| Packages | Photographer Packages → useSaveMyBookingPlans | services/booking-plans.ts → bookingPlanApi | GET/POST /photographers/me/booking-plans; PATCH/DELETE /booking-plans/:id | Mapping Web gửi photo_count và retouched_photo_count bằng cùng photoCount. Khi xóa plan, service gọi DELETE; Backend chỉ xóa plan chưa có booking, plan đã dùng phải được deactivate |
| Portfolio upload | Photographer Portfolio → useUploadPortfolioImages | services/portfolio-media.ts + media-upload.ts → portfolioApi/mediaApi | portfolio list/create/add item; media upload-url, direct PUT presigned URL, complete-upload, GET media status | Web kiểm tra JPG/PNG/WebP, tối đa 100 MB và chờ ready; đây là flow tham chiếu hữu ích nhưng phải tôn trọng media visibility/ownership ở Backend |
| Booking gallery delivery | Storage/DeliveryGallery → useMyGalleries/useGallery/useUploadPhotos/usePublishGallery | services/storage.ts + media-upload.ts | booking gallery create/add/publish/read/download; media upload/complete | Customer gallery chỉ đọc được sau publish theo Backend; 403/404 bị map thành “không có gallery” ở một số đường gọi nên cần tránh che lỗi permission khi Mobile implement |
| Reviews | Public profile/Customer Reviews → useReviews/useReviewSummary/useSubmitBookingReview | services/reviews.ts → reviewApi | GET photographer reviews/rating-summary; POST booking review; PUT reply/PATCH/DELETE có service | getMyBookingReviews chủ động throw vì thiếu GET /customers/me/reviews; review screen lấy booking list để xác định flow. API public read và submit là các phần đang dùng |
| Wallet | Shared Wallet/WithdrawDialog → useWalletSummary/useWalletTransactions/useWithdraw | services/wallet.ts → paymentApi | GET /wallet, GET /wallet/ledger, POST /wallet/withdrawals | Web mapping ledger; withdrawal DTO cần destination/reason/idempotency. Top-up/refund service được khai báo nhưng không đồng nghĩa UI hiện gọi |
| Subscription/storage | Photographer Storage → useMySubscription/useSubscriptionPlans/useSubscribeToPlan/useMyGalleries | services/backend/subscriptions.ts, useStorage | GET /subscriptions/plans, /subscriptions/me; POST /subscriptions; gallery endpoints | /subscriptions/me/usage/history và cancel có service nhưng không thấy UI query hook tương ứng. StorageOverview suy quota từ mô tả/features plan và cộng gallery size, không gọi usage endpoint |
| Achievements | Photographer Overview/Achievements/Public profile → useMyAchievements/useAchievements | services/achievements.ts → catalogApi/photographerApi | GET /photographers/me hoặc /photographers/:id; GET /ranks, /badges | Rank/badges lấy từ profile + catalog; commission labels cần map theo schema Backend |
| Messages/AI/collaboration | Messages, ConversationInfo, CollaboratorDialog và assistant controls có UI/query hooks | services/messages.ts, assistant.ts, collaborations.ts | Không gọi Backend API thật; các hàm throw lỗi unsupported | UI presence không phải API integration; Portal service ghi rõ chưa có messages, AI hoặc collaboration API |

### Kết luận riêng về Web

Portal là bằng chứng source tốt cho cách ghép API và một số mapping thực tế: booking plan duration → from/to, payment idempotency/polling, gallery upload lifecycle, profile fields và calendar blocked ranges. Nhưng không coi Web là contract authority: Web có local-only controls, endpoint declarations chưa được UI gọi, fixed cancellation/rejection reason, unsupported services, và mapping có thể che một số lỗi 403/404.

## 6. Ma trận feature-to-API chi tiết và hướng xử lý

### Customer Mobile

| Feature/flow | UI và wiring Mobile | Web reference | Backend endpoint/contract đã xác minh trong source | Tương thích, gap và owner đề xuất |
|---|---|---|---|---|
| Customer register/login | LoginScreen/SignupScreen → ApiAuthRepository | Login/Signup → useAuth → auth service | POST /auth/register {role, fullname, email, password}; POST /auth/login {email,password}; response có tokens, expires_in, user | Contract cơ bản tương thích; role client phải map customer; tiếp tục nhóm C, Mobile + environment QA |
| Refresh/logout/change password | Dio/session interceptor và settings | backend-api interceptor; AccountSettings | POST /auth/refresh {refresh_token}; POST /auth/logout [refresh_token]; POST /auth/change-password {current_password,new_password,confirm_password} | Source behavior hợp lý; xác minh expiry/401 sau khi có test account. 403 phải giữ session, không clear như token expired. Mobile + QA |
| Customer profile | settings/profile UI; gọi hai patch user/customer cho field hỗ trợ | useProfile và services/profile | GET/PATCH /users/me: fullname/avatar_url HTTPS/phone_number/gender/dob; GET/PATCH /customers/me: description/preferred_styles/location | Name/phone/city dùng được; address detail/default không tồn tại. Nếu bắt buộc lưu address trên nhiều thiết bị thì Backend cần field/contract; nếu chỉ là địa điểm buổi chụp thì nhập ở booking |
| Avatar | UI chọn ảnh local | Web không có trường profile avatar upload flow trong Profile form | POST /media/upload-url, PUT upload URL, POST /media/complete-upload rồi PATCH /users/me {avatar_url} | Backend có thể hỗ trợ qua media pipeline nhưng Mobile updateAvatar hiện từ chối localPath. Nhóm C sau khi chốt URL/visibility; không gửi local path vào avatar_url |
| Notification preferences | Các toggle settings, MockNotificationPreferencesRepository | Web profile trả fixed defaults, không gọi API | Không có GET/PATCH preferences trong controller lens-be | Thiếu contract rõ. Nhóm B nếu giữ toggles: đề nghị GET/PATCH /users/me/notification-preferences với event/channel preference có persisted response; validate role, channel consent và cross-device readback |
| Discovery query | Search/filter/sort; provider MockPhotographerRepository | usePhotographers → GET /photographers; listTopRated → GET /photographers/top-rated | Search DTO: limit 1–100, offset, location, keyword, min_rating; public list response page {items,total,offset,limit} | Nhóm C cho supported query. min/max price, availableDate, styles, experience, server sort không có query contract. Không filter toàn bộ dataset từ page đầu rồi giả định kết quả đầy đủ |
| Discovery display fields | Photographer cards | Web composes plans and portfolio resources | Photographer response: id, fullname, avatar_url, styles, career start year, verification/location/available/description/rating/rank/badges | Không có coverImageUrl hoặc price trong response. Có thể chọn ảnh portfolio thật làm cover và tính min plan price nếu Product chấp thuận; không lấy mock cover/price. Nhóm D cho fallback/copy |
| Photographer detail resources | Detail tabs: about, gear, packages, portfolio, reviews | profile page composes multiple hooks/services | GET /photographers/:id; GET /photographers/:id/booking-plans; GET /photographers/:id/portfolios; GET /portfolios/:id; GET reviews/rating-summary; GET availability | Nhóm C cho các resource có thật. Gear/studio/insurance/delivery SLA chưa có contract. Profile response is_verified/verification_status phải được map, không suy từ mock boolean |
| Package read | package picker | Web listPhotographerBookingPlans | GET /photographers/:photographer_id/booking-plans; plan có price, duration_minutes, photo_count, retouched_photo_count, features, is_active theo response | Map package UUID; Customer model cần quyết định photo_count hay retouched count hiển thị. Không có deliveryDays. Nhóm C + D cho field thời gian giao |
| Availability selection | DateStrip/TimeSlots, booking wizard | useAvailability → GET availability with from/to; Web converts continuous UTC ranges to Vietnam half-hour slots | GET /photographers/:id/availability?from=&to= returns free time ranges | Nhóm C cho slot thật. Mobile phải tạo slot từ intervals, timezone +07:00 và plan duration; filter date/availability không thể dùng fixture list |
| Booking create | Wizard thu package/date/time/location/contact/note/price | useCreateBooking → services/bookings.ts | POST /bookings {photographer_id UUID, booking_plan_id UUID, location, from, to}; timezone-aware ISO; Backend derives price/deposit from selected plan/business rules | Partial. Contact name/phone/note/price không được nhận; plan UUID phải tồn tại; duration lấy plan; hỏi Product liệu contact đọc từ profile hay cần snapshot. Nhóm D trước, sau đó C |
| Booking list/detail/timeline | Booking list/detail/progress/cancel/confirm | useMyBookings and mapping service | GET /bookings?limit&offset&status&from&to; GET /bookings/:id; GET /bookings/:id/timeline | Nhóm C. Use token role/ownership; mock ids/statuses không map trực tiếp. Handle page, 401, 403, 404, 409 distinctly |
| Customer cancel | CancelBookingDialog | useCancelBooking → cancelBooking | POST /bookings/:id/cancel {reason}; pending/accepted may cancel subject to business rules | Mobile needs collect reason or approved reason policy; cannot send empty body. Backend cancellation may affect payment/refund separately. Nhóm C, UI small update |
| Customer confirm receipt | Booking detail/gallery | useConfirmReceipt | POST /bookings/:id/confirm-receipt, allowed after shot with payment/gallery policy | Backend lifecycle uses shot → completed; not generic released. Need display/eligibility mapping; group with state decision |
| Deposit | DepositScreen and fixed local deposit amount | usePayDeposit | POST /bookings/:id/payments/deposit {idempotency_key, payment_method? gateway|wallet}; GET payment/QR/history | API does not receive amount; Backend computes amount. The mock 30% must be checked against backend current rule. No production transaction. C after D, sandbox required |
| Remaining payment/status | PaymentScreen local flow | usePayBooking, status and QR polling | POST /bookings/:id/payments/remaining same idempotency/payment_method; GET /payments/:id, /qr, /bookings/:id/payments | Map asynchronous pending/paid state; do not set booking state from local button. Payment provider webhook is server-side. C after payment flow decision |
| Gallery read/download | DeliveryGalleryScreen, local downloader | Web GET gallery/download; storage service | GET /bookings/:id/gallery and /gallery/download; Customer access only after published | Downloading direct image URL to device is not gallery API. C after booking IDs and authorization; render unavailable/pending distinctly |
| Review read/submit | ReviewsScreen/detail tabs, local review/reward | useReviews/useReviewSummary/useSubmitBookingReview | GET /photographers/:id/reviews, /rating-summary; POST /bookings/:id/reviews; edit/delete routes exist | C for read/write; review must satisfy Backend booking eligibility and DTO rating dimensions. No /customers/me/reviews; no Lens Xu reward endpoint. Reward decision D |
| Wallet/rewards/refund | WalletScreen with coins, rewards, refund entries | Web wallet maps VND ledger | GET /wallet; GET /wallet/ledger; POST topups/withdrawals; POST booking refund request | Not compatible as a single model. Backend wallet is VND; coin/redeem/cashback policy absent. D for model, then C for any actual refund flow |
| Messages | Conversations/thread/send/read UI | Portal hooks call throw-only service | No messaging controller in lens-be source; external Chat checkout referenced | Blocked/unverified. Need Chat service OpenAPI/auth/realtime contract before integration |

### Creator Mobile

| Feature/flow | UI và wiring Mobile | Web reference | Backend endpoint/contract đã xác minh trong source | Tương thích, gap và owner đề xuất |
|---|---|---|---|---|
| Photographer onboarding | Login/register flow includes styles/location | Portal auth register exists; no same Mobile onboarding required | POST /auth/register role photographer; POST /photographers/profile {location, styles}; GET /photographers/me returns verification status | Source integrated; pending is expected until review; retain gate. Verify authorized account and role claims in QA |
| Photographer profile | Settings/profile/public profile | useDashboard profile calls GET /photographers/me + GET /users/me; update routes via profile services | GET/PATCH /users/me; GET/PATCH /photographers/me; PATCH /photographers/me/location; optional status endpoint | Partial: profile provider for Creator domain remains mock. Supported description/styles/started_career_at/location should map; rich cover/gear fields not supplied |
| Package create/update | EditPackageScreen fields include deliveryDays/photo/duration/price/features | Packages → useSaveMyBookingPlans → CRUD service | POST /photographers/me/booking-plans; PATCH /booking-plans/:id; DTO requires name, price, duration_minutes, photo_count, retouched_photo_count; PATCH supports is_active | Core CRUD available; deliveryDays missing. Mobile needs map fields; deletion is allowed only if no booking, otherwise deactivate. D for delivery semantics |
| Package delete/deactivate | Remove package UI | Web save function may issue DELETE for removed entries | DELETE /booking-plans/:id; Backend documents delete only plans without bookings, used plans must be disabled | Do not treat disabled vs deleted alike. Use is_active=false where bookings reference plan, or ask Product what remove means. C + business policy |
| Incoming booking list | Booking tabs/detail/KPIs | Overview/Bookings → useIncomingBookings → GET /bookings | GET /bookings with pagination/status/from/to, actor scoping | C, but model/status adapter needed. Ensure no customer list leakage; consume total/offset |
| Accept booking | Request detail accept action | updateBookingStatus → POST /accept | POST /bookings/:id/accept, Photographer role; pending → accepted; use case requires paid deposit and slot not blocked/occupied | State rules must be reflected in action enabled/disabled. C after status/Payment D review |
| Reject booking | Reject dialog/action | Web sends fixed reason through POST /reject | POST /bookings/:id/reject {reason}; Photographer role; pending → rejected | Mobile must collect or generate approved reason; use error/409 for stale request. C |
| Start/complete shoot | Booking timeline/actions | Web maps held → /start, completeShoot → /complete-shoot | POST /start accepted → in_progress; POST /complete-shoot in_progress → shot; POST /complete and /confirm-receipt complete later lifecycle | Do not map start, shoot complete, final order complete into one local state. Backend full payment and gallery publication conditions apply for final completion |
| Calendar read/block | Weekly calendar and day schedules | Portal reads /calendar/me; blocks day/range | GET /calendar/me?from&to; POST /calendar/blocked-times accepts date or from/to, reason, decline_pending; DELETE blocked-time id; affected preview GET | C for date range and blocked times. If overlapping pending requests exist, request may fail with 409 unless explicitly decline; show confirmation before action |
| Recurring weekly availability | WorkSchedule.weekly editor | Portal WeekScheduleEditor is read-only and uses Backend default 07:00–24:00 | No weekly-template GET/PATCH found; availability API returns open ranges derived from bookings/blocked windows | D. If recurring hours are essential, Backend needs timezone/effective dates/weekly intervals/exception contract; if not, adapt UI to date-specific block management |
| Portfolio CRUD and media | PortfolioScreen/editor, add/delete/reorder photos | Portfolio route uploads via media and adds item to album | POST/GET /photographers/me/portfolios; public GET; portfolio item add/update/delete/reorder; media upload-url/complete; GET/delete media | C with media lifecycle and UUID mapping. DTO allows only supported MIME, 100MB size ceiling, visibility/ownership. Do not make portfolio success local before all response steps |
| Booking gallery delivery | DeliveryGalleryScreen uploads, adds items, publishes | Web storage gallery flow | POST /bookings/:id/gallery; POST upload URL/complete; POST /gallery/items {media_id}; POST /gallery/publish; GET/download | C; depends on booking lifecycle and ready media. Customer view is denied until published. Keep portfolio gallery distinct from booking delivery gallery |
| Reviews and rating | ReviewsScreen lists profile reviews; check current UI for reply action before implementing | Public profile uses reviewApi; service supports reply but UI may only list | GET reviews/rating-summary; PUT /reviews/:feedback_id/reply {reply}; Backend review policy applies | C for read; only add reply if current screen already has action or Product approves scope. Do not conflate public read with reply integration |
| Wallet withdrawal | WalletScreen and mock withdraw action | Shared Wallet → GET wallet/ledger, POST withdrawal | POST /wallet/withdrawals {amount, reason, payout_destination:{bank_code,account_number,account_name}, idempotency_key}; min amount 10,000 VND | UI currently lacks authoritative API mapping/fields. Need secure destination entry and idempotency, no actual production withdraw for testing. C after form/contract alignment |
| Subscription and storage | StorageScreen, storage plan cards/usage | Portal uses plans/current/create and galleries; has unused usage/history/cancel services | GET plans/me/usage/history; POST /subscriptions {photographer_plan_id,idempotency_key}; POST cancel | C for API mapping, but verify plan IDs, status, entitlement/storage units and payment completion lifecycle before showing active. Existing MockStorageRepository must not mask API errors |
| Ranks/badges | Achievements screen | useMyAchievements + catalog/profile services | GET /ranks; GET /badges; GET /photographers/me includes earned rank/badges | C; model adapter. Rank catalog alone is not earned state; use own profile for photographer current rank/badges |
| Messages/assistant | Inbox/chat and FAQ assistant editor | Portal respective hooks call unsupported errors | No message/assistant controller in lens-be; Chat service external | Blocked/unverified; obtain source/OpenAPI/auth and realtime behavior |
| Notification/security settings | Mock toggles, two-factor/session controls | Portal prefs hardcoded; 2FA local | No preference/session/2FA route in lens-be; change-password/logout exist | B if retained. Do not report local toggle as saved notification preference |

## 7. Nhóm A — Điều chỉnh Mobile để phù hợp API hiện có

### A1. Discovery v1 chỉ gửi các filter Backend hỗ trợ

- Screen: Customer discovery/filter/sort.
- Điều chỉnh: tiếp tục giữ keyword, khu vực và minimum rating; dùng top-rated endpoint cho feed nổi bật. Không gửi giá, ngày rảnh, style, years of experience hoặc sort mode như thể Backend đã lọc các trường đó. Có thể giữ UI filter nâng cao ở trạng thái chưa khả dụng hoặc ẩn trong v1 sau khi Product duyệt.
- Trải nghiệm sau chỉnh: danh sách được lọc nhất quán trên toàn bộ kết quả Backend; không loại nhầm item do chỉ tải một page rồi filter cục bộ.
- API dùng: GET /photographers?limit&offset&location&keyword&min_rating; GET /photographers/top-rated.
- Vì sao Mobile: Backend đã có search cơ bản; bổ sung nhiều kiểu sort/filter chỉ để giữ control mock làm tăng contract và truy vấn cần hỗ trợ.
- Ảnh hưởng: giảm khả năng lọc trong v1. Nếu các filter là acceptance requirements, chuyển sang nhóm B để bổ sung contract thay vì âm thầm bỏ.

### A2. Không cần trường cover/giá giả trên discovery

- Screen: cards và Photographer detail.
- Điều chỉnh đề xuất nếu Product chấp thuận: lấy avatar_url làm ảnh nhận diện; nếu cần cover thì dùng một item portfolio thật theo quy tắc chọn ảnh thống nhất. Giá hiển thị từ booking plan thật, có thể biểu đạt “từ” giá thấp nhất trong các plan đang active; nếu không có plan thì không hiển thị giá.
- API dùng: photographer profile + booking plans + portfolio endpoints.
- Vì sao Mobile: những giá trị này có thể lấy từ resource Backend đã có, không cần thêm duplicate profile fields nếu quy tắc tổng hợp phù hợp.
- Ảnh hưởng: tăng số request/ghép resource; nếu Product yêu cầu cover được chọn riêng hoặc price range tính theo rule cụ thể, cần Backend field/contract hoặc quyết định Product. Không dùng mock ảnh/giá/lịch.

### A3. Profile address không được báo thành công khi Backend không lưu

- Screen: Customer profile/settings.
- Điều chỉnh: chỉ cho lưu fullname/phone/location/fields API hỗ trợ. Nếu địa chỉ chi tiết chỉ là nơi chụp, nhập trong booking location; không đưa vào profile đã “lưu” nếu chỉ nằm trong secure session/local cache.
- API dùng: PATCH /users/me và PATCH /customers/me.
- Vì sao Mobile: Backend profile DTO không nhận địa chỉ chi tiết hoặc saveAsDefault.
- Ảnh hưởng: mất tiện ích điền sẵn địa chỉ giữa thiết bị. Nếu địa chỉ mặc định là yêu cầu nghiệp vụ, chuyển yêu cầu sang nhóm B.

### A4. Package đã được booking thì dùng deactivate, không xóa vật lý

- Screen: Creator Packages.
- Điều chỉnh: nếu gói có booking liên quan, action “xóa” nên diễn giải thành ngừng bán/is_active=false; chỉ gọi DELETE với gói chưa được dùng.
- API dùng: PATCH /booking-plans/:id {is_active:false} hoặc DELETE khi Backend cho phép.
- Vì sao Mobile: Backend có rule bảo vệ booking tham chiếu và hỗ trợ deactivate.
- Ảnh hưởng: gói ngừng bán vẫn tồn tại trong lịch sử/booking snapshots; cần UX phân biệt “ngừng nhận booking mới” với “xóa chưa từng dùng”.

## 8. Nhóm B — Contract cần Backend bổ sung nếu Product giữ các yêu cầu tương ứng

Các đề xuất dưới đây là contract thảo luận, không phải endpoint hiện có.

### B1. Notification preferences

- Màn hình: Customer và Creator settings.
- Gap: có event delivery/outbox nhưng không có API CRUD preference.
- Đề xuất: GET /users/me/notification-preferences; PATCH cùng resource với danh sách event/channel. Request có thể gồm event key, push/email/SMS/in-app boolean và version/update timestamp; response trả canonical settings đã lưu.
- Quy tắc cần chốt: event nào theo role, channel nào triển khai thật, consent/opt-out, default mới, migration default hiện có, đồng bộ đa thiết bị.
- Auth: Bearer token, actor chỉ đọc/sửa preference của chính mình.
- Acceptance: patch xong GET trả cùng giá trị từ session/thiết bị khác; validation từ chối channel không hỗ trợ; không báo “đã lưu” nếu API lỗi; Customer không đọc được settings Photographer.

### B2. Session management và 2FA

- Màn hình: Customer/Creator account security nếu các controls được giữ.
- Gap: source có logout/change-password; không có API list/revoke session hoặc 2FA enrollment/status.
- Đề xuất: session listing có session_id, device/client, created_at, last_active_at, current flag; revoke session id và revoke all except current. 2FA cần contract riêng dựa trên Keycloak, gồm enroll/challenge/verify/disable và recovery policy.
- Quy tắc cần chốt: API do lens-be proxy hay Keycloak trực tiếp; current refresh token rotation/revocation semantics; có yêu cầu revocation access token không.
- Auth: Bearer + self-session only; yêu cầu step-up auth cho revoke/2FA nếu policy cần.
- Acceptance: revoked refresh token không thể refresh; current session action được xác định rõ; 2FA state đọc lại từ server; các thiết bị khác cập nhật trạng thái; không mô phỏng toggle local.

### B3. Photographer collaboration và chia booking revenue

- Màn hình: Creator booking detail/invitation; Customer review flow hiển thị nhiều Photographer.
- Gap: lens-be hiện mô hình một photographer chịu trách nhiệm; không thấy collaboration invite/response/share allocation entity hoặc route.
- Đề xuất contract ở mức thảo luận: mời participant vào booking; response accepted/declined; danh sách participants với role/status/share_percent; cancellation/removal; lịch sử thay đổi; rule phân bổ payout.
- Request/response cần có: booking UUID, photographer UUID, share_percent, status, inviter, timestamps; response canonical participants và tổng phần trăm được phép.
- Quy tắc cần chốt: tổng share, quyền accept/cancel, payment/refund khi một bên từ chối, customer consent, trách nhiệm shoot/gallery/review, payout/escrow.
- Auth: owner Photographer mời; Photographer được mời chỉ phản hồi lời mời của mình; Customer chỉ đọc participants liên quan booking.
- Acceptance: không vượt tổng share đã chốt; transition idempotent; booking cancellation/refund và ledger giữ đúng tổng tiền; không có participant ngoài booking xem dữ liệu.
- Tác động: cần đồng bộ Web/Backend/Mobile và sửa API response/bookings nếu collaboration vẫn là feature bắt buộc.

### B4. Weekly recurring availability nếu không đổi Mobile UX

- Màn hình: Creator WorkSchedule/weekly editor.
- Gap: Backend chỉ thấy date-range availability và blocked-times; chưa có recurring template persistence.
- Đề xuất: API đọc/cập nhật weekly rules theo timezone, weekday, from/to, effective date, exception dates; availability query nên được tính từ template + blocked ranges + bookings.
- Quy tắc cần chốt: timezone cố định hay theo Photographer, ngày bắt đầu áp dụng, cập nhật template có ảnh hưởng booking đã giữ không, slot length/duration.
- Auth: Photographer owner; public availability chỉ đọc kết quả đã áp dụng.
- Acceptance: save/reload giữ đúng tuần; public availability không hiển thị slot nằm ngoài recurring hours; booking đang tồn tại vẫn giữ ưu tiên; thay đổi không tự xóa booking.
- Nếu Product thấy date-specific blocked time đủ cho v1, dùng nhóm A để giản lược editor; không tự chọn thay Product.

### B5. Rich discovery fields, package delivery time, customer address hoặc reward wallet

- Đây là các yêu cầu tùy thuộc quyết định Product, không mặc định cần thêm API.
- Nếu filter style/price/experience/date là tiêu chí bắt buộc: bổ sung query fields với semantics/pagination rõ ràng và response price/availability source; acceptance phải xác nhận Backend filter trên toàn dataset, không chỉ page client.
- Nếu cover được Photographer chọn riêng: thêm cover_media_id/cover_url theo quyền media; nếu lấy portfolio item đầu tiên là đủ thì không cần API mới.
- Nếu delivery SLA quan trọng: thêm delivery_days vào booking plan DTO/response và booking snapshot để lịch sử không thay đổi khi plan được chỉnh.
- Nếu address mặc định cần tồn tại đa thiết bị: thêm field address/location semantics và DTO/validation cho Customer; không dùng location hiện tại như địa chỉ chi tiết.
- Nếu Lens Xu là tiền thưởng/loyalty: xác định currency/unit, wallet ledger type, redemption cap, earn/refund rules và idempotency; không nhét coin vào VND wallet hiện tại.
- Acceptance cho từng API cần có field/validation/error status, permission, pagination, versioning và backward compatibility cho Web.

## 9. Nhóm C — Chỉ cần tích hợp Mobile/mapping, không cần sửa API hoặc UI lớn

Các mục này có controller/DTO/logic tương ứng trong lens-be và flow Mobile đã tồn tại:

1. Auth login/register/refresh/logout/change password: source đã nối; còn thiếu cấu hình môi trường/tài khoản QA và live authenticated verification.
2. GET profile / PATCH supported profile fields; map Backend response thay vì chỉ cập nhật session cache. Customer address/default và avatar path không thuộc nhóm này.
3. Photographer search/top-rated/detail với query/response hiện có.
4. Public booking-plan read và Creator booking-plan CRUD fields tương ứng.
5. Customer booking create/list/detail/actions sau khi chốt state/request decisions; DTO mapping là Mobile task.
6. Customer availability slot generation từ Backend time ranges, timezone-aware.
7. Creator calendar range/bookings/blocked-times/preview/remove; handle 409 and decline_pending.
8. Portfolio/media upload, complete, ready status, portfolio item create/delete/reorder.
9. Booking gallery create/add/publish/read/download theo permissions.
10. Public review list/summary, Customer submit review theo eligibility, Photographer reply nếu screen có action.
11. Payment deposit/remaining/status/QR, wallet summary/ledger/withdrawal, refund request endpoints; sandbox and approval required before money-flow validation.
12. Subscription plans/current/usage/history/cancel and Creator ranks/badges; map Backend entitlements/IDs rather than mock tiers/catalog.
13. Customer recommendations via GET /customers/me/recommendations có thể cấp dữ liệu cho Discovery đã có; đây không phải filter tự do và cần profile preference thật.

## 10. Nhóm D — Cần Product/Team quyết định trước code

| Câu hỏi | Phương án | Tác động và Trade-off | Câu hỏi cần Product trả lời |
|---|---|---|---|
| Discovery v1 cần filter nào? | Giữ keyword/location/rating; hoặc yêu cầu Backend hỗ trợ price/style/experience/availability/sort | Giản lược v1 giảm độ chính xác tìm kiếm; bổ sung API tăng query/index/response contract và phải đồng bộ Web | Những filter nào là acceptance requirement của mobile release đầu? |
| Giá/cover/profile fields | Giá tối thiểu tổng hợp từ plans; cover dùng portfolio; hoặc Backend trả field rõ ràng | Tổng hợp từ resources sẵn có không cần field duplicate nhưng tăng request và cần quy tắc ổn định; field riêng tốn API/model nhưng rõ semantics | Giá “từ” có được tính bằng plan active thấp nhất? Cover có được chọn tùy ý không? Gear/insurance có còn là dữ liệu bắt buộc? |
| Booking contact/note | Dùng thông tin customer profile và booking location; hoặc Backend lưu snapshot contact/note trên booking | Dùng profile giảm DTO nhưng thay đổi profile có thể ảnh hưởng lịch sử; snapshot giữ booking record nhưng thêm validation/privacy | Photographer cần contact/name/note snapshot ngay khi nhận request không? |
| Booking state/payment ordering | Theo Backend pending → deposit → accepted → in_progress → shot → completed; hoặc đổi Backend nếu business muốn khác | Backend enforce accept sau deposit, payment và booking state là hai domain; enum Mobile hiện gộp confirmed/held/released | Deposit phải trả trước khi Photographer accept như source Backend, hay accept trước rồi mới đặt cọc? Ai hoàn tất đơn cuối cùng? |
| Booking cancellation/rejection | Bắt lý do; hoặc reason mặc định do policy | Bắt lý do tăng friction nhưng có audit trail; mặc định ngắn tiện hơn nhưng ít thông tin | Customer/Photographer có cần lý do bắt buộc và hiển thị cho bên kia không? |
| Timezone và duration | Backend plan duration tính from/to; timezone theo Asia/Ho_Chi_Minh | Tính duration theo plan đúng contract; nếu package cho phép thời lượng linh động phải mở rộng request | Vùng thời gian app mặc định là Việt Nam? Có booking cross-timezone không? |
| Weekly availability | Giữ lịch lặp → bổ sung Backend API; hoặc dùng date-specific blocked time | Recurring biểu đạt lịch thật tốt nhưng cần rule hiệu lực/exceptions; block-only đơn giản hơn nhưng phải chỉnh từng ngày | Weekly hours là contract chính thức hay chỉ là tiện ích UI? |
| deliveryDays/photo count | Bổ sung delivery_days và snapshot; hoặc bỏ field nếu chỉ hiển thị phụ | Có SLA rõ ràng nhưng cần lưu lịch sử; bỏ field làm giảm thông tin về cam kết giao ảnh | Thời gian giao ảnh có bắt buộc để khách chọn Photographer/plan không? “Photo count” là ảnh đã retouch hay tổng ảnh? |
| Lens Xu/wallet/reward | Giữ Lens Xu với ledger/currency riêng; hoặc thay bằng VND-only wallet | Loyalty có thể tạo retention nhưng cần earn/redeem/refund/expiry rules; dùng VND wallet đơn giản nhưng đổi UX | Coins là tiền có thể quy đổi, điểm loyalty hay mock? Có reward sau review không? |
| Collaboration/share | Giữ và yêu cầu Backend contract; hoặc hoãn khỏi mobile flow | Giữ cần sửa booking, auth, gallery, review và settlement; hoãn làm mất multi-photographer flow nhưng phù hợp API hiện có | Collaboration có thuộc MVP và cần chia payout thực không? |
| Notification/security/chat | Làm API preferences/session/2FA; hoặc chỉ để server policy và hoãn controls; chat lấy contract service riêng | Bổ sung API có security/privacy obligations; hoãn controls giữ UI gọn nhưng mất tùy chỉnh; Chat không thể suy từ lens-be | Những controls nào cần MVP? Ai sở hữu Chat service/source/OpenAPI? |

## 11. Dependency map và thứ tự triển khai

### P0 — Integration gate

| Hạng mục | Dependency | Owner | Điều kiện hoàn thành |
|---|---|---|---|
| Chọn environment và cung cấp API_BASE_URL khi build/run cả hai app | Origin đã được bạn cung cấp; cần xác định môi trường test phù hợp và tài khoản QA | Mobile/DevOps/QA | Cả app khởi tạo Dio bằng HTTPS URL thật; login customer và verified photographer được xác nhận trên environment QA; không đưa credentials vào repo |
| Xác minh cấu hình Portal production | VITE_BACKEND_API_URL phải được truyền lúc build; Deployment docs hiện không nhất quán với Dockerfile | Web/DevOps | Build artifact có origin đúng; browser network xác nhận Portal dùng Backend API; MSW/relative URL không che lỗi |

Không gán P0 cho mọi feature chưa tích hợp. P0 trên đây chỉ là điều kiện để kiểm chứng bất kỳ flow API thật nào.

### P1 — Core booking

| Thứ tự | Flow | Phụ thuộc trước | Owner | Hoàn thành khi |
|---|---|---|---|---|
| 1 | Auth/session/profile supported fields | P0, role mapping và token expiry | Mobile | Login/refresh/logout/profile/change-password xử lý đúng response, 401/403 và session restore |
| 2 | Customer discovery/detail/plans | Auth không bắt buộc cho public; UUID resources | Mobile, Product cho filter/display decisions | Cards/detail chỉ dùng Backend data; pagination/loading/empty/error không fallback thành mock |
| 3 | Customer availability + booking create/list/detail | Plans, package UUID, timezone, state/request decisions | Mobile + Product | Tạo booking bằng plan thật; GET list/detail phản ánh status; duplicate/slot conflict/403 được hiển thị đúng |
| 4 | Creator plans + booking request actions | Verified Photographer; state/payment decision | Mobile | CRUD theo ownership; accept/reject/start/complete-shoot theo đúng transition và reason |
| 5 | Calendar blocks + delivery media/gallery | Booking thật; media permissions; calendar overlap policy | Mobile; Backend nếu chọn weekly | Block/reload calendar; upload ready media; publish; Customer chỉ xem sau publish |

### P2 — Post-booking and enhancements

| Feature | Dependency | Status |
|---|---|---|
| Reviews/ratings | Booking completed/eligibility and rating dimensions | API source available; reward decision blocked |
| Payment/wallet/refund | Payment sandbox, provider, idempotency, fee/escrow/reason/destination rules | API source available; no production transactions |
| Subscription/storage | Plan product/entitlement/usage semantics | API source available; do not treat plan purchase accepted as active before backend/payment status |
| Achievements | Photographer profile + rank/badge catalog | Low dependency; API read mapping |
| Reports/OTP/Google auth | Product requirement and UI flow | API exists but Mobile has no matching flow |
| Notification preferences/session controls | Product/security decision and Backend contract | Blocked under current API surface |
| Messaging/assistant | Chat service contract and auth/realtime strategy | Blocked/unverified |

## 12. Backend capability không có Mobile UI tương ứng hoặc chưa gọi

- Auth recovery và verification: POST /auth/forgot-password/send-otp, /verify, /reset; POST /auth/email/send-otp, /verify; Google OAuth GET /keycloak/google/login/callback/exchange. Mobile không có các flow này trong router/screens hiện tại. Portal có Google source flow; OTP recovery service có khai báo nhưng chưa thấy UI route.
- Customer summary/recommendations: GET /customers/me/summary và GET /customers/me/recommendations có trong Backend; Mobile chưa có consumer API. Recommendations có thể cấp data cho Discovery hiện tại, không cần tạo màn hình mới.
- User reports: POST /reports và GET /reports/me tồn tại cho user authenticated; không tìm thấy report screen/flow hiện tại trong hai app.
- Backend review edit/delete và Photographer reply API tồn tại; chỉ tích hợp edit/reply nếu Mobile UI hiện có control tương ứng.
- Subscription usage/history/cancel endpoints có trong Backend nhưng chưa thấy Mobile API consumers; Creator Storage UI đang mock.
- Admin APIs, admin routes, webhooks của payment/subscription và internal worker không thuộc phạm vi Mobile; không tính là thiếu sót mobile.

## 13. Phân loại ngoài phạm vi và chưa xác minh

- **E — OUT_OF_SCOPE:** Admin portal, Landing, admin routes, payment/subscription provider webhooks, reconciliation/worker jobs, nội bộ DB/migration; không đề xuất tạo Admin/Landing screens trên Mobile.
- **Messaging/AI:** Không có controller trong lens-be, nhưng deployment source tham chiếu Chat service ngoài checkout. Kết luận là chưa xác minh, không kết luận toàn hệ thống không có API.
- **Live auth/booking/payment:** Lượt audit này không dùng tài khoản/token và không gọi API. HTTP 200 từ public endpoint trước đây không xác nhận secured business logic, role, data ownership hoặc state transitions.
- **Portal production:** Không truy cập browser production/network trace. Local env và source deployment docs đủ để chỉ ra cấu hình mâu thuẫn nhưng không xác định Vercel artifact hiện hành.
- **Source status:** Không chạy format/analyze/test/build; đây là audit, chưa có code edit cần verify.
- **Mock IDs và dữ liệu hiển thị:** Các URLs/cover/price/availability/booking IDs trong fixture không chứng minh Backend có các giá trị tương đương.

## 14. Evidence appendix: các file và symbols quan trọng

### Lens-mobile

- Navigation: lib/core/router/app_router.dart — các Customer/auth/settings/bookings/messages/payment routes.
- Active providers: lib/providers/data_providers.dart — ApiAuthRepository nhưng MockNotificationPreferencesRepository, MockCustomerWalletRepository, MockCustomerReviewsRepository, MockCustomerMessagesRepository.
- API auth/session: lib/data/repositories/api_auth_repository.dart; lib/core/network/api_config.dart; lib/core/network/dio_client.dart; lib/core/network/session_interceptor.dart; lib/core/network/auth_session_store.dart.
- Discovery: lib/features/customer/discovery/models/filter_criteria.dart; discovery/controllers/discovery_controller.dart; discovery/repositories/discovery_repository_provider.dart; mock_photographer_repository.dart.
- Detail/booking: lib/features/customer/photographer_detail/repositories/photographer_detail_repository_provider.dart; lib/features/customer/booking_flow/models/create_booking_input.dart; booking_flow/controllers/booking_wizard_controller.dart.
- Booking/payment/gallery: lib/features/customer/bookings/repositories/customer_booking_repository_provider.dart; mock_booking_repository.dart; lib/features/customer/bookings/repositories/delivery_media_repository.dart; lib/features/customer/payments/deposit_screen.dart.
- Wallet/review/message/settings: lib/data/repositories/mock_customer_wallet_repository.dart; mock_customer_reviews_repository.dart; mock_customer_messages_repository.dart; mock_notification_preferences_repository.dart; lib/features/customer/settings/settings_screen.dart.

### lens-creator-mobile

- Navigation: lib/core/router/app_router.dart.
- Active providers: lib/providers/data_providers.dart — ApiAuthRepository; MockPhotographerDataSource; MockBookingDataSource; feature-level mock repositories.
- Auth/onboarding: lib/data/repositories/api_auth_repository.dart; domain/repositories/auth_repository.dart; features/auth/login_screen.dart.
- Booking/package: lib/data/repositories/booking_repository_impl.dart; lib/data/datasources/mock/mock_booking_data_source.dart; features/photographer/packages/edit_package_screen.dart; domain/models/models.dart.
- Calendar: features/photographer/availability/work_schedule.dart; schedule_provider.dart; mock_availability_repository.dart.
- Portfolio/gallery/storage: features/photographer/portfolio; bookings/delivery_gallery_screen.dart; storage/storage_provider.dart and mock_storage_repository.dart.
- Reviews/wallet/achievements/messages/assistant/settings: features/photographer/{reviews,wallet,achievements,messages,assistant,settings} provider/repository files.

### lens-be

- Auth/profile: src/features/api/http/auth.controller.ts; google-auth.controller.ts; user.controller.ts; customer.controller.ts; photographer.controller.ts; src/features/api/dto/auth.dto.ts; identity.dto.ts; customer.dto.ts; photographer.dto.ts.
- Search/profile response: src/features/api/http/photographer.controller.ts; src/features/api/dto/photographer.dto.ts; src/features/api/swagger/responses.ts; src/modules/photographer/photographers.query.ts.
- Plans: src/features/api/http/booking-plan.controller.ts; src/features/api/dto/booking-plan.dto.ts; src/modules/photographer/booking-plan.
- Booking lifecycle: src/features/api/http/booking.controller.ts; src/features/api/dto/booking.dto.ts; src/modules/booking/core/booking.domain.ts; booking.use-case.ts; src/shared/domain/values/booking.values.ts.
- Calendar: src/features/api/http/calendar.controller.ts; src/features/api/dto/calendar.dto.ts; src/modules/calendar/schedule.
- Media/portfolio: src/features/api/http/media.controller.ts; portfolio.controller.ts; src/features/api/dto/media.dto.ts; portfolio.dto.ts; src/modules/media/media.use-case.ts.
- Review/payment/wallet: src/features/api/http/feedback.controller.ts; payments.controller.ts; src/features/api/dto/review.dto.ts; payment.dto.ts; src/modules/feedback/review; src/modules/payment.
- Subscription/catalog: subscription.controller.ts; rank.controller.ts; badge.controller.ts; src/features/api/dto/subscription.dto.ts.
- No chat/preference/session management HTTP controller found in the inspected API module inventory.

### Lens-web/apps/portal

- API client/session: src/lib/backend-api.ts.
- Auth: src/routes/Login.tsx, Signup.tsx, GoogleAuthCallback route; src/queries/useAuth.ts; src/services/auth.ts; src/services/backend/auth.ts.
- Profile: src/routes/shared/settings/ProfileSettings.tsx and AccountSettings.tsx; src/queries/useProfile.ts; src/services/profile.ts.
- Discovery/profile: src/routes/Photographers.tsx; src/routes/PhotographerProfile.tsx; src/queries/usePhotographers.ts; src/services/photographers.ts.
- Booking/payment: src/routes/customer/BookingFlow.tsx, Bookings.tsx, Deposit.tsx, Payment.tsx; src/queries/useBookings.ts; src/services/bookings.ts; src/services/backend/bookings.ts and payments.ts.
- Creator flows: src/routes/photographer/Packages.tsx, Bookings.tsx, Availability.tsx, Portfolio.tsx, Storage.tsx; src/queries/useDashboard.ts, useCalendar.ts, useStorage.ts, useSubscriptions.ts.
- Media/reviews/wallet/achievement: src/services/media-upload.ts; portfolio-media.ts; storage.ts; reviews.ts; wallet.ts; achievements.ts; corresponding queries under src/queries.
- Unsupported services: src/services/messages.ts, assistant.ts, collaborations.ts throw errors; do not count as API integrations.
- Runtime config: apps/portal/.env key list, src/main.tsx, Dockerfile.frontend, DEPLOY.md.

## 15. Working-tree integrity and completion gate

Trước audit này, Lens-mobile đã có source changes chưa commit, file MOBILE_BACKEND_AUDIT.md và các network/auth files mới; lens-creator-mobile cũng có source/auth/session changes chưa commit. lens-be và Lens-web ở trạng thái sạch theo git status tại thời điểm kiểm tra đầu. Báo cáo mới được tạo riêng tại docs/MOBILE_BACKEND_API_COMPATIBILITY_AUDIT.md; không đụng các diff cũ.

Giai đoạn audit đã hoàn thành. Chưa sửa source, UI, Backend, API integration hoặc dependency. Các quyết định cần review trước khi code là: discovery filters/price/cover, booking state/payment order/contact snapshot, calendar recurring hours, delivery SLA, Lens Xu, collaboration, và notification/session controls. Sau khi bạn duyệt phạm vi, bước kế tiếp là triển khai từng feature theo dependency ở mục 11 và kiểm chứng trên environment QA.

