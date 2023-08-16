//
//  RTPManager.swift
//  FireRTC
//
//  Created by young on 2023/08/10.
//

import Foundation
import WebRTC

class RTPManager: NSObject, RTCPeerConnectionDelegate {
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
    
    var factory: RTCPeerConnectionFactory?
    var pc: RTCPeerConnection?
    var iceServers = [RTCIceServer]()
    
    var localStream: RTCMediaStream?
    var localSDP: RTCSessionDescription?
    
    func initialize(
        isAudio: Bool = DefaultValues.isAudio,
        isVideo: Bool = DefaultValues.isVideo,
        isScreen: Bool = DefaultValues.isScreen,
        isDataChannel: Bool = DefaultValues.isDataChannel,
        enableStat: Bool = DefaultValues.enableStat,
        recordAudio: Bool = DefaultValues.recordAudio
    ) {
        self.isInit = true
        self.isAudio = isAudio
        self.isVideo = isVideo
        self.isScreen = isScreen
        self.isDataChannel = isDataChannel
        self.enableStat = enableStat
        self.recordAudio = recordAudio
        
        self.factory = RTCPeerConnectionFactory.init()
    }
    
    func release() {
        print("\(TAG) \(#function)")
        self.pc!.close()
        self.pc = nil
//        self.localStream.
    }
    
    func startRTP(isOffer: Bool, remoteSDP: RTCSessionDescription?) {
        print("\(TAG) \(#function)")
        self.isOffer = isOffer
        self.iceServers.append(defaultSTUNServer())
        
        if factory == nil {
            print("\(TAG) startRTP factory is nil")
            return
        }
        self.pc = factory!.peerConnection(with: defaultPCConfiguration(), constraints: defaultPCConstraints(), delegate: self)
        localStream = self.factory!.mediaStream(withStreamId: "ARDAMS")
        if (self.isAudio) {
            localStream!.addAudioTrack(AudioMedia().createAudioTrack(factory: self.factory!))
        }
        //TODO: if (self.isVideo) { //addVideoTrack }
        
        if isOffer {
            createOffer()
        } else if remoteSDP != nil {
            
        }
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
        URLSession().dataTask(with: requestUrl, completionHandler: { data, urlResponse, err in
            var turnServers = [RTCIceServer]()
            if let err = err {
                print("Unable to get TURN server.")
                handler(turnServers)
                return
            }
            let dict = Utils.dictionaryWithJSONData(jsonData: data)
            turnServers = Utils.serversFromDictionary(dict: dict)
            handler(turnServers)
        })
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue()) { response, data, err in
            var turnServers = [RTCIceServer]()
            if let err = err {
                print("Unable to get TURN server.")
                handler(turnServers)
                return
            }
            let dict = Utils.dictionaryWithJSONData(jsonData: data)
            turnServers = Utils.serversFromDictionary(dict: dict)
            handler(turnServers)
        }
    }
    
    private func createOffer() {
        if pc == nil {
            print("\(TAG) createOffer pc is nil")
            return
        }
        
        var mandatory = [String: String]()
        mandatory["OfferToReceiveAudio"] = String(self.isAudio)
        mandatory["OfferToReceiveVideo"] = String(self.isVideo)
        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatory, optionalConstraints: nil)
        self.pc!.offer(for: constraints) { sdp, err in
            if let error = err {
                print("\(self.TAG) createOffer Error!!!!!!!!!!!!! \(error)")
            } else {
                print("\(self.TAG) sdp is \(sdp!.sdp))")
                self.pc!.setLocalDescription(sdp!) { err in
                    if let err = err {
                        print("\(self.TAG) setLocalDescription failed \(err)")
                    } else {
                        print("\(self.TAG) setLocalDescription success")
                    }
                }
            }
        }
    }
    
    // PeerConnection Delegate
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
        print("\(TAG) \(#function) didAdd")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("\(TAG) \(#function) didRemove")
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
            case .completed:
                print("\(TAG) IceConnectionState completed")
            case .failed:
                print("\(TAG) IceConnectionState failed")
            case .disconnected:
                print("\(TAG) IceConnectionState disconnected")
            case .closed:
                print("\(TAG) IceConnectionState closed")
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
        print("\(TAG) \(#function) IceCandidate \(candidate.sdp)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("\(TAG) \(#function) IceCandidates count \(candidates.count)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("\(TAG) \(#function) dataChannel")
    }
}
