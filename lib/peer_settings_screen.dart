import 'dart:async';

import 'package:anywherelan/api.dart';
import 'package:anywherelan/entities.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class KnownPeerSettingsScreen extends StatefulWidget {
  static String routeName = "/peer_settings";

  KnownPeerSettingsScreen({Key? key}) : super(key: key);

  @override
  _KnownPeerSettingsScreenState createState() => _KnownPeerSettingsScreenState();
}

class _KnownPeerSettingsScreenState extends State<KnownPeerSettingsScreen> {
  late TextEditingController _aliasTextController;
  late TextEditingController _domainNameTextController;

  bool _hasPeerConfig = false;
  late String _peerID;
  late KnownPeerConfig _peerConfig;

  final _generalFormKey = GlobalKey<FormState>();

  void _refreshPeerConfig() async {
    var peerConfig = await fetchKnownPeerConfig(http.Client(), _peerID);
    if (!this.mounted) {
      return;
    }

    _aliasTextController = TextEditingController(text: peerConfig.alias);
    _domainNameTextController = TextEditingController(text: peerConfig.domainName);

    setState(() {
      _peerConfig = peerConfig;
    });
  }

  Future<String> _sendNewPeerConfig() async {
    var payload =
        UpdateKnownPeerConfigRequest(_peerConfig.peerId, _aliasTextController.text, _domainNameTextController.text);

    var response = await updateKnownPeerConfig(http.Client(), payload);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPeerConfig) {
      _peerID = ModalRoute.of(context)!.settings.arguments as String;

      _refreshPeerConfig();
      _hasPeerConfig = true;
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peer settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            _buildGeneralForm(),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  child: Text('CANCEL'),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  child: Text('SAVE'),
                  onPressed: () async {
                    var result = await _sendNewPeerConfig();
                    if (result == "") {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.green,
                        content: Text("Successfully saved"),
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.red,
                        content: Text(result),
                      ));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralForm() {
    return Form(
      key: _generalFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              initialValue: _peerConfig.peerId,
              decoration: InputDecoration(labelText: 'Peer ID', enabled: false),
              maxLines: 2,
              minLines: 1,
              readOnly: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              initialValue: _peerConfig.ipAddr,
              decoration: InputDecoration(labelText: 'Local address', enabled: false),
              maxLines: 2,
              minLines: 1,
              readOnly: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              initialValue: _peerConfig.name,
              decoration: InputDecoration(labelText: 'Name', enabled: false),
              readOnly: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _aliasTextController,
              decoration: InputDecoration(labelText: 'Alias'),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _domainNameTextController,
              autovalidateMode: AutovalidateMode.always,
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return null;
                }
                var filteredValue = value.trim().replaceAll(RegExp(r'\s'), "").toLowerCase();
                if (value != filteredValue) {
                  return "should be lowercase and without whitespace";
                }

                return null;
              },
              decoration: InputDecoration(
                labelText: 'Domain name',
                helperText: 'domain name without ".awl" suffix, like "tvbox.home" or "workstation"',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
