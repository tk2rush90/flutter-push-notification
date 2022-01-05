# Flutter Push Notification

Flutter push notification test application.

See the official document from here: [https://firebase.flutter.dev/docs/messaging/usage](https://firebase.flutter.dev/docs/messaging/usage)

# firebase_messaging

The `firebase_messaging` package is required to receive push notification via firebase.

# flutter_local_notifications

The `flutter_local_notifications` package is required to display foreground notification for Android.

See more details for Android foreground notification from here: [https://firebase.flutter.dev/docs/messaging/notifications/#foreground-notifications](https://firebase.flutter.dev/docs/messaging/notifications/#foreground-notifications)

# Firebase

To use firebase features from the flutter app, need to initialize flutterfire.

Before using flutterfire, firebase cli is required.

Run `npm install -g firebase-tools` to install firebase cli.

Then, run `dart pub global activate flutterfire_cli` to activate flutterfire cli.

After activated, run `flutterfire configure` from the flutter project root directory to select a firebase project and platforms.

See details from here: [https://firebase.flutter.dev/docs/overview/#initialization](https://firebase.flutter.dev/docs/overview/#initialization)

# Backend integration

See [https://firebase.flutter.dev/docs/messaging/server-integration](https://firebase.flutter.dev/docs/messaging/server-integration) to learn how to integrate with backend.

# Other references

[https://uaremine.tistory.com/22](https://uaremine.tistory.com/22)

