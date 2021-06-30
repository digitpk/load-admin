import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:load_admin/dao/barcode_dao.dart';
import 'package:load_admin/model/barcode.dart';
import 'package:load_admin/network/database.dart';
import 'package:load_admin/utils/constants.dart';
import 'package:load_admin/widgets/ProgressHUD.dart';
import 'package:load_admin/widgets/barcode_single.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannedBarcodesScreen extends StatefulWidget {
  final String token;

  ScannedBarcodesScreen({this.token});

  @override
  State<StatefulWidget> createState() => ScannedBarcodesState();
}

class ScannedBarcodesState extends State<ScannedBarcodesScreen> {
  var database;
  BarcodeDao barcodeDAO;
  List<Barcode> barcodes = List<Barcode>();
  bool _validContact = false;
  bool isLoading;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  @override
  void initState() {
    super.initState();
    isLoading = false;
    openDB();
  }

  openDB() async {
    database = await $FloorAppDatabase
        .databaseBuilder(widget.token)
        .build()
        .then((value) {
      barcodeDAO = value.barcodeDao;
      getBarCodeList();
    });
  }

  getBarCodeList() async {
    await barcodeDAO.getAllBarcodes().then((value) {
      updateBarcodeList(value);
    });
  }

  updateBarcodeList(barcodeList) {
    setState(() {
      barcodes = barcodeList;
    });
  }

  TextEditingController textEditingController = TextEditingController();
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.BARCODE);

      getContactDialog(barcodeScanRes);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            "Scanned Bar Codes",
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
              onPressed: () {
                scanBarcodeNormal();
              },
            ),
            IconButton(
              icon: Icon(Icons.check, color: Theme.of(context).primaryColor),
              onPressed: () {
                sendToDB(barcodes);
              },
            )
          ],
        ),
        body: ProgressHUD(
          child: ListView.builder(
            itemCount: barcodes.length,
            itemBuilder: (context, index) => SingleBarCode(
              barcode: barcodes[index].code,
              contact: barcodes[index].contact,
              barcodeDao: barcodeDAO,
            ),
          ),
          inAsyncCall: isLoading,
          opacity: 0.0,
        ),
      );

  void getContactDialog(String barcodeScanRes) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(barcodeScanRes),
            content: TextField(
              controller: textEditingController,
              decoration: InputDecoration(
                  hintText: "Contact",
                  errorText:
                      _validContact ? null : "Contact number is required"),
            ),
            actions: <Widget>[
              FlatButton(
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                child: Text('Cancel'),
                onPressed: () {
                  setState(() {
                    //save to db
                    Navigator.pop(context);
                  });
                },
              ),
              FlatButton(
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                child: Text('Save'),
                onPressed: () {
                  setState(() {
                    textEditingController.text.isEmpty
                        ? _validContact = false
                        : _validContact = true;
                    if (_validContact) {
                      insertBarcode(barcodeScanRes, textEditingController.text);
                    }

                    // Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  insertBarcode(barcode, contact) async {
    await barcodeDAO
        .insertBarcode(Barcode(barcode, textEditingController.text))
        .then((value) {
      getBarCodeList();
    });
  }

  sendToDB(barcodes) async {
    setState(() {
      isLoading = true;
    });
    await getAccessToken().then((accessToken) async {
      print("Acess token before send $accessToken");
      Map<String, dynamic> args = {"barcodes": barcodes};
      final String requestBody = json.encode(args);
      var url =
          'https://api.load-africa.com/api/distributors/service_requests/barcodes';
      var uri = Uri.https(
        BASE_URL,
        "/api/distributors/service_requests/barcodes",
      );
      var response = await http.post(uri,
          headers: <String, String>{
            'x-load-apikey': API_KEY,
            'x-load-tokenshare': widget.token,
            'authorization': 'Bearer $accessToken'
            //    'Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI1ZDhiM2EyYjc3NjY5MTQ2MWFmYTY4ZjEiLCJfdGVuYW50SWQiOiI1ZDhiM2EyYjc3NjY5MTQ2MWFmYTY4ZWEiLCJfYWNjb3VudCI6IjVkOGIzYTJiNzc2NjkxNDYxYWZhNjhlZSIsIl91c2VyVHlwZSI6IkFfUEFSVE5FUiIsInVzZXJuYW1lIjoiZ2Fuc3RhQGdlbml1c2FsZWMuY29tIiwiY2xhaW1zIjpbeyJfaWQiOiI1ZDhiM2EyYjc3NjY5MTQ2MWFmYTY4ZjUiLCJ0eXBlIjoidXNlciIsInZhbHVlIjoiYW5jaG9yIiwiZGF0ZUNyZWF0ZWQiOiIyMDE5LTA5LTI1VDA5OjU4OjAzLjc5MFoifSx7Il9pZCI6IjVkOGIzYTJiNzc2NjkxNDYxYWZhNjhmNCIsInR5cGUiOiJyb2xlIiwidmFsdWUiOiJhZG1pbiIsImRhdGVDcmVhdGVkIjoiMjAxOS0wOS0yNVQwOTo1ODowMy43OTBaIn0seyJfaWQiOiI1ZDhiM2EyYjc3NjY5MTQ2MWFmYTY4ZjMiLCJ0eXBlIjoicm9sZSIsInZhbHVlIjoidGVuYW50X2FkbWluIiwiZGF0ZUNyZWF0ZWQiOiIyMDE5LTA5LTI1VDA5OjU4OjAzLjc5MVoifV0sImFnZW50Ijp7ImZhbWlseSI6IkNocm9tZSIsIm1ham9yIjoiODgiLCJtaW5vciI6IjAiLCJwYXRjaCI6IjQzMjQiLCJkZXZpY2UiOnsiZmFtaWx5IjoiT3RoZXIiLCJtYWpvciI6IjAiLCJtaW5vciI6IjAiLCJwYXRjaCI6IjAifSwib3MiOnsiZmFtaWx5IjoiV2luZG93cyIsIm1ham9yIjoiMTAiLCJtaW5vciI6IjAiLCJwYXRjaCI6IjAifX0sImlhdCI6MTYxMjI2ODgzNSwibmJmIjoxNjEyODczNjM1LCJleHAiOjE2MTI4NzM2MzUsImF1ZCI6IkxvYWQgQ2xpZW50IiwiaXNzIjoiTG9hZCBBUEkgSWRlbnRpdHkgTWFuYWdlciIsInN1YiI6IjVkOGIzYTJiNzc2NjkxNDYxYWZhNjhmMSJ9.7U6iEul6zHMo0OPO0sWR8ZeyJwZuPeTYYBFYmQZxQPQ7QtDnx-JNhlLOW2u0leKUrvFkCas2YLfFySFEBLwfKA'
            // 'Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI1ZDhiM2EyYjc3NjY5MTQ2MWFmYTY4ZjEiLCJfdGVuYW50SWQiOiI1ZDhiM2EyYjc3NjY5MTQ2MWFmYTY4ZWEiLCJfYWNjb3VudCI6IjVkOGIzYTJiNzc2NjkxNDYxYWZhNjhlZSIsIl91c2VyVHlwZSI6IkFfUEFSVE5FUiIsInVzZXJuYW1lIjoiZ2Fuc3RhQGdlbml1c2FsZWMuY29tIiwiY2xhaW1zIjpbeyJfaWQiOiI1ZDhiM2EyYjc3NjY5MTQ2MWFmYTY4ZjUiLCJ0eXBlIjoidXNlciIsInZhbHVlIjoiYW5jaG9yIiwiZGF0ZUNyZWF0ZWQiOiIyMDE5LTA5LTI1VDA5OjU4OjAzLjc5MFoifSx7Il9pZCI6IjVkOGIzYTJiNzc2NjkxNDYxYWZhNjhmNCIsInR5cGUiOiJyb2xlIiwidmFsdWUiOiJhZG1pbiIsImRhdGVDcmVhdGVkIjoiMjAxOS0wOS0yNVQwOTo1ODowMy43OTBaIn0seyJfaWQiOiI1ZDhiM2EyYjc3NjY5MTQ2MWFmYTY4ZjMiLCJ0eXBlIjoicm9sZSIsInZhbHVlIjoidGVuYW50X2FkbWluIiwiZGF0ZUNyZWF0ZWQiOiIyMDE5LTA5LTI1VDA5OjU4OjAzLjc5MVoifV0sImFnZW50Ijp7ImZhbWlseSI6IkNocm9tZSIsIm1ham9yIjoiODgiLCJtaW5vciI6IjAiLCJwYXRjaCI6IjQzMjQiLCJkZXZpY2UiOnsiZmFtaWx5IjoiT3RoZXIiLCJtYWpvciI6IjAiLCJtaW5vciI6IjAiLCJwYXRjaCI6IjAifSwib3MiOnsiZmFtaWx5IjoiV2luZG93cyIsIm1ham9yIjoiMTAiLCJtaW5vciI6IjAiLCJwYXRjaCI6IjAifX0sImlhdCI6MTYxMjI2ODgzNSwibmJmIjoxNjEyODczNjM1LCJleHAiOjE2MTI4NzM2MzUsImF1ZCI6IkxvYWQgQ2xpZW50IiwiaXNzIjoiTG9hZCBBUEkgSWRlbnRpdHkgTWFuYWdlciIsInN1YiI6IjVkOGIzYTJiNzc2NjkxNDYxYWZhNjhmMSJ9.7U6iEul6zHMo0OPO0sWR8ZeyJwZuPeTYYBFYmQZxQPQ7QtDnx-JNhlLOW2u0leKUrvFkCas2YLfFySFEBLwfKA'
          },
          body: requestBody);
      print(response.body);
      var parsedJson = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });

        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: Text("Success"),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ));
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
    });
  }

  Future<String> getAccessToken() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString("accessToken");
  }
}

class BarcodeList {
  BarcodeList(this.barcodes);

  List<Barcode> barcodes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'barcodes': barcodes,
      };
}
