//
//  VideoCallController.swift
//  FireRTC
//
//  Created by young on 2023/10/10.
//

import UIKit
import WebRTC

class VideoCallController: UIViewController {
    private let TAG = "VideoCallController"
    
    @IBOutlet weak var remoteViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var localViewHeight: NSLayoutConstraint!
    @IBOutlet weak var localViewWidth: NSLayoutConstraint!
    @IBOutlet weak var localViewBottom: NSLayoutConstraint!
    @IBOutlet weak var localViewRight: NSLayoutConstraint!
    
    @IBOutlet weak var remoteView: RTCEAGLVideoView!
    @IBOutlet weak var localView: RTCEAGLVideoView!
    
    @IBOutlet weak var ivMute: UIButton!
    @IBOutlet weak var ivCameraMute: UIButton!
    @IBOutlet weak var ivChangeCamera: UIButton!
    @IBOutlet weak var ivChangeScalingType: UIButton!

    @IBOutlet weak var tvName: PaddingLabel!
    @IBOutlet weak var tvTime: PaddingLabel!
    
    var localVideoTrack: RTCVideoTrack!
    var remoteVideoTrack: RTCVideoTrack!
    
    var localVideoSize: CGSize? = nil
    var remoteVideoSize: CGSize? = nil
    
    let callVM = CallViewModel.instance
    var isOffer: Bool = true
    var isMute = false
    var isCameraMute = false
    var isBackCamera = false
    var scaleType = false
    
    var user: User!
    
    var terminated: Bool? {
        didSet {
            print("terminated didSet")
            MoveTo.popController(ui: self, action: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(TAG) viewDidLoad")
        
        callVM.controllerEvent = self
        callVM.videoEvent = self
        if (isOffer) {
            callVM.counterpart = user
            callVM.startCall(callType: .VIDEO, counterpart: user!)
        } else {
            user = callVM.counterpart
            callVM.answerCall()
        }
        
        tvName.text = user.name
        tvTime.text = "(00 : 00)"
        
        self.remoteView.delegate = self
        self.localView.delegate = self
    }
    
    @IBAction func endCall(_ sender: Any) {
        print("\(TAG) endCall")
        callVM.endCall()
    }
    
    @IBAction func mute(_ sender: Any) {
        print("\(TAG) mute \(isMute)")
        if isMute {
            callVM.unmute()
            ivMute.setImage(UIImage(systemName: "mic.slash.fill"), for: .normal)
        } else {
            callVM.mute()
            ivMute.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        }
        isMute = !isMute
    }
    
    @IBAction func cameraMute(_ sender: Any) {
        print("\(TAG) cameraMute \(isCameraMute)")
        if isCameraMute {
            callVM.startCapture(isBack: false)
            ivCameraMute.setImage(UIImage(systemName: "video.slash.fill"), for: .normal)
        } else {
            callVM.stopCapture()
            ivCameraMute.setImage(UIImage(systemName: "video.fill"), for: .normal)
        }
        isCameraMute = !isCameraMute
    }
    
    @IBAction func cameraSwitch(_ sender: Any) {
        print("\(TAG) cameraSwitch \(isBackCamera)")
        isBackCamera  = !isBackCamera
        callVM.startCapture(isBack: isBackCamera)
    }
    
    @IBAction func changeScalingType(_ sender: Any) {
        print("\(TAG) changeScalingType")
    }
    
    private func changeViewSize(isLocal: Bool, isFull: Bool, size: CGSize? = nil) {
        UIView.animate(withDuration: 0.4) {
            let containerWidth = self.view.frame.size.width
            let containerHeight = self.view.frame.size.height
            let defaultAspectRatio = CGSizeMake(4, 3)
            var videoRect = CGRectMake(0.0, 0.0, self.view.frame.size.width / 4.0, self.view.frame.size.height / 4.0)
            let videoFrame = AVMakeRect(aspectRatio: self.localView.frame.size, insideRect: videoRect)
            print("changeViewSize width \(videoFrame.size.width) height \(videoFrame.size.height)")
            if isLocal {
                if isFull {
                    
                }
            }
        }
    }
}

extension VideoCallController: ControllerEvent {
    func onTerminatedCall() {
        print("\(TAG) onTerminatedCall")
        MoveTo.popController(ui: self, action: true)
    }
    
    func onPCConnected() {
        print("\(TAG) onPCConnected")
    }
}

extension VideoCallController: VideoEvent {
    func onLocalVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) onLocalVideoTrack")
        self.localVideoTrack = track
        self.localVideoTrack.add(self.localView)
//        changeViewSize(isLocal: true, isFull: true)
        print("\(TAG) rotation \(self.localView.rotationOverride)")
    }
    
    func onRemoteVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) onRemoteVideoTrack")
        self.remoteVideoTrack = track
        self.remoteVideoTrack.add(self.remoteView)
    }
}

extension VideoCallController: RTCVideoViewDelegate {
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        print("\(TAG) \(#function) size \(size)")
        UIView.animate(withDuration: 0.4) {
            let defaultAspectRatio = CGSizeMake(4, 3);
            let aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size
            var videoRect = self.view.bounds
            
            if videoView as? RTCEAGLVideoView == self.remoteView {
                print("\(self.TAG) remoteView")
                self.remoteVideoSize = size
                var videoFrame = AVMakeRect(aspectRatio: aspectRatio, insideRect: videoRect)
                print("\(self.TAG) width \(videoFrame.size.width) height \(videoFrame.size.height)")
                self.remoteViewHeight.constant = videoFrame.size.height * self.view.frame.width / videoFrame.size.width
                
                videoRect = CGRectMake(0.0, 0.0, self.view.frame.size.width / 4.0, self.view.frame.size.height / 4.0)
                videoFrame = AVMakeRect(aspectRatio: self.localVideoSize!, insideRect: videoRect)
                print("\(self.TAG) width \(videoFrame.size.width) height \(videoFrame.size.height)")
                self.localViewWidth.constant = videoFrame.size.width
                self.localViewHeight.constant = videoFrame.size.height
                self.localViewRight.constant = 20.0
                self.localViewBottom.constant = 80.0
            } else {
                print("\(self.TAG) localView")
                self.localVideoSize = size
                if (self.remoteVideoTrack != nil) {
                    videoRect = CGRectMake(0.0, 0.0, self.view.frame.size.width / 4.0, self.view.frame.size.height / 4.0)
                    let videoFrame = AVMakeRect(aspectRatio: aspectRatio, insideRect: videoRect)
                    print("\(self.TAG) width \(videoFrame.size.width) height \(videoFrame.size.height)")
                    self.localViewWidth.constant = videoFrame.size.width
                    self.localViewHeight.constant = videoFrame.size.height
                    self.localViewRight.constant = 20.0
                    self.localViewBottom.constant = 80.0
                } else {
                    let videoFrame = AVMakeRect(aspectRatio: aspectRatio, insideRect: videoRect)
                    print("\(self.TAG) width \(videoFrame.size.width) height \(videoFrame.size.height)")
                    self.localViewWidth.constant = self.view.frame.width
                    self.localViewHeight.constant = videoFrame.size.height * self.view.frame.width / videoFrame.size.width
                    self.localViewRight.constant = 0.0
                    self.localViewBottom.constant = (self.view.frame.height - self.localViewHeight.constant) / 2.0
                }
            }
        }
    }
}
