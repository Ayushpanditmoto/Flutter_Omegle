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
  io.Socket? socket;

//Peerdart copied code
  final TextEditingController _msgController = TextEditingController();
  final Peer peer = Peer(options: PeerOptions(debug: LogLevel.All));
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool inCall = false;
  String? peerID;
  //END

  String? otherUser;
  MediaStream? theStream;
  String? otherPeerID;

  bool joined = false;
  bool waitingOnConnection = false;
  late bool videoOn;
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
    connectSocekt();
    _getUsersMedia(audio, video);

    //Peerdart copied code
    peer.on<MediaConnection>("call").listen((call) async {
      final mediaStream = await navigator.mediaDevices
          .getUserMedia({"video": true, "audio": false});

      call.answer(mediaStream);

      call.on("close").listen((event) {
        setState(() {
          inCall = false;
        });
      });

      call.on<MediaStream>("stream").listen((event) {
        _localRenderer.srcObject = mediaStream;
        _remoteRenderer.srcObject = event;

        setState(() {
          inCall = true;
        });
      });
    });
    //END
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  connectSocekt() {
    debugPrint("Connecting to socket");
    socket = io.io('https://omegleclone.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();
    socket!.on('oc', (oc) {
      setState(() {
        socketStatus = true;
        debugPrint('online users: $oc');
        debugPrint('Socket connected');

        onlineUsers = oc;
      });
    });
    //Submit sent message
    socket!.on('connect', (data) {
      setState(() {
        debugPrint('Socket connected $data');
        socketStatus = true;
        UserConnectionMsg = "Connected ${socket!.id} $peerID";
      });
      _getUsersMedia(audio, video);
      socket!.emit('join', peerID);
    });
//done and working
    socket!.on('dc', (msg) {
      setState(() {
        debugPrint('Socket disconnected $msg');
        _remoteRenderer.srcObject = null;
        socketStatus = false;
        joined = false;
        UserConnectionMsg = "Disconnected";
      });
    });

    //done and working
    socket!.on('other peer', (pid) {
      setState(() {
        otherPeerID = pid;
        debugPrint('otherPeerID: $otherPeerID');
      });
    });
    socket!.on('user joined', (msg) {
      setState(() {
        socketStatus = true;
        // otherPeerID = pid;
        debugPrint('joined1: $msg $peerID');
        // debugPrint(msg.runtimeType.toString());
        print(msg[0]);
        print(msg[1]);
        print(msg[2]);
        connect(msg[1]);
        joined = true;
        UserConnectionMsg = "Connected";
      });
    });
  }

  connectToNewUser(pid, stream) {
    debugPrint('connectToNewUser: $pid Stream: $stream');
    final call = peer.call(pid, stream);
    call.on('stream').listen((remoteStream) {
      _remoteRenderer.srcObject = remoteStream;
    });
  }

  joinRoom() {
    try {
      setState(() {
        waitingOnConnection = true;
        UserConnectionMsg = "Searching for a user...";
        joined = false;
      });

      socket!.emit('join room', ({peerID, video}));
      debugPrint('join room: $peerID $video');
      setState(() {
        waitingOnConnection = true;
        joined = false;
        _remoteRenderer.srcObject = null;
      });
      peer.on('call').listen((call) {
        call.answer(_localRenderer.srcObject);
        call.on('stream').listen((stream) {
          setState(() {
            _remoteRenderer.srcObject = stream;
            waitingOnConnection = false;
            joined = true;
            UserConnectionMsg = "Connected";
          });
        });
      });
    } catch (e) {
      debugPrint('join Room: $e');
    }
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

  serverMsg(msg) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "Server : $msg",
        style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
      ),
    );
  }

  strangerMsg(msg) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "stranger : $msg",
        style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
      ),
    );
  }

  @override
  void dispose() {
    peer.dispose();
    _msgController.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    socket!.disconnect();
    super.dispose();
  }

  void connect(String peerid) async {
    final mediaStream = await navigator.mediaDevices
        .getUserMedia({"video": true, "audio": false});

    // final conn = peer.call(_msgController.text, mediaStream);
    final conn = peer.call(peerid, mediaStream);

    conn.on("close").listen((event) {
      setState(() {
        inCall = false;
      });
    });

    conn.on<MediaStream>("stream").listen((event) {
      _remoteRenderer.srcObject = event;
      _localRenderer.srcObject = mediaStream;

      setState(() {
        inCall = true;
      });
    });

    // });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build');
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
      // bottomNavigationBar: Container(
      //   height: 50,
      //   color: const Color.fromARGB(255, 211, 211, 211),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: const [
      //       Expanded(
      //         child: TextField(
      //           decoration: InputDecoration(
      //             hintText: 'Enter Messages',
      //           ),
      //         ),
      //       ),
      //       IconButton(onPressed: null, icon: Icon(Icons.send)),
      //     ],
      //   ),
      // ),

      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            VideoRenderers(),
            ButtonSection(),
            UserJoinStatus(),
            MessageSection(),
            MessageArea(),
          ],
        ),
      ),
    );
  }

  MessageSection() {
    return Expanded(
        child: Column(
      children: [
        Container(
          child: SelectableText(peerID ?? ""),
        ),
        Text(UserConnectionMsg),
        Text(socketStatus ? "Socket Connected" : "Socket Disconnected"),
        Text(joined ? "Joined" : "Not Joined"),
      ],
    ));
  }

  MessageArea() {
    return Container(
      height: 50,
      color: const Color.fromARGB(255, 211, 211, 211),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: const InputDecoration(
                hintText: 'Enter Messages',
              ),
            ),
          ),
          // IconButton(onPressed: connect, icon: const Icon(Icons.send)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }

  UserJoinStatus() {
    return Container(
      width: double.infinity,
      height: 50,
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
