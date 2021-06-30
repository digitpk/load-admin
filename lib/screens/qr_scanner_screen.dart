import 'package:bottom_sheet_bar/bottom_sheet_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:load_admin/dao/barcode_dao.dart';
import 'package:load_admin/model/barcode.dart';
import 'package:load_admin/network/database.dart';
import 'package:load_admin/screens/scanned_barcodes_screen.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => QRScannerState();
}

class QRScannerState extends State<QRScannerScreen> {
  String _scanBarcode = 'Unknown';
  bool _validContact = false;
  var database;
  int scannedCodesCount = 0;
  BarcodeDao barcodeDAO;
  bool _isLocked = false;
  final itemList = List<int>.generate(300, (index) => index * index);
  List<Barcode> barcodeList = List<Barcode>();
  final _bsbController = BottomSheetBarController();
  String token;
  TextEditingController textEditingController = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
            "#ff6666", "Cancel", true, ScanMode.BARCODE)
        .listen((barcode) => print(barcode));
  }

  Future<void> scanQR() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      print("QR TOKEN ==== $token");
      token = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      database = await $FloorAppDatabase
          .databaseBuilder("$token.db")
          .build()
          .then((value) {
        barcodeDAO = value.barcodeDao;
        getBarcodeList();
      });

      print("QR TOKEN ==== $token");
    } on PlatformException {
      token = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = token;
    });
  }

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

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Center(
                child: Text(
                  'Barcode Scanner',
                  style: TextStyle(
                      color: Color(0xFFE8733E), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/qrcode.png",
                    height: 200,
                    width: 200,
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(top: 12),
                    width: 180,
                    height: 60,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: RaisedButton(
                      color: Color(0xFFE8733E),
                      onPressed: scanQR,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Scan Qr Code",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Image.asset(
                            "assets/images/qrcode_button.png",
                            height: 20,
                            width: 20,
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )));
  }

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
      getBarcodeList();
    });
  }

  getBarcodeList() async {
    print("Get barcode list called =======================");
    await barcodeDAO.getAllBarcodes().then((value) {
      if (value.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ScannedBarcodesScreen(
                      token: token,
                    )));
      } else {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          // false = user must tap button, true = tap outside dialog
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('QR Code Successful'),
              content: Text(
                  'QR Code scanned successfully, continue to scan bar codes.'),
              actions: <Widget>[
                FlatButton(
                  child: Text(
                    'Continue',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    scanBarcodeNormal();
                    // Dismiss alert dialog
                  },
                ),
              ],
            );
          },
        );
      }
      updateBarcodeList(value);
      print("=========== " + value.length.toString());
    });
  }

  updateBarcodeList(barcodeList) {
    setState(() {
      this.barcodeList = barcodeList;
    });
  }

  showBottomSheet() {
//    return BottomSheetBar(
//      locked: _isLocked,
//      color: Colors.white,
//      controller: _bsbController,
//      borderRadius: BorderRadius.only(
//        topLeft: Radius.circular(32.0),
//        topRight: Radius.circular(32.0),
//      ),
//      borderRadiusExpanded: BorderRadius.only(
//        topLeft: Radius.circular(0.0),
//        topRight: Radius.circular(0.0),
//      ),
//      body: Container(
//          alignment: Alignment.center,
//          child: Flex(
//              direction: Axis.vertical,
//              mainAxisAlignment: MainAxisAlignment.center,
//              children: <Widget>[
//                RaisedButton(
//                    onPressed: () => scanBarcodeNormal(),
//                    child: Text("Start barcode scan")),
//                RaisedButton(
//                    onPressed: () => scanQR(), child: Text("Start QR scan")),
//              ])),
//      expandedBuilder: (scrollController) => CustomScrollView(
//        controller: scrollController,
//        shrinkWrap: true,
//        slivers: [
//          SliverFixedExtentList(
//            itemExtent: 56.0, // I'm forcing item heights
//            delegate: SliverChildBuilderDelegate(
//                (context, index) => ListView.separated(
//                      separatorBuilder: (context, index) => Divider(),
//                      itemCount: barcodeList.length,
//                      itemBuilder: (context, index) => ListTile(
//                        subtitle: Text(barcodeList[index].contact),
//                        title: Text(
//                          barcodeList[index].code,
//                          style: TextStyle(fontSize: 20.0),
//                        ),
//                        onTap: () => showDialog(
//                          context: context,
//                          builder: (context) => AlertDialog(
//                            title: Text(
//                              itemList[index].toString(),
//                            ),
//                          ),
//                        ),
//                      ),
//                    )),
//          ),
//          SliverToBoxAdapter(
//            child: Container(
//              padding: const EdgeInsets.all(8.0),
//              height: 64,
//              child: RaisedButton(
//                onPressed: () {},
//                color: Theme.of(context).primaryColor,
//                child: Text(
//                  "Submit",
//                  style: TextStyle(color: Colors.white),
//                ),
//              ),
//            ),
//          )
//        ],
//      ),
//      collapsed: FlatButton(
//        onPressed: () => _bsbController.expand(),
//        child: Text(barcodeList.length.toString() + " scanned"),
//      ),
//    );
  }
}
