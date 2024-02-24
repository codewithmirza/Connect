import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class Signaling {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('Users');
  final CollectionReference roomsCollection =
  FirebaseFirestore.instance.collection('rooms');

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? myUserId;
  String? matchedUserId;

  final Map<String, dynamic> iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:global.stun.twilio.com:3478?transport=udp'},
      {
        'urls': 'turn:numb.viagenie.ca',
        'credential': 'webrtc',
        'username': 'webrtc@live.com'
      },
    ]
  };

  Signaling() {
    FirebaseFirestore.instance.settings =
        Settings(persistenceEnabled: false);
  }

  StreamStateCallback? onAddRemoteStream;

  Future<String?> createRoom(RTCVideoRenderer remoteRenderer) async {
    DocumentReference roomRef = roomsCollection.doc();
    String roomId = roomRef.id;

    peerConnection = await createPeerConnection(iceServers);
    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    await roomRef.set({'offer': null, 'answer': null});
    print('New room created with ID: $roomId');

    peerConnection?.onTrack = (RTCTrackEvent event) {
      print('Got remote track: ${event.streams[0]}');

      event.streams[0].getTracks().forEach((track) {
        print('Add a track to the remoteStream: $track');
        remoteStream?.addTrack(track);
      });
    };

    myUserId = await generateUserId();
    usersCollection.doc(myUserId).update({'isAvailable': false});
    usersCollection
        .doc(myUserId)
        .collection('incomingCalls')
        .doc(myUserId)
        .set({'callFrom': 'self', 'callTo': 'self', 'isIncoming': false});

    return roomId;
  }

  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteRenderer) async {
    DocumentReference roomRef = roomsCollection.doc(roomId);
    var roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      print('Create PeerConnection with configuration: $iceServers');
      peerConnection = await createPeerConnection(iceServers);
      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      var data = roomSnapshot.data() as Map<String, dynamic>;
      var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
      await peerConnection?.setRemoteDescription(answer);

      peerConnection!.onTrack = (RTCTrackEvent event) {
        print('Got remote track: ${event.streams[0]}');
        event.streams[0].getTracks().forEach((track) {
          print('Add a track to the remoteStream: $track');
          remoteStream?.addTrack(track);
        });
      };

      myUserId = await generateUserId();
      usersCollection
          .doc(myUserId)
          .update({'isIncoming': true, 'roomId': roomRef.id, 'calleeId': myUserId});
    }
  }

  Future<void> findMatch(Function(String?) callback) async {
    CollectionReference users = FirebaseFirestore.instance.collection('Users');

    // Create a room reference
    DocumentReference roomRef = roomsCollection.doc();
    String roomId = roomRef.id;

    // Query users who are available and not currently in a call
    QuerySnapshot availableUsers = await users.where('isAvailable', isEqualTo: true)
        .where('isIncoming', isEqualTo: false)
        .get();

    if (availableUsers.docs.isEmpty) {
      print('No users are available right now');
    } else {
      // Randomly select a user from the available users
      final matchedUser = availableUsers.docs[Random().nextInt(availableUsers.docs.length)];
      matchedUserId = matchedUser.id;

      // Update matched user's status
      await usersCollection.doc(matchedUserId).update({
        'isAvailable': false,
        'isIncoming': true,
        'roomId': roomId
      });

      // Update current user's status
      await usersCollection.doc(myUserId).update({
        'isIncoming': false,
        'calleeId': matchedUserId
      });

      callback(matchedUserId);
    }
  }

  Future<MediaStream?> openUserMedia(
      RTCVideoRenderer localVideo,
      RTCVideoRenderer remoteVideo,
      ) async {
    try {
      MediaStream stream = await navigator.mediaDevices.getUserMedia(
        {'video': true, 'audio': true},
      );

      localVideo.srcObject = stream;

      remoteVideo.srcObject = await createLocalMediaStream('key');

      return stream;
    } catch (e) {
      print('Failed to get user media: $e');
      return null;
    }
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    localVideo.srcObject!.getTracks().forEach((track) {
      track.stop();
    });

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    await roomsCollection.doc(roomId).delete();

    if (usersCollection != null) {
      CollectionReference users =
      FirebaseFirestore.instance.collection('Users');
      await users
          .where('isIncoming', isEqualTo: true)
          .get()
          .then((value) async {
        if (value.docs.isNotEmpty) {
          for (DocumentSnapshot doc in value.docs) {
            if (doc['calleeId'] == myUserId) {
              await doc.reference.update({'isIncoming': false});
            }
          }
        }
      });
    }

    localStream!.dispose();
    remoteStream?.dispose();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('Got candidate: ${candidate.toMap()}');
      roomsCollection.doc(roomId).collection('calleeCandidates').add(candidate.toMap());
    };

    peerConnection?.onIceConnectionState = (state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };

    peerConnection?.onRemoveStream = (MediaStream stream) {
      print('Remove remote stream');
      remoteStream = null;
    };

    peerConnection?.onRenegotiationNeeded = () {
      print('Renegotiation needed');
    };
  }

  Future<String> generateUserId() async {
    String userId = '';
    for (int i = 0; i < 11; i++) {
      userId += (i == 0 || i == 6) ? '' : '-';
      userId += (Random().nextInt(9) + 1).toString();
    }
    return userId;
  }

  Future<void> createOffer() async {
    RTCSessionDescription description = await peerConnection!.createOffer();
    peerConnection!.setLocalDescription(description);

    Map<String, dynamic> roomWithOffer = {'offer': description.toMap()};

    await roomsCollection.doc(roomId).update(roomWithOffer);
  }

  Future<void> createAnswer() async {
    RTCSessionDescription description = await peerConnection!.createAnswer();
    peerConnection!.setLocalDescription(description);

    Map<String, dynamic> roomWithAnswer = {'answer': description.toMap()};

    await roomsCollection.doc(roomId).update(roomWithAnswer);
  }

  Future<void> addCandidate(RTCIceCandidate candidate) async {
    peerConnection!.addCandidate(candidate);
  }
}