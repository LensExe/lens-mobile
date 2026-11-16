# 04 — Implementation progress

Ngày cập nhật: 2026-10-24.

## Đã hoàn tất trong Mobile

- Chuẩn hóa các điểm lỗi envelope: login/register, refresh token, discovery, recommendations, wallet, review submit/history, notification preferences, gallery/payment/detail paths đã map envelope hoặc được kiểm tra lại.
- Photographer discovery map starting price và Backend style codes theo Web labels; multi-style OR, city/rating/search, price range, experience buckets, sort và URL state được triển khai. Khi lọc, tải các trang API rồi lọc/sắp xếp trước pagination 9 results để count chính xác. Viewport 320 px dùng sort icon gọn để tránh overflow.
- Lịch sử review đọc từ `GET customers/me/reviews` theo page; review submit unwrap response và cập nhật danh sách/provider/booking state.
- Notification settings tải/lưu boolean preferences bằng `GET/PATCH users/me`; có loading/error/retry và feedback thao tác.
- Avatar dùng signed media upload → complete → chờ xử lý ready → PATCH user, cập nhật `AuthSessionStore` và auth provider.
- Profile map/đọc/lưu gender và DOB (`dob`), hỗ trợ phone rỗng và date/gender controls; API fields được test.
- Wallet hỗ trợ request withdrawal theo DTO `wallet/withdrawals`, validate amount/reason/bank destination, gửi idempotency key ổn định cho từng dialog, rồi refresh balance/ledger.
- Cancellation dialog lấy preview từ Backend, hiển thị refundable estimate và admin-review flag trước khi gửi reason. Khi preview lỗi, thông báo không giả lập số tiền và vẫn cho phép gửi cancellation request, giống phương án fallback trên Web.
- Sửa test provider để lịch sử review được cung cấp qua data source kiểm soát; sửa comment cũ trong mock discovery để không còn nói REST API chưa tồn tại.
- Bổ sung fake-adapter integration tests cho auth envelope, discovery local filters/sort/price/experience, recommendations, review history, notification preferences, avatar upload, cancellation preview và withdrawal; response refresh/wallet/profile tests dùng envelope thật.

## Đã audit, giữ nguyên implementation hiện có

Booking wizard, booking list/detail/status, payment intent/status/QR, gallery/download, photographer detail/plans/portfolio/availability, chat và notification inbox/realtime đã có production repositories/screens. Chúng được đối chiếu với Web/Backend và giữ nguyên; phần E2E thật vẫn phụ thuộc các service/credentials được nêu trong blocker.

## Chưa thể hoàn thiện chỉ từ Mobile

1. Google OAuth cần Backend cung cấp callback URI/deep-link handoff riêng cho mobile.
2. Địa chỉ chi tiết/default address và quản lý/thu hồi session cần Backend endpoint/DTO.
3. Web date filter hiện không có dữ liệu (`availableDates: []`); Backend cần aggregate availability/date filter để hỗ trợ directory mà không tạo nhiều request theo từng photographer. Web có thêm “Ẩm thực”/“Kiến trúc” nhưng Backend chưa có style code tương ứng.
4. Notifications/chat cần URL/credentials của service tích hợp; real-time behavior chưa kiểm chứng.
5. Real API smoke/E2E cần test account/staging data; không chạy giao dịch tài chính thật.

## Bảo toàn working tree

Tại thời điểm audit ban đầu, cả Web, Backend và Mobile đã có thay đổi chưa commit. Những thay đổi đang tồn tại trong `Lens-mobile` ở booking detail/gallery/model, discovery screen, chat realtime, deposit và notification center được giữ nguyên; các diff đang có trong `Lens-web` và `lens-be` cũng không bị chỉnh sửa. Lượt này chỉ thêm/sửa Mobile và tài liệu trong `docs/customer-completion/`.
