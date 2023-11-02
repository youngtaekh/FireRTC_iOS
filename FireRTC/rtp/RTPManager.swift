//
//  RTPManager.swift
//  FireRTC
//
//  Created by young on 2023/08/10.
//

import Foundation
import WebRTC

class RTPManager: NSObject {
    private let TAG = "RTPManager"
    
    private let defaultSTUNServerUrl = "stun:stun.l.google.com:19302"
    private let defaultTurnServerUrl =
    "https://computeengineondemand.appspot.com" +
    "/turn?username=iapprtc&key=4080218913"
    
    var isInit = false
    var isCreatedFactory = false
    
    // Options related RTP(PeerConnection)
    private var isOffer = true
    private var isAudio = true
    private var isVideo = false
    private var isScreen = false
    private var isDataChannel = false
    private var enableStat = true
    private var recordAudio = true
    
    var factory: RTCPeerConnectionFactory!
    var pc: RTCPeerConnection!
    var iceServers = [RTCIceServer]()
    let rtpMedia = RTPMedia()
    
    var localSDP: RTCSessionDescription?
    var remoteSessionDescription: RTCSessionDescription?
    var remoteICE = [String]()
    var defaultAudioSender: RTCRtpSender!
    var defaultAudioTrack: RTCMediaStreamTrack!
    
    var dc: RTCDataChannel!
    var sendDataChannel: RTCDataChannel!
    
    var rtpListener: RTPListener?
    
    func start(
        isAudio: Bool = DefaultValues.isAudio,
        isVideo: Bool = DefaultValues.isVideo,
        isScreen: Bool = DefaultValues.isScreen,
        isDataChannel: Bool = DefaultValues.isDataChannel,
        enableStat: Bool = DefaultValues.enableStat,
        recordAudio: Bool = DefaultValues.recordAudio,
        isOffer: Bool,
        remoteSDP: String? = nil,
        rtpListener: RTPListener
    ) {
        isInit = true
        self.isAudio = isAudio
        self.isVideo = isVideo
        self.isScreen = isScreen
        self.isDataChannel = isDataChannel
        self.enableStat = enableStat
        self.recordAudio = recordAudio
        
        factory = RTCPeerConnectionFactory.init()
        
        self.isOffer = isOffer
        iceServers.append(defaultSTUNServer())
        
        self.rtpListener = rtpListener
        
        pc = factory!.peerConnection(with: defaultPCConfiguration(), constraints: defaultPCConstraints(), delegate: self)
        if (isAudio) {
            let track = rtpMedia.createAudioTrack(factory: factory!)
            pc.add(track, streamIds: ["ARDAMS"])
        }
        if (isVideo && (!isScreen || isOffer)) {
            let track = rtpMedia.createVideoTrack(factory: factory!, isScreen: isScreen)
            pc?.add(track, streamIds: ["ARDAMS"])
            if (isScreen) {
                rtpMedia.startScreenShare()
            } else {
                startCapture()
            }
            self.rtpListener?.onLocalVideoTrack(track: track)
        }
        
        if (isDataChannel) {
            let config = RTCDataChannelConfiguration()
            config.isOrdered = DefaultValues.isOrdered
            config.isNegotiated = DefaultValues.isNegotiated
            config.maxRetransmits = DefaultValues.maxRetransmitPreference
            config.maxPacketLifeTime = DefaultValues.maxRetransmitTimeMs
            config.channelId = DefaultValues.dataId
            config.protocol = DefaultValues.subProtocol
            sendDataChannel = pc.dataChannel(forLabel: "message data", configuration: config)!
        }
        
        if isOffer {
            createOffer()
        } else if remoteSDP != nil {
            for ice in remoteICE {
                addRemoteCandidate(sdp: ice)
            }
            setRemoteDescription(isOffer: true, sdp: remoteSDP!)
        }
    }
    
    func release() {
        print("\(TAG) \(#function)")
        if isScreen && isOffer {
            rtpMedia.stopScreenShare()
        }
        pc?.close()
        pc = nil
    }
    
    func setRemoteDescription(isOffer: Bool, sdp: String) {
        let type: RTCSdpType = isOffer ? .offer : .answer
        let remoteDescription = RTCSessionDescription(type: type, sdp: sdp)
        pc!.setRemoteDescription(remoteDescription) { err in
            if let err = err {
                print("\(self.TAG) setRemoteDescription Error \(err)")
            } else {
                print("\(self.TAG) setRemoteDescription success size \(self.remoteICE.count)")
                if !self.isOffer {
                    self.createAnswer()
                }
                self.drainRemoteCandidate()
            }
        }
    }
    
    func addRemoteCandidate(sdp: String) {
        remoteICE.append(sdp)
        let candidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: 0, sdpMid: "0")
        pc?.add(candidate)
    }
    
    func drainRemoteCandidate() {
        for ice in remoteICE {
            print("drainRemoteCandidate \(ice)")
            let candidate = RTCIceCandidate(sdp: ice, sdpMLineIndex: 0, sdpMid: "0")
            pc!.add(candidate)
        }
    }
    
    func startCapture(isBack: Bool = false) {
        print("\(TAG) \(#function)")
        if isBack {
            rtpMedia.startCaptureLocalVideo(cameraPositon: .back)
        } else {
            rtpMedia.startCaptureLocalVideo()
        }
    }
    
    func stopCapture() {
        print("\(TAG) \(#function)")
        rtpMedia.stopCapture()
    }
    
    private func defaultPCConfiguration() -> RTCConfiguration {
        let config = RTCConfiguration()
        config.iceServers = [defaultSTUNServer()]
        config.tcpCandidatePolicy = .disabled
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .require
        config.continualGatheringPolicy = .gatherContinually
        config.keyType = .ECDSA
        config.sdpSemantics = .unifiedPlan
        return config
    }
    
    private func defaultPCConstraints() -> RTCMediaConstraints {
        var optional = [String: String]()
        optional["DtlsSrtpKeyAgreement"] = "true"
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optional)
        return constraints
    }
    
    private func defaultSTUNServer() -> RTCIceServer {
        return RTCIceServer(urlStrings: [defaultSTUNServerUrl], username: nil, credential: nil)
    }
    
    private func requestTURNServersWithURL(requestUrl: URL, handler: @escaping ([RTCIceServer]) -> Void) {
        var request = URLRequest(url: requestUrl)
        request.addValue("Mozilla/5.0", forHTTPHeaderField: "user-agent")
        request.addValue("https://apprtc.appspot.com", forHTTPHeaderField: "origin")
        
        //NSURLSession dataTaskWithRequest
//        URLSession().dataTask(with: requestUrl, completionHandler: { data, urlResponse, err in
//            var turnServers = [RTCIceServer]()
//            if err != nil {
//                print("Unable to get TURN server.")
//                handler(turnServers)
//                return
//            }
//            let dict = Utils.dictionaryWithJSONData(jsonData: data)
//            turnServers = Utils.serversFromDictionary(dict: dict)
//            handler(turnServers)
//        })
//        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue()) { response, data, err in
//            var turnServers = [RTCIceServer]()
//            if err != nil {
//                print("Unable to get TURN server. \(err)")
//                handler(turnServers)
//                return
//            }
//            let dict = Utils.dictionaryWithJSONData(jsonData: data)
//            turnServers = Utils.serversFromDictionary(dict: dict)
//            handler(turnServers)
//        }
    }
    
    private func createOffer() {
        if pc == nil {
            print("\(TAG) createOffer pc is nil")
            return
        }
        
        var mandatory = [String: String]()
        mandatory["OfferToReceiveAudio"] = String(isAudio)
        mandatory["OfferToReceiveVideo"] = String(isVideo)
        var optional = [String: String]()
        optional["DtlsSrtpKeyAgreement"] = kRTCMediaConstraintsValueTrue
        optional["RtpDataChannels"] = String(isDataChannel)
        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatory, optionalConstraints: optional)
        pc!.offer(for: constraints) { sdp, err in
            if let error = err {
                print("\(self.TAG) createOffer Error!!!!!!!!!!!!! \(error)")
            } else {
                self.onCreateSuccess(sdp: sdp!)
            }
        }
    }
    
    private func createAnswer() {
        if pc == nil {
            print("\(TAG) createAnswer pc is nil")
            return
        }
        
        var mandatory = [String: String]()
        mandatory["OfferToReceiveAudio"] = String(isAudio)
        mandatory["OfferToReceiveVideo"] = String(isVideo)
        var optional = [String: String]()
        optional["DtlsSrtpKeyAgreement"] = kRTCMediaConstraintsValueTrue
        optional["RtpDataChannels"] = String(isDataChannel)
        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatory, optionalConstraints: optional)
        pc?.answer(for: constraints) { sdp, err in
            if let error = err {
                print("\(self.TAG) createAnswer Error!!!! \(error)")
            } else {
                self.onCreateSuccess(sdp: sdp)
            }
        }
    }
    
    private func onCreateSuccess(sdp: RTCSessionDescription?) {
        rtpListener?.onDescriptionSuccess(type: sdp!.type.rawValue, sdp: sdp!.sdp)
        pc.setLocalDescription(sdp!) { err in
            if err == nil {
                print("setLocalDescription success")
            } else {
                print("setLocalDescription failure \(err!)")
            }
        }
    }
    
    func muteAudio() {
        for sender in pc!.senders {
            print("\(sender.streamIds) \(sender.senderId) \(sender.track == nil)")
            if (sender.senderId == "ARDAMSa0") {
                defaultAudioSender = sender
                defaultAudioTrack = sender.track!
                pc?.removeTrack(sender)
            }
        }
    }
    
    func unmuteAudio() {
        print("\(defaultAudioTrack == nil)")
        pc?.add(defaultAudioTrack ?? RTPMedia().createAudioTrack(factory: factory!), streamIds: defaultAudioSender.streamIds)
    }
    
    func sendData(msg: String) {
        print("\(TAG) sendData msg \(msg)")
        let buffer = RTCDataBuffer(data: msg.data(using: .utf8)!, isBinary: false)
        
        sendDataChannel.sendData(buffer)
    }
}

extension RTPManager: RTCPeerConnectionDelegate {

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        switch (stateChanged) {
            case .stable:
                print("\(TAG) SignalingState stable")
            case .haveLocalOffer:
                print("\(TAG) SignalingState haveLocalOffer")
            case .haveLocalPrAnswer:
                print("\(TAG) SignalingState haveLocalPrAnswer")
            case .haveRemoteOffer:
                print("\(TAG) SignalingState haveRemoteOffer")
            case .haveRemotePrAnswer:
                print("\(TAG) SignalingState haveRemotePrAnswer")
            case .closed:
                print("\(TAG) SignalingState closed")
            @unknown default:
                print("\(TAG) SignalingState default")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("\(TAG) \(#function)")
        print("\(TAG) \(#function) videoTrack.count \(stream.videoTracks.count)")
        if stream.videoTracks.count > 0 {
            DispatchQueue.main.async {
                self.rtpListener?.onRemoteVideoTrack(track: stream.videoTracks[0])
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("\(TAG) \(#function)")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("\(TAG) \(#function)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch (newState) {
            case .new:
                print("\(TAG) IceConnectionState new")
            case .checking:
                print("\(TAG) IceConnectionState checking")
            case .connected:
                print("\(TAG) IceConnectionState connected")
                rtpListener?.onPCConnected()
            case .completed:
                print("\(TAG) IceConnectionState completed")
            case .failed:
                print("\(TAG) IceConnectionState failed")
                rtpListener?.onPCFailed()
            case .disconnected:
                print("\(TAG) IceConnectionState disconnected")
                rtpListener?.onPCDisconnected()
            case .closed:
                print("\(TAG) IceConnectionState closed")
                rtpListener?.onPCClosed()
            case .count:
                print("\(TAG) IceConnectionState count")
            @unknown default:
                print("\(TAG) IceConnectionState default")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        switch (newState) {
            case .new:
                print("\(TAG) IceGatheringState new")
            case .gathering:
                print("\(TAG) IceGatheringState gathering")
            case .complete:
                print("\(TAG) IceGatheringState complete")
            @unknown default:
                print("\(TAG) IceGatheringState default")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("\(TAG) \(#function) IceCandidate")
        rtpListener?.onIceCandidate(candidate: candidate.sdp)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("\(TAG) \(#function) IceCandidates count \(candidates.count)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("\(TAG) \(#function) dataChannel")
        dc = dataChannel
        dc.delegate = self
    }
}

extension RTPManager: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("\(TAG) \(#function) label \(dataChannel.label), state \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        print("\(TAG) \(#function) label \(dataChannel.label), state \(dataChannel.readyState)")
        if (buffer.isBinary) {
            print("Received binary msg over \(dataChannel)")
            return
        }
        let data = buffer.data
        let message = String(decoding: data, as: UTF8.self)
        print("data \(message)")
        rtpListener?.onMessage(msg: message)
    }
}
