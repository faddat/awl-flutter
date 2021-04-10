import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:peerlanflutter/api.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_code_scanner/qr_code_scanner.dart';

void showAddPeerDialog(BuildContext context) {
  showDialog<String>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: Text("Add new peer"),
        children: [
          Center(
            child: SizedBox(
              width: 450,
              child: AddPeerForm(),
            ),
          ),
        ],
      );
    },
  );
}

class AddPeerForm extends StatefulWidget {
  @override
  _AddPeerFormState createState() => _AddPeerFormState();
}

class _AddPeerFormState extends State<AddPeerForm> {
  final _peerIdTextController = TextEditingController();
  final _aliasTextController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _focusAlias = FocusNode();
  String _serverError = "";

  void _onPressInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    var response = await sendFriendRequest(http.Client(), _peerIdTextController.text, _aliasTextController.text);
    if (response == "") {
      // "Invitation was sent"
      Navigator.pop(context);
      _serverError = "";
      _formKey.currentState!.validate();
    } else {
      _serverError = response;
      _formKey.currentState!.validate();
      _serverError = "";
    }
  }

  void _scanQR(BuildContext context) async {
    // TODO: support web; there is an open PR in lib
    if (Platform.isAndroid) {
      var status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        return;
      }
    } else {
      return;
    }

    var res =
        await Navigator.of(context).push<Barcode?>(MaterialPageRoute(builder: (BuildContext context) => QRScanPage()));
    if (res == null || res.code == '') {
      return;
    }

    setState(() {
      _peerIdTextController.text = res.code;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter some text';
                } else if (_serverError != "") {
                  return _serverError;
                }
                return null;
              },
              controller: _peerIdTextController,
              decoration: InputDecoration(hintText: 'Peer ID'),
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (v) {
                FocusScope.of(context).requestFocus(_focusAlias);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _aliasTextController,
              focusNode: _focusAlias,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: 'Alias'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              if (!kIsWeb)
                RaisedButton.icon(
                  icon: Image(image: AssetImage('assets/qrcode.png')),
                  label: Text('Scan QR'),
                  onPressed: () async {
                    _scanQR(context);
                  },
                ),
              RaisedButton(
                child: Text('Invite peer'),
                onPressed: () async {
                  _onPressInvite();
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

class QRScanPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (result != null) {
      Navigator.of(context).pop(result!);
      return Scaffold();
    }
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: _buildQrView(context)),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea =
        (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400) ? 150.0 : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      controller.stopCamera();
      setState(() {
        result = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
