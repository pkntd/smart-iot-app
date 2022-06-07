import 'package:flutter/material.dart';
import 'package:smart_iot_app/services/authentication.dart';

class MainPage extends StatefulWidget{
  MainPage({Key? key, required this.auth, required this.logoutCallback, required this.userId}): super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage>{
  final scaffKey = GlobalKey<ScaffoldState>();

  signOut() async {
    try{
      await widget.auth.signOut();
      widget.logoutCallback();
    }catch(e){
      print(e);
    }
  }

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffKey,
      appBar: AppBar(
        title: Text("Smart IOT Farm"),
        actions: <Widget>[
          TextButton(
              onPressed: signOut,
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black
                ),
              ),
          )
        ],
      ),
    );
  }


}