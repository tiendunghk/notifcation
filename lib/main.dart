import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification/navigator.dart';
import 'package:notification/test_widget.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    'This channel is used for important notifications.', // description
    importance: Importance.high,
    playSound: true);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgrounHanlder(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A new background message : ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgrounHanlder);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: initializationSettingsAndroid),
      onSelectNotification: (message) async {
    if (message != null) {
      print('message laf: $message');

      var data = json.decode(message);

      print('data laf: ${data['myText']}');
      Navigator.of(navigatorKey.currentContext!).pushNamed(TestWidget.routeName,
          arguments: data['myText'].toString());
    }
  });

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: HomePage(),
      navigatorKey: navigatorKey,
      routes: {
        TestWidget.routeName: (_) => TestWidget(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        if (message.data.isNotEmpty) {
          Navigator.of(navigatorKey.currentContext!).pushNamed(
              TestWidget.routeName,
              arguments: message.data['myText']);
        }
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification!.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
                android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channel.description,
              color: Colors.blue,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            )),
            payload: json.encode(message.data));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification!.android;

      if (android != null && notification != null) {
        Navigator.of(context).pushNamed(TestWidget.routeName,
            arguments: message.data['myText'].toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test notification'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          flutterLocalNotificationsPlugin.show(
              0,
              'title',
              'body',
              NotificationDetails(
                  android: AndroidNotificationDetails(
                      channel.id, channel.name, channel.description,
                      importance: Importance.high,
                      color: Colors.blue,
                      playSound: true,
                      icon: '@mipmap/ic_launcher')),
              payload: json.encode(<String, int>{'myText': 1}));
        },
      ),
      body: Center(),
    );
  }
}
