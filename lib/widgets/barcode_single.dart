import 'package:flutter/material.dart';
import 'package:load_admin/dao/barcode_dao.dart';

class SingleBarCode extends StatefulWidget {
  final String barcode;
  final String contact;
  final BarcodeDao barcodeDao;

  SingleBarCode({this.contact, this.barcode, this.barcodeDao});

  @override
  _SingleBarCodeState createState() => _SingleBarCodeState();
}

class _SingleBarCodeState extends State<SingleBarCode> {
  TextEditingController _textEditController = TextEditingController();
  bool editing = false;
  @override
  void initState() {
    super.initState();
    _textEditController.text = widget.contact;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Card(
        color: Colors.white,
        elevation: 10,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                widget.barcode,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _textEditController,
                enabled: editing ? true : false,
              ),
            ),
            Container(
              height: 2,
              color: Colors.grey.shade600,
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(left: 12, right: 12),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: IconButton(
                      icon: Icon(Icons.edit),
                      color: Theme.of(context).primaryColor,
                      onPressed: () {
                        setState(() {
                          editing = true;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: IconButton(
                      icon: Icon(Icons.save),
                      color: Theme.of(context).primaryColor,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  updateBarcode() async {
    await widget.barcodeDao
        .updateContact(_textEditController.text, widget.barcode)
        .then((value) {});
  }
}
