# LENS customer web → Flutter migration map

This audit compares `Lens-web/apps/portal` (customer-facing source of truth) with
`Lens-mobile/lib` before the customer migration work.

## Feature and route map

| Web feature/screen | Web route | Mobile equivalent | Current status | Required action |
|---|---|---|---|---|
| Public photographer browse | `/` and `/photographers` | `/customer_home/discovery` | Partially migrated | Align the mobile browse hierarchy with the web editorial header, search, sort, filter, empty/error/loading states, and photographer cards. |
| Photographer profile | `/photographers/:id` | `/customer_home/photographer/:id` | Partially migrated | Keep the mobile bottom action bar, but match web tabs (`Tác phẩm`, `Giới thiệu`, `Đánh giá`) and remove invented profile-only business areas. |
| Booking flow | `/photographers/:id/book` | `/customer_home/photographer/:id/book` | Partially migrated | Implement web step semantics: package, date/time availability, contact/location, confirmation, and deposit hand-off. |
| Login | `/login` | `/login` | Present but inconsistent | Translate all copy to Vietnamese, add validation/loading/error states, and support the web demo flow. |
| Signup | `/signup` | Missing | Missing | Add a customer signup screen and route. |
| Client overview | `/client` | `/customer_home/overview` | Present but divergent | Refactor to web metrics, upcoming bookings, to-do items, nearest shoot, and discovery CTA. |
| Client booking list | `/client/bookings` | `/customer_home/bookings` | Present | Retain the stronger feature booking model and align status labels/actions with the web. |
| Booking detail | `/client/bookings/:id` | `/customer_home/bookings/:id` | Present but simplified | Add status-specific action cards, escrow summary, progress timeline, cancellation/payment hand-offs, and missing-booking state. |
| Deposit checkout | `/client/bookings/:id/deposit` | Missing | Missing | Add payment-method selection, deposit summary, hold explanation, success/error states. |
| Remainder payment | `/client/bookings/:id/pay` | Missing | Missing | Add payment methods, Lens Xu toggle/summary, and held-in-escrow success state. |
| Delivery gallery | `/client/bookings/:id/gallery` | `/customer_home/bookings/:id/gallery` | Present | Gate receipt confirmation on delivered package count and keep safe escrow messaging. |
| Client reviews | `/client/reviews` | Missing | Missing | Add pending/completed review tabs and an honest empty state; no invented review submission API. |
| Messages | `/messages` | `/customer_home/messages` + `.../messages/:id` | Present but divergent | Keep native mobile conversation navigation; add unread/search/filter behavior and mark-read semantics. |
| Wallet / Lens Xu | `/wallet` | Missing | Missing | Add a read-only mock wallet screen using the same ledger concepts as web. |
| Profile/settings | `/settings/*` | `/customer_home/more` | Partial placeholder | Add profile, account/security, notification sections and preserve mock-only behavior. |

## Reusable web patterns to carry into Flutter

- Neutral `Mist` canvas, `Snow` cards, `Pebble` hairline borders, rounded 16–24px
  cards, and pill-shaped primary/secondary controls.
- `Obsidian` as the neutral primary action and heading color; `Ember` reserved for
  the primary booking/payment CTA, ratings, and attention counts; `Lagoon` for
  earned/selected/safe states.
- Photographer cards use an image-led composition, dark bottom scrim, rating,
  featured badge, rank/style chips, avatar, city, and starting price.
- Every async surface has loading, error, empty, and success/confirmation states.
- Booking lifecycle is `awaiting_deposit → pending → confirmed → held → released`
  with `cancelled` as the terminal branch. Deposit is 30%; receipt confirmation
  is gated by the package's delivered photo count.

## Architecture findings

- `lib/features/customer/bookings/models/booking_model.dart` already contains the
  web-aligned escrow/package snapshot model, but active legacy routes also use a
  smaller `lib/domain/models/models.dart` booking model and a second provider.
- Discovery and profile each have independent mock fixtures, so names/prices and
  profile data can drift. The migration keeps repositories behind feature APIs
  and avoids importing mock data into presentation widgets.
- Several screens repeat colors, radii, status labels, and action-card styling
  instead of using the shared theme/widgets.
- The current auth screen still contains English copy and the starter widget test
  still tests a removed counter, so validation is not representative of the app.
- The web app is UI-only with MSW mock services. Flutter will remain mock-only in
  this migration; no backend/API contract is invented.

