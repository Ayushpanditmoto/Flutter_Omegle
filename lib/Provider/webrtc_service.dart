// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService extends ChangeNotifier {
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _getUsersMedia() async {
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
      _localStream = stream;
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };
    final RTCPeerConnection pc = await createPeerConnection(configuration, {});
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      debugPrint(candidate.candidate);
    };
    pc.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint(state.toString());
    };
    pc.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      _remoteRenderer.srcObject = _remoteStream;
    };
    pc.addStream(_localStream!);
  }

  Future<void> startCall() async {
    await initRenderers();
    await _getUsersMedia();
    await _createPeerConnection();
  }
}
