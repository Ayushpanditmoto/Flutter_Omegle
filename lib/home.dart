// ignore_for_file: unused_import

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
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
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
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
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
                    final MediaStream stream = await navigator.mediaDevices
                        .getUserMedia(mediaConstraints);
                    _localStream = stream;
                    _localRenderer.srcObject = _localStream;
                  },
                  child: const Text('Active Audio and Video'),
                ),
                const SizedBox(
                  width: 10,
                ),
                ElevatedButton(
                  onPressed: () async {
                    // final Map<String, dynamic> mediaConstraints = {
                    //   'audio': true,
                    //   'video': false,
                    // };
                    // final MediaStream stream = await navigator.mediaDevices
                    //     .getUserMedia(mediaConstraints);
                    // _localStream = stream;
                    // _localRenderer.srcObject = _localStream;
                  },
                  child: const Text('Search for a partner'),
                ),
              ],
            ),
            const Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: Text("Messages Area"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
