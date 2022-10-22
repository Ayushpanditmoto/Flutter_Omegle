// ignore_for_file: unused_import, non_constant_identifier_names, avoid_unnecessary_containers,

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:omegleclone/Provider/webrtc_service.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final bool _offer = false;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final TextEditingController _sdController = TextEditingController();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  @override
  void initState() {
    initRenderers();
    // _createPeerConnection().then((pc) {
    //   _peerConnection = pc;
    // });
    _getUsersMedia();
    super.initState();
  }

  _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };
    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };
    _localStream = await _getUsersMedia();
    final RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);
    pc.addStream(_localStream!);
    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        debugPrint(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid..toString(),
          'sdpMLineIndex': e.sdpMLineIndex..toString(),
        }));
      }
    };
    pc.onIceConnectionState = (e) {
      debugPrint(e.toString());
    };
    pc.onAddStream = (stream) {
      debugPrint('add stream: ${stream.id}');
      _remoteRenderer.srcObject = stream;
    };
    return pc;
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _sdController.dispose();
    super.dispose();
  }

  _getUsersMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };
    try {
      final MediaStream stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);

      _localRenderer.srcObject = stream;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Omegle Clone'),
      ),
      bottomNavigationBar: Container(
        height: 50,
        color: const Color.fromARGB(255, 211, 211, 211),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter Messages',
                ),
              ),
            ),
            Icon(Icons.send),
          ],
        ),
      ),
      body: Container(
        child: Column(
          children: [
            VideoRenderers(),
            OfferAndAnswerButtons(),
            sdpCandidateTF(),
            sdpCandidateButtons(),
          ],
        ),
      ),
    );
  }

  Row sdpCandidateButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Set Remote Description'),
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Add Ice Candidate'),
        ),
      ],
    );
  }

  Padding sdpCandidateTF() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _sdController,
        keyboardType: TextInputType.multiline,
        maxLines: 5,
        maxLength: TextField.noMaxLength,
        decoration: const InputDecoration(
          hintText: 'Enter SDP Candidate',
        ),
      ),
    );
  }

  SizedBox VideoRenderers() => SizedBox(
        height: 300,
        child: Row(
          children: [
            Flexible(
              child: Container(
                  key: const Key('local'),
                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                  ),
                  child: RTCVideoView(_localRenderer)),
            ),
            Flexible(
              child: Container(
                  key: const Key('remote'),
                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                  ),
                  child: RTCVideoView(_remoteRenderer)),
            ),
          ],
        ),
      );
  Row OfferAndAnswerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () async {},
          child: const Text('Create Offer'),
        ),
        const SizedBox(
          width: 10,
        ),
        ElevatedButton(
          onPressed: () async {},
          child: const Text('Create Answer'),
        ),
      ],
    );
  }
}
