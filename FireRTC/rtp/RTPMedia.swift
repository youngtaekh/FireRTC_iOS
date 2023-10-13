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
    var videoCapturer: RTCVideoCapturer?
    
    func createAudioTrack(factory: RTCPeerConnectionFactory) -> RTCAudioTrack {
        let track = factory.audioTrack(withTrackId: "ARDAMSa0")
        return track
    }
    
    func createVideoTrack(factory: RTCPeerConnectionFactory) -> RTCVideoTrack {
        let source: RTCVideoSource = factory.videoSource()
        self.videoCapturer = RTCCameraVideoCapturer(delegate: source)
        
        let track = factory.videoTrack(with: source, trackId: "ARDAMSv0")
        return track
    }
    
    func stopCapture() {
        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
            capturer.stopCapture()
        }
    }
    
    func startCaptureLocalVideo(cameraPositon: AVCaptureDevice.Position = .front, videoWidth: Int = 640, videoHeight: Int = 640 * 16 / 9, videoFps: Int = 30) {
        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
            print("RTPMedia startCameraVideoCapturer")
            var targetDevice: AVCaptureDevice?
            var targetFormat: AVCaptureDevice.Format?
            
            // find target device
            let devicies = RTCCameraVideoCapturer.captureDevices()
            devicies.forEach { (device) in
                if device.position ==  cameraPositon{
                    targetDevice = device
                }
            }
            
            // find target format
            let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice!)
            formats.forEach { (format) in
                for _ in format.videoSupportedFrameRateRanges {
                    let description = format.formatDescription as CMFormatDescription
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    
                    if dimensions.width == videoWidth && dimensions.height == videoHeight ?? 0{
                        targetFormat = format
                    } else if dimensions.width == videoWidth {
                        targetFormat = format
                    }
                }
            }
            
            capturer.startCapture(with: targetDevice!,
                                  format: targetFormat!,
                                  fps: videoFps)
        } else if let capturer = self.videoCapturer as? RTCFileVideoCapturer{
            print("setup file video capturer")
            if let _ = Bundle.main.path( forResource: "sample.mp4", ofType: nil ) {
                capturer.startCapturing(fromFileNamed: "sample.mp4") { (err) in
                    print(err)
                }
            }else{
                print("file did not faund")
            }
        }
    }
}

extension RTPMedia: RTCVideoCapturerDelegate {
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        print("RTPMedia RTCVideoCapturerDelegate capturer")
    }
}
