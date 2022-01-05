import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize firebase app with current platform options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Push Notification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Push Notification'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Get firebase messaging instance
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Flutter local notification plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Android notification channel
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    // channel id
    'high_importance_channel',
    // channel title
    'High Importance Notifications',
    // channel description
    description: 'This channel is used for important notifications.',
    // importance
    importance: Importance.max,
  );

  @override
  void initState() {
    super.initState();

    _readyForNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const Center(
        child: Text('This is push notification test'),
      ),
    );
  }

  /// Ready to receive notifications
  Future<void> _readyForNotification() async {
    await _getApplicationToken();
    await _initializeFlutterLocalNotificationsPlugin();

    NotificationSettings settings = await _requestPushPermission();

    _checkNotificationAuthorizationStatus(settings);

    await _enableForegroundMessageForIOS();
    await _createAndroidNotificationChannel();

    _listenFirebaseMessage();
  }

  /// Get application token for testing
  /// Maybe this can be stored in backend to specify the user who can receive a notification
  Future<void> _getApplicationToken() async {
    String? token = await _messaging.getToken();

    if (token != null && token.isNotEmpty) {
      inspect(token);
    }
  }

  /// Request permission for Web and iOS
  /// [FirebaseMessaging.requestPermission] method only works for Web and iOS
  /// From the Apple based platforms, once the request [AuthorizationStatus.authorized] or [AuthorizationStatus.denied],
  /// it's not possible to re-request permission.
  /// The user must update permission via the device setting.
  Future<NotificationSettings> _requestPushPermission() async {
    return await _messaging.requestPermission(
      // Sets whether notifications can be displayed to the user on the device.
      alert: true,
      // If enabled, Siri will read the notification content out when devices are connected to AirPods.
      announcement: false,
      // Sets whether a notification dot will appear next to the app icon on the device when there are unread notifications.
      badge: true,
      // Sets whether notifications will appear when the device is connected to CarPlay.
      carPlay: false,
      // ?
      criticalAlert: false,
      // Sets whether provisional permissions are granted.
      // On iOS 12+, provisional permission can be used.
      // This type of permission system allows for notification permission to be instantly granted without displaying a dialog to your user.
      // permission allows notifications to be displayed quietly (only visible within the device notification center).
      // Set `true` to allow provisional permission.
      provisional: false,
      // Sets whether a sound will be played when a notification is displayed on the device.
      sound: true,
    );
  }

  /// Check the [NotificationSettings.authorizationStatus]
  /// The Android will return [AuthorizationStatus.authorized] if they didn't turn the push off from the app setting
  void _checkNotificationAuthorizationStatus(NotificationSettings settings) {
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        inspect('Authorized');
        break;

      case AuthorizationStatus.denied:
        inspect('Denied');
        break;

      case AuthorizationStatus.notDetermined:
        inspect('User has not chosen yet');
        break;

      case AuthorizationStatus.provisional:
        inspect('User granted provisional permission');
        break;
    }
  }

  /// For iOS device, need to call [FirebaseMessaging.setForegroundNotificationPresentationOptions] method
  /// to display head up message
  Future<void> _enableForegroundMessageForIOS() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initialize [FlutterLocalNotificationsPlugin] for Android and iOS
  Future<void> _initializeFlutterLocalNotificationsPlugin() async {
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final IOSInitializationSettings iosInitializationSettings = IOSInitializationSettings(
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => const Text('message'),
    );
  }

  /// Create [AndroidNotificationChannel] to show foreground notification from Android.
  /// The heads up notification requires [Importance.max] level.
  /// The [AndroidNotificationChannel] need to be created to device by using [FlutterLocalNotificationsPlugin].
  /// After created, update `android/app/src/main/AndroidManifest.xml` to use this created channel.
  Future<void> _createAndroidNotificationChannel() async {
    // Create channel on device
    // If the channel id already exists, the channel will be updated
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Listen the push message for app
  void _listenFirebaseMessage() {
    FirebaseMessaging.onMessage.listen(_firebaseMessageHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_firebaseMessageHandler);
  }

  /// The [RemoteMessage] contains [RemoteMessage.notification] and [RemoteMessage.data] properties.
  /// The message that only contains [RemoteMessage.data] will have low priority, and it's silent message.
  /// The low priority messages are ignored from the Background and Terminated state app.
  /// To set high priority for [RemoteMessage.data] only message,
  /// - Android: set the `priority` field to `high`
  /// - iOS: set the `content-available` field to `true`.
  void _firebaseMessageHandler(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // What is [message.notification?.apple]?
    // Can I use this field for iOS message?
    inspect(notification?.apple);
    inspect(notification);
    inspect(android);

    // If `onMessage` is triggered with a notification, construct our own
    // local notification to show to users using the created channel.
    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon,
          ),
        ),
      );
    }
  }
}
