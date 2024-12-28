import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final _isInCall = false.obs;
  final _isMuted = false.obs;

  late RTCVideoRenderer localRenderer;
  late RTCVideoRenderer remoteRenderer;
  MediaStream? localStream;
  RTCPeerConnection? peerConnection;
  IO.Socket? socket;

  bool get isInCall => _isInCall.value;
  bool get isMuted => _isMuted.value;

  @override
  void onInit() {
    super.onInit();
    _initializeRenderers();
    _connectSocket();
    _requestPermissions();
  }

  Future<void> _initializeRenderers() async {
    localRenderer = RTCVideoRenderer();
    remoteRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  void _connectSocket() {
    socket = IO.io('http://your-server:3000',
        IO.OptionBuilder().setTransports(['websocket']).build());

    socket?.on('offer', (data) async => await _handleOffer(data));
    socket?.on('answer', (data) async => await _handleAnswer(data));
    socket?.on(
        'ice-candidate', (data) async => await _handleIceCandidate(data));
  }

  Future<void> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    peerConnection = await createPeerConnection(configuration);

    peerConnection?.onIceCandidate = (candidate) {
      socket?.emit('ice-candidate', {
        'candidate': candidate.toMap(),
      });
    };

    peerConnection?.onTrack = (event) {
      remoteRenderer.srcObject = event.streams[0];
    };

    localStream =
        await mediaDevices.getUserMedia({'audio': true, 'video': false});

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });
  }

  Future<void> _handleOffer(dynamic data) async {
    await _createPeerConnection();
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(data['sdp'], data['type']),
    );

    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection?.setLocalDescription(answer);

    socket?.emit('answer', {
      'type': answer.type,
      'sdp': answer.sdp,
    });
  }

  Future<void> _handleAnswer(dynamic data) async {
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(data['sdp'], data['type']),
    );
  }

  Future<void> _handleIceCandidate(dynamic data) async {
    await peerConnection?.addCandidate(
      RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      ),
    );
  }

  Future<void> startCall() async {
    await _createPeerConnection();
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection?.setLocalDescription(offer);

    socket?.emit('offer', {
      'type': offer.type,
      'sdp': offer.sdp,
    });

    _isInCall.value = true;
  }

  void endCall() {
    localStream?.getTracks().forEach((track) => track.stop());
    peerConnection?.close();
    localStream?.dispose();
    peerConnection = null;
    localStream = null;
    _isInCall.value = false;
  }

  void toggleMute() {
    if (localStream != null) {
      final audioTrack = localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
      _isMuted.value = !audioTrack.enabled;
    }
  }

  @override
  void onClose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    socket?.disconnect();
    endCall();
    super.onClose();
  }
}
