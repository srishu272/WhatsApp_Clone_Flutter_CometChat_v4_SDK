import 'dart:io';

import 'package:cometchat_sdk/exception/cometchat_exception.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:cometchat_sdk/models/user.dart';
import 'package:cometchat_sdk/notification/enums/push_platforms.dart';
import 'package:cometchat_sdk/notification/main/cometchat_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/screens/homeScreen.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final TextEditingController uidController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();
  bool isLoading = false;

  Future<void> loginUser() async {

    String uid = uidController.text.trim();
    String authKey = "34bd5ed076ab5a7aba096ccbffb98d0dcaafebe3";

    final user = await CometChat.getLoggedInUser();
    if (user == null) {
      await CometChat.login(
        uid,
        authKey,
        onSuccess: (User user) async {
          debugPrint("Login Successful : $user");
          setState(() {
            isLoading = false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Homescreen()),
          );

          // Request FCM permissions
          FirebaseMessaging messaging = FirebaseMessaging.instance;
          NotificationSettings settings = await messaging.requestPermission();

          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            /*if (Platform.isIOS) {
              // Wait for APNs token before requesting FCM token
              String? apnsToken = await messaging.getAPNSToken();
              if (apnsToken == null) {
                debugPrint("APNs token not yet available.");
                return;
              }

              // Give time for APNs token to be forwarded from native iOS
              await Future.delayed(Duration(seconds: 1));
            }*/
            String? apnsToken;
            if (Platform.isIOS) {

              int retryCount = 0;

              // Retry getting APNs token for up to 5 seconds

                apnsToken = await messaging.getAPNSToken();
                if (apnsToken == null) {
                  debugPrint("Waiting for APNs token...");
                  await Future.delayed(Duration(milliseconds: 500));
                  retryCount++;
                }
              }



            String? token = await messaging.getToken();
            debugPrint("FCM Token: $token");
            if (token != null) {
              final platform =
                  Platform.isAndroid
                      ? PushPlatforms.FCM_FLUTTER_ANDROID
                      : PushPlatforms.FCM_FLUTTER_IOS;

              CometChatNotifications.registerPushToken(
                platform,
                providerId: "fcm-android-provider-1",
                 /*Platform.isAndroid ? "fcm-provider-1" : "apns-provider-1",*/
                // Replace with your actual provider ID
                fcmToken: token,
                deviceToken: apnsToken,
                onSuccess: (response) {
                  debugPrint(
                    "registerPushToken:success ${response.toString()}",
                  );
                },
                onError: (e) {
                  debugPrint("registerPushToken:error ${e.toString()}");
                },
              );
            }
          }
        },
        onError: (CometChatException e) {
          debugPrint("Login failed with exception:  ${e.message}");
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message!),
              backgroundColor: Colors.red.shade700,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "CometChat App",
            style: TextStyle(
              color: Colors.teal.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
        backgroundColor: Colors.teal.shade100,
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade100,
              Colors.teal.shade300,
              Colors.teal.shade500,
              Colors.teal.shade700,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFormField(
                controller: uidController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a valid user ID";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Enter the UID",
                  labelText: "User-ID",
                  labelStyle: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white70, width: 3),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                ),
              ),
              SizedBox(height: 15),
              InkWell(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      isLoading = true;
                    });
                    loginUser();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white70,
                  ),
                  child: Center(
                    child:
                        isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
