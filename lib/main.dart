import 'package:flutter/material.dart';
import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:my_first_app/screens/loginScreen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String region = "IN";
  String appId = "27153765695d4ed3";

  AppSettings appSettings= (AppSettingsBuilder()
    ..subscriptionType = CometChatSubscriptionType.allUsers
    ..region= region
    ..adminHost = "" //optional
    ..clientHost = "" //optional
    ..autoEstablishSocketConnection =  true
  ).build();


  CometChat.init(appId, appSettings,
      onSuccess: (String successMessage) {
        debugPrint("Initialization completed successfully  $successMessage");
      }, onError: (CometChatException excep) {
        debugPrint("Initialization failed with exception: ${excep.message}");
      }
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Loginscreen(),
    );
  }
}

