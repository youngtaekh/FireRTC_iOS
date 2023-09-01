//
//  AudioMedia.swift
//  FireRTC
//
//  Created by young on 2023/08/11.
//

import Foundation
import WebRTC
import AVFoundation

class RTPMedia: NSObject {
    func createAudioTrack(factory: RTCPeerConnectionFactory) -> RTCAudioTrack {
        let track = factory.audioTrack(withTrackId: "ARDAMSa0")
        return track
    }
    
    func createVideoTrack(factory: RTCPeerConnectionFactory) -> RTCVideoTrack {
        var cameraID: String? = nil
        let source: RTCVideoSource = factory.videoSource()
        let capturer: RTCCameraVideoCapturer = RTCCameraVideoCapturer(delegate: source)
        for device in AVCaptureDevice.devices() {
            if device.position == AVCaptureDevice.Position.front {
                capturer.startCapture(with: device, format: device.activeFormat, fps: 30)
                cameraID = device.localizedName
                break
            }
        }
        
        let track = factory.videoTrack(with: source, trackId: "ARDAMSv0")
        return track
    }
}

extension RTPMedia: RTCVideoCapturerDelegate {
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        print("RTPMedia RTCVideoCapturerDelegate capturer")
    }
}
