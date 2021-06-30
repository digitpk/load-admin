import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:load_admin/screens/qr_scanner_screen.dart';
import 'package:load_admin/utils/constants.dart';
import 'package:load_admin/widgets/ProgressHUD.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  final usernameController = TextEditingController();

  final passwordController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final _formKey = GlobalKey<FormState>();

  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  //TODO FIX FlutterActivity requirement
  bool _authorized = false;
  bool _isAuthenticating = false;
  Future<String> accessToken;
  bool isLoading;
  @override
  void initState() {
    super.initState();
    isLoading = false;
    getAccessToken().then((accessToken) {
      if (accessToken != null) {
        print("accessToken $accessToken");

        _getAvailableBiometrics().then((availableBiometrics) {
          print(availableBiometrics);

          setState(() {
            _availableBiometrics = availableBiometrics;
          });
          _authenticate().then((authenticated) {
            if (authenticated) {
              goToHomeScreen(context);
            }
          });
        });
      }
    });
  }

  Future<bool> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }

    return canCheckBiometrics;
  }

  Future<bool> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticateWithBiometrics(
          localizedReason: 'Scan your fingerprint to authenticate',
          useErrorDialogs: true,
          stickyAuth: true);
    } on PlatformException catch (e) {
      print(e);
    }

    return authenticated;
  }

  Future<List<BiometricType>> _getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print(e);
    }
    return availableBiometrics;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      // backgroundColor: Color(0xff060B1F),
      body: ProgressHUD(
        child: SingleChildScrollView(
          child: SafeArea(
            child: Container(
              margin: EdgeInsets.only(top: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      LOGO,
                      height: LOGO_SIZE_HEIGHT.toDouble(),
                      width: LOGO_SIZE_WIDTH.toDouble(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter username';
                          }
                          return null;
                        },
                        style: TextStyle(color: Colors.black),
                        controller: usernameController,
                        decoration: InputDecoration(
                            labelStyle: TextStyle(color: Colors.black),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor),
                              //  when the TextFormField in unfocused
                            ),
                            icon: Icon(
                              Icons.email,
                              color: Theme.of(context).primaryColor,
                            ),
                            focusColor: Theme.of(context).primaryColor,
                            hintText: "Username",
                            hintStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                        obscureText: true,
                        controller: passwordController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                            labelStyle: TextStyle(color: Colors.black),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueAccent),
                              //  when the TextFormField in unfocused
                            ),
                            icon: Icon(
                              Icons.lock_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                            focusColor: Theme.of(context).primaryColor,
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    Container(
                        width: 150,
                        height: 60,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: RaisedButton(
                          color: Theme.of(context).primaryColor,
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              login(context);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "Sign In",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'avenir'),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        )),
                    Row(
                      children: <Widget>[],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        inAsyncCall: isLoading,
        opacity: 0.0,
      ),
    );
  }

  Widget biometricScanner() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.fingerprint,
          size: 40,
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Scan finger print to continue",
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
        )
      ],
    );
  }

  login(context) async {
    setState(() {
      isLoading = true;
    });
    //var url = 'http://206.189.117.106:8001/api/users/login';
    // var url = 'https://api.load-africa.com/api/users/login';
    //var apiKey = "b9d33f338be27ec9ed63baaebc44ac05";
    var uri = Uri.https(
      BASE_URL,
      "/api/users/login",
    );
    var response = await http.post(uri, headers: <String, String>{
      'x-load-apikey': API_KEY
    }, body: {
      "username": usernameController.text,
      "password": passwordController.text,
      "deviceType": "WEB",
      "appVersion": "1.0.0"
    });
    var parsedJson = json.decode(response.body);
    print("Response========= " + parsedJson.toString());
    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
      });
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(
          "Login Successful",
          style: TextStyle(fontFamily: 'Avenir'),
        ),
      ));

      print("Access token before saving ${parsedJson['data']['accessToken']}");
      saveToken(parsedJson['data']['accessToken']).then((value) {
        goToHomeScreen(context);
      });
    } else {
      setState(() {
        isLoading = false;
      });
      showDialog(
          context: context,
          builder: (_) => new AlertDialog(
                title: new Text("Error"),
                content: new Text(parsedJson['message']),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ));
    }
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  }

  Future<void> saveToken(accessToken) async {
    final SharedPreferences prefs = await _prefs;
    final String _accessToken = "";
    return prefs
        .setString("accessToken", accessToken)
        .then((bool success) => null);
  }

  Future<String> getAccessToken() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString("accessToken");
  }

  goToHomeScreen(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return QRScannerScreen(
              // firstName: usernameController.text,
              );
        },
      ),
    );
  }
}
