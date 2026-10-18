# lens_app

A new Flutter project.

## Getting Started

### API endpoints

Run the app with `--dart-define` values for the active environment:

```sh
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
  --dart-define=CHAT_API_URL=https://chat.example.com \
  --dart-define=NOTIFICATION_API_URL=https://notify.example.com \
  --dart-define=NOTIFICATION_SOCKET_URL=https://notify.example.com
```

`CHAT_API_URL` and `NOTIFICATION_API_URL` are optional when those services are
behind `API_BASE_URL`. `NOTIFICATION_SOCKET_URL` is also optional; when omitted,
the app uses the notification API host if configured, otherwise the API host.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
