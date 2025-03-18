import 'package:cometchat_sdk/exception/cometchat_exception.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:cometchat_sdk/models/user.dart';
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

  Future<void> loginUser() async {
    String uid = uidController.text.trim();
    String authKey = "34bd5ed076ab5a7aba096ccbffb98d0dcaafebe3";

    final user = await CometChat.getLoggedInUser();
    if (user == null) {
      await CometChat.login(uid, authKey,
          onSuccess: (User user) {
            debugPrint("Login Successful : $user" );
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Homescreen()));
          }, onError: (CometChatException e) {
            debugPrint("Login failed with exception:  ${e.message}");
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Center(child: Text("CometChat App",style: TextStyle(color: Colors.teal.shade800,fontWeight: FontWeight.bold,fontSize: 25),)),
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
                validator: (value){
                  if(value == null || value.isEmpty){
                    return "Please enter a valid user ID";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Enter the UID",
                  labelText: "User-ID",
                  labelStyle: TextStyle(color: Colors.white70,fontWeight: FontWeight.bold,fontSize: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),borderSide: BorderSide(color: Colors.white70),

                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),borderSide: BorderSide(color: Colors.white70,width: 3),

                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),borderSide: BorderSide(color: Colors.white70),

                  )
                ),
              ),
              SizedBox(
                height: 15,
              ),
              InkWell(
                onTap: (){
                  if(_formKey.currentState!.validate()){
                    print("Login Success");
                    loginUser();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10,horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white70
                  ),
                  child: Center(
                    child: Text("Login",style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.teal
                    ),),
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}
