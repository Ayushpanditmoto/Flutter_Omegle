// ignore_for_file: unused_import, non_constant_identifier_names, avoid_unnecessary_containers,

import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool video = true;
  bool audio = true;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final TextEditingController _sdController = TextEditingController();
  final Peer peer = Peer();
  final io.Socket _socket = io.io('http://10.0.2.2:3000', <String, dynamic>{
    'transports': ['websocket'],
  });

  String? theUUID;
  String? peerConnection;
  String? localStream;
  String? otherUser;
  String? theStream;
  String? peerID;
  String? otherPeerID;
  bool joined = false;
  bool waitingOnConnection = false;
  int onlineUsers = 0;
  @override
  void initState() {
    initRenderers();
    connectSocekt();
    // generate peer id and print in console
    peer.on("open").listen((id) {
      setState(() {
        peerID = peer.id;
        debugPrint('peerID: $peerID');
      });
    });
    _getUsersMedia(audio, video);
    super.initState();
  }

  connectSocekt() {
    //online users count
    _socket.on('oc', (oc) {
      setState(() {
        debugPrint('online users: $oc');
        debugPrint('Socket connected');

        onlineUsers = oc;
      });
    });
    _socket.on('connect', (data) {
      _getUsersMedia(audio, video);
      _socket.emit('join', peerID);
    });
  }

  joinRoom() {
    try {
      ServerMsg("Searching for a user...");
      waitingOnConnection = true;
      joined = false;
      _socket.emit('join room', [peerID, video]);
      peer.on<MediaConnection>('call').listen((call) async {
        final mediaStream = await navigator.mediaDevices
            .getUserMedia({"video": true, "audio": false});
        call.answer(mediaStream);
        call.on('stream').listen((stream) {
          joined = true;
          _remoteRenderer.srcObject = stream;
        });
        call.on("close").listen((event) {
          setState(() {
            waitingOnConnection = false;
            joined = false;
          });
        });
      });
    } catch (e) {
      debugPrint('joinRoom error: $e');
    }
  }

  ServerMsg(String msg) {
    debugPrint(msg);
  }

  StrangerMsg(String msg) {
    debugPrint(msg);
  }

  sendMessage() {
    if (joined) {
      _socket.emit('message', 'Hello');
    } else if (waitingOnConnection) {
      _socket.emit('message', 'Waiting for strangers');
    } else if (!joined) {
      _socket.emit(
          'message', 'You havent joined a Room yet! Please click on search');
    } else {
      _socket.emit('message', 'you cannot sent a blank message');
    }
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

  _getUsersMedia(bool x, bool y) async {
    final Map<String, dynamic> mediaConstraints = {'audio': x, 'video': y};
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
        actions: [
          Text(
            '$onlineUsers',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Icon(Icons.person)
        ],
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
            const SizedBox(height: 5),
            ButtonSection(),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Row ButtonSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              video = !video;
              _getUsersMedia(audio, video);
            });
          },
          child: const Text('Camera'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              audio = !audio;
              _getUsersMedia(audio, video);
            });
          },
          child: const Text('Microphone'),
        ),
        ElevatedButton(
          onPressed: () {
            joinRoom();
          },
          child: const Text('Search for Partner'),
        ),
      ],
    );
  }

  SizedBox VideoRenderers() => SizedBox(
        height: 260,
        child: Row(
          children: [
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Container(
                  height: 260,
                  key: const Key('local'),
                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                  ),
                  child: video
                      ? RTCVideoView(_localRenderer, mirror: true)
                      : const Center(child: Text('No Video'))),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Container(
                  height: 260,
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
}
