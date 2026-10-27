# 06 — Test report

Ngày chạy cuối: 2026-10-24.

| Lệnh | Kết quả | Phạm vi |
|---|---|---|
| `flutter pub get` | Pass | Đồng bộ dependencies của Flutter project; lần chạy thành công sau khi cho phép Flutter ghi SDK package cache ngoài workspace. |
| `dart format` trên Dart files đã chỉnh sửa | Pass | Format repositories, providers, screens và tests; formatter không còn thay đổi sau lượt cuối. |
| `flutter analyze` | Pass — `No issues found!` | Static analysis toàn bộ Lens-mobile. |
| `flutter test test/filter_bottom_sheet_test.dart test/customer_flows_test.dart` | Pass — 10 tests | Filter sheet, customer route rendering/search/empty API states. Đã sửa sort toolbar overflow ở viewport 320 px. |
| `flutter test` | Pass — 50 tests | Toàn bộ unit/widget/API fake-adapter tests trong `test/`, gồm wallet withdrawal, discovery filters/sort, profile, cancellation preview và Customer route rendering. |
| `git diff --check` | Pass | Chạy sau cập nhật tài liệu; không có whitespace errors trong diff cuối. |

## Những gì được kiểm thử bằng test doubles

- API adapter giả lập response chuẩn `{success, statusCode, data, timestamp}`.
- Session rotation và request đồng thời; không replay write sau refresh.
- Discovery: API page/envelope, localized style/price mapping, multi-style OR, narrowed price, experience bucket, sort và pagination; filter sheet state.
- Avatar: media reservation, PUT tới signed URL, complete, polling `ready`, cập nhật user/session.
- Cancellation preview endpoint và trường số tiền/admin review.
- UI route destinations trong widget suite; discovery thử viewport 320×740, 390×844 và 430×932.

## Chưa kiểm thử

- Không có test account/credentials staging và không có môi trường backend/service test được cấu hình cho phiên này. Chưa chạy real API E2E cho booking, payment, gallery, notification hoặc chat.
- Không chạy real API test cho wallet withdrawal; request chỉ được xác minh qua adapter giả lập và widget test, không gửi yêu cầu rút tiền thật.
- Không tạo thanh toán thật, không hủy booking production và không upload dữ liệu cá nhân lên service thật.
- Google callback chưa thể end-to-end cho Mobile vì Backend dùng redirect URI frontend cố định và app không có callback handoff.
- Các fake-adapter tests chứng minh request/response mapping; chúng không chứng minh credentials, provider/storage, quyền truy cập dữ liệu thật hay external realtime services.

## Lượt kiểm thử cuối

- `flutter pub get`: Pass; dependencies resolved, 39 packages có phiên bản mới hơn nhưng bị giới hạn bởi các dependency constraints hiện tại.
- `dart format` trên 8 file discovery/repository/widget/test được thay đổi trong lượt cuối: Pass.
- `flutter analyze`: Pass, `No issues found!`.
- `flutter test`: Pass, 50 tests.
