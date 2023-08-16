//
//  AudioMedia.swift
//  FireRTC
//
//  Created by young on 2023/08/11.
//

import Foundation
import WebRTC

class AudioMedia {
    func createAudioTrack(factory: RTCPeerConnectionFactory) -> RTCAudioTrack {
        let track = factory.audioTrack(withTrackId: "ARDAMSa0")
        let source: RTCAudioSource = track.source
        return track
    }
}
