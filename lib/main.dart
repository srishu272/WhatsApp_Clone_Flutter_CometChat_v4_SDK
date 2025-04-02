import 'package:flutter/material.dart';
import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:my_first_app/screens/homeScreen.dart';
import 'package:my_first_app/screens/loginScreen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String region = "IN";
  String appId = "27153765695d4ed3";

  AppSettings appSettings =
      (AppSettingsBuilder()
            ..subscriptionType = CometChatSubscriptionType.allUsers
            ..region = region
            ..adminHost =
                "" //optional
            ..clientHost =
                "" //optional
            ..autoEstablishSocketConnection = true)
          .build();

  CometChat.init(
    appId,
    appSettings,
    onSuccess: (String successMessage) {
      debugPrint("Initialization completed successfully  $successMessage");
    },
    onError: (CometChatException excep) {
      debugPrint("Initialization failed with exception: ${excep.message}");
    },
  );

  var user = await CometChat.getLoggedInUser();

  runApp(MyApp(initialScreen: user != null ? Homescreen() : Loginscreen()));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}
