// ignore_for_file: unused_import, non_constant_identifier_names, avoid_unnecessary_containers,

import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //Icon for the button change conditionally
  bool video = true;
  bool audio = true;
  bool socketStatus = false;
  String UserConnectionMsg = "Not Connected";
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final TextEditingController _msgController = TextEditingController();
  final Peer peer = Peer();
  final io.Socket _socket =
      io.io('https://socketomegle.herokuapp.com', <String, dynamic>{
    'transports': ['websocket'],
  });

  String? theUUID;
  String? peerConnection;
  String? otherUser;
  String? theStream;
  String? peerID;
  String? otherPeerID;
  bool joined = false;
  bool waitingOnConnection = false;
  int onlineUsers = 0;
  @override
  void initState() {
    super.initState();
    initRenderers();
    peer.on("open").listen((id) {
      setState(() {
        peerID = peer.id;
        debugPrint('peerID: $peerID');
      });
    });
    peer.on<MediaConnection>('call').listen((call) async {
      final mediaStream = await navigator.mediaDevices
          .getUserMedia({"video": true, "audio": true});
      call.answer(mediaStream);
      call.on('stream').listen((stream) {
        joined = true;
        setState(() {
          _localRenderer.srcObject = mediaStream;
          _remoteRenderer.srcObject = stream;
        });
      });
      call.on("close").listen((event) {
        setState(() {
          waitingOnConnection = false;
          joined = false;
          _localRenderer.srcObject = null;
        });
      });
    });
    _getUsersMedia(audio, video);
    connectSocekt();
  }

  connectSocekt() {
    _socket.on('oc', (oc) {
      setState(() {
        socketStatus = true;
        debugPrint('online users: $oc');
        debugPrint('Socket connected');

        onlineUsers = oc;
      });
    });
    _socket.on('connect', (data) {
      _getUsersMedia(audio, video);
      _socket.emit('join', peerID);
    });
    _socket.on('disconnect', (data) {
      socketStatus = false;
      debugPrint('Socket disconnected');
    });
  }

  serverMsg(msg) {
    debugPrint('server msg: $msg');
  }

  strangerMsg(msg) {
    debugPrint('stranger msg: $msg');
  }

  joinRoom() {
    try {
      ServerMsg("Searching for a user...");
      setState(() {
        waitingOnConnection = true;
        UserConnectionMsg = "Searching for a user...";
        joined = false;
      });

      _socket.emit('join room', peerID);
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
    peer.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _msgController.dispose();
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
        toolbarTextStyle: const TextStyle(color: Colors.black),
        title: const Text('Omegle Clone'),
        actions: [
          Center(
            child: Text(
              '$onlineUsers',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          InkWell(
            onTap: () async {
              await connectSocekt();
            },
            child: socketStatus
                ? const Icon(
                    Icons.circle,
                    color: Colors.green,
                  )
                : const Icon(
                    Icons.circle,
                    color: Colors.red,
                  ),
          ),
          const SizedBox(
            width: 10,
          )
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
            IconButton(onPressed: null, icon: Icon(Icons.send)),
          ],
        ),
      ),
      body: Container(
        child: Column(
          children: [
            VideoRenderers(),
            ButtonSection(),
            UserJoinStatus(),
          ],
        ),
      ),
    );
  }

  UserJoinStatus() {
    return Container(
      width: double.infinity,
      height: 25,
      decoration: const BoxDecoration(
        color: Colors.black38,
      ),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          joined ? 'Stranger Joined' : UserConnectionMsg,
          style: TextStyle(
            color: joined ? Colors.green : Colors.red,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Row ButtonSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              video = !video;
            });
            _getUsersMedia(audio, video);
          },
          icon: Icon(
            video ? Icons.videocam : Icons.videocam_off,
            color: video ? Colors.blue : Colors.grey,
          ),
        ),
        Container(
          height: 40,
          width: 1,
          color: Colors.black,
        ),
        IconButton(
          onPressed: () {
            setState(() {
              audio = !audio;
            });
            _getUsersMedia(audio, video);
          },
          icon: Icon(
            audio ? Icons.mic : Icons.mic_off,
            color: audio ? Colors.blue : Colors.grey,
          ),
        ),
        Container(
          height: 40,
          width: 1,
          color: Colors.black,
        ),
        ElevatedButton(
          onPressed: () async {
            await joinRoom();
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: const Text('Search for Partner',
              style: TextStyle(color: Colors.white)),
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
