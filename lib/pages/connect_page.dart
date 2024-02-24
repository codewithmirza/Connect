import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/signaling.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  Signaling signaling = Signaling();
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  String? matchedUserId;
  MediaStream? localStream;
  String? uid;
  bool showSpinner = false;

  @override
  void initState() {
    super.initState();
    initRenderers();
    initUid();
    signaling.onAddRemoteStream = (stream) {
      remoteRenderer.srcObject = stream;
    };
    _initializeStream();
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> initUid() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        uid = user.uid; // Assign uid from current user
      });
    } else {
      // Handle if user is not authenticated
    }
  }

  Future<void> _initializeStream() async {
    final permissionsGranted = await _checkAndRequestPermissions();
    if (permissionsGranted) {
      final stream = await signaling.openUserMedia(localRenderer, remoteRenderer);
      if (stream != null) {
        setState(() {
          localStream = stream;
        });
      } else {
        print('Failed to get local media stream');
      }
    }
  }


  Future<bool> _checkAndRequestPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return true;
    } else if (cameraStatus.isPermanentlyDenied || microphoneStatus.isPermanentlyDenied) {
      print('Camera and/or microphone permissions are permanently denied');
      openAppSettings();
      return false;
    } else {
      final cameraPermissionStatus = await Permission.camera.request();
      final microphonePermissionStatus = await Permission.microphone.request();

      if (cameraPermissionStatus.isGranted && microphonePermissionStatus.isGranted) {
        return true;
      } else {
        print('Camera and/or microphone permissions are denied');
        return false;
      }
    }
  }

  @override
  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> findMatch() async {
    setState(() {
      showSpinner = true;
    });
    signaling.findMatch((matchedUserId) async {
      if (matchedUserId != null) {
        String? roomId = await signaling.createRoom(remoteRenderer);
        await signaling.joinRoom(roomId!, remoteRenderer);
      }
    });
  }

  Future<void> connect(String matchedUserId) async {
    String? roomId = await signaling.createRoom(remoteRenderer);
    await signaling.joinRoom(roomId!, remoteRenderer);
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: RTCVideoView(remoteRenderer),
          ),
          Expanded(
            flex: 1,
            child: RTCVideoView(localRenderer),
          ),
          ElevatedButton(
            onPressed: findMatch,
            child: const Text('Connect'),
          ),
          ElevatedButton(
            onPressed: () => signaling.hangUp(localRenderer),
            child: const Text('Hang up'),
          ),
          const SizedBox(height: 50),
          showSpinner ? const CircularProgressIndicator() : const Text('Please wait...'),
        ],
      ),
    );
  }
}
