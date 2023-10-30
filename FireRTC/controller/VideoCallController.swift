//
//  VideoCallController.swift
//  FireRTC
//
//  Created by young on 2023/10/10.
//

import UIKit
import WebRTC

//TODO: change scale type
class VideoCallController: UIViewController {
    private let TAG = "VideoCallController"
    
    @IBOutlet weak var remoteViewHeight: NSLayoutConstraint!
    @IBOutlet weak var remoteViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var localViewHeight: NSLayoutConstraint!
    @IBOutlet weak var localViewWidth: NSLayoutConstraint!
    @IBOutlet weak var localViewBottom: NSLayoutConstraint!
    @IBOutlet weak var localViewRight: NSLayoutConstraint!
    
    @IBOutlet weak var pipButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var pipButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var pipButtonBottom: NSLayoutConstraint!
    @IBOutlet weak var pipButtonRight: NSLayoutConstraint!
    
    @IBOutlet weak var fullButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var fullButtonWidth: NSLayoutConstraint!

    @IBOutlet weak var remoteView: RTCEAGLVideoView!
    @IBOutlet weak var localView: RTCEAGLVideoView!
    
    @IBOutlet weak var remoteViewButton: UIButton!
    @IBOutlet weak var localViewButton: UIButton!
    
    @IBOutlet weak var buttons: UIStackView!
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
    var isScreen = false
    var isSwap = false
    var isHiddenButton = false
    var startTime = Date().timeIntervalSince1970
    var timer: Timer?
    
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
            callVM.startCall(callType: isScreen ? .SCREEN : .VIDEO, counterpart: user!)
        } else {
            user = callVM.counterpart
            callVM.answerCall()
        }
        
        tvName.text = user.name
        tvTime.text = isOffer ? "Calling..." : ""
        
        remoteView.delegate = self
        localView.delegate = self
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
    
    @IBAction func swapVideoView(_ sender: Any) {
        print("swapVideoView - \(isSwap)")
        isSwap = !isSwap
        
        if isSwap {
            remoteVideoTrack.remove(remoteView)
            localVideoTrack.remove(localView)
            remoteVideoTrack.add(localView)
            localVideoTrack.add(remoteView)
            setMirror(view: remoteView, isMirror: true)
            setMirror(view: localView, isMirror: false)
        } else {
            remoteVideoTrack.remove(localView)
            localVideoTrack.remove(remoteView)
            remoteVideoTrack.add(remoteView)
            localVideoTrack.add(localView)
            setMirror(view: remoteView, isMirror: false)
            setMirror(view: localView, isMirror: true)
        }
    }
    
    @IBAction func toggleButton(_ sender: Any) {
        print("toggleButton isHiddenButton \(isHiddenButton)")
        isHiddenButton = !isHiddenButton
        
        buttons.isHidden = isHiddenButton
        tvName.isHidden = isHiddenButton
        tvTime.isHidden = isHiddenButton
    }
    
    private func setMirror(view: RTCEAGLVideoView, isMirror: Bool) {
        if isMirror {
            let transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
            view.transform = transform.rotated(by: Double.pi)
        } else {
            let transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            view.transform = transform.rotated(by: 0.0)
        }
    }
    
    private func changeViewSize() {

        let defaultAspectRatio = CGSizeMake(4, 3);
        let remoteAspectRatio = remoteVideoSize == nil ? defaultAspectRatio : CGSizeEqualToSize(remoteVideoSize!, CGSizeZero) ? defaultAspectRatio : remoteVideoSize!
        let localAspectRatio = localVideoSize == nil ? defaultAspectRatio : CGSizeEqualToSize(localVideoSize!, CGSizeZero) ? defaultAspectRatio : localVideoSize!
        
        let fullVideoRect = view.bounds
        let pipVideoRect = CGRectMake(0.0, 0.0, view.frame.size.width / 4.0, view.frame.size.height / 4.0)
        
        if remoteVideoTrack == nil || isScreen && isOffer {
            
            let videoFrame = AVMakeRect(aspectRatio: localAspectRatio, insideRect: fullVideoRect)
            localViewWidth.constant = view.frame.width
            localViewHeight.constant = videoFrame.size.height * view.frame.width / videoFrame.size.width
            localViewRight.constant = 0.0
            localViewBottom.constant = (view.frame.height - localViewHeight.constant) / 2.0
            
        } else if remoteVideoTrack != nil && !isScreen {
            
            let remoteVideoFrame = AVMakeRect(aspectRatio: remoteAspectRatio, insideRect: fullVideoRect)
            remoteViewWidth.constant = view.frame.width
            remoteViewHeight.constant = remoteVideoFrame.size.height * view.frame.width / remoteVideoFrame.size.width
            fullButtonWidth.constant = view.frame.width
            fullButtonHeight.constant = remoteVideoFrame.size.height * view.frame.width / remoteVideoFrame.size.width
            
            let localVideoFrame = AVMakeRect(aspectRatio: localAspectRatio, insideRect: pipVideoRect)
            localViewWidth.constant = localVideoFrame.size.width
            localViewHeight.constant = localVideoFrame.size.height
            localViewRight.constant = 20.0
            localViewBottom.constant = 80.0
            
            pipButtonWidth.constant = localVideoFrame.size.width
            pipButtonHeight.constant = localVideoFrame.size.height
            pipButtonRight.constant = 20.0
            pipButtonBottom.constant = 80.0

        } else {

            let remoteVideoFrame = AVMakeRect(aspectRatio: remoteAspectRatio, insideRect: fullVideoRect)
            remoteViewHeight.constant = remoteVideoFrame.size.height
            fullButtonHeight.constant = remoteVideoFrame.size.height
            
            localViewWidth.constant = 0.0
            localViewHeight.constant = 0.0
        }
    }
    
    private func parseTime(time: Int) {
        if time >= 3600 {
            let hour = time / 3600
            let min = (time % 3600) / 60
            let sec = time % 60
            tvTime.text = String(format: "(%02d : %02d : %02d)", hour, min, sec)
        } else {
            let min = time / 60
            let sec = time % 60
            tvTime.text = String(format: "(%02d : %02d)", min, sec)
        }
    }
}

extension VideoCallController: ControllerEvent {
    func onTerminatedCall() {
        print("\(TAG) onTerminatedCall")
        MoveTo.popController(ui: self, action: true)
        timer?.invalidate()
    }
    
    func onPCConnected() {
        print("\(TAG) onPCConnected")
        startTime = Date().timeIntervalSince1970
        print("\(TAG) \(#function) \(startTime)")
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { timer in
                let time = Int(Date().timeIntervalSince1970 - self.startTime)
                self.parseTime(time: time)
            })
        }
    }
}

extension VideoCallController: VideoEvent {
    func onLocalVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) onLocalVideoTrack")
        localVideoTrack = track
        localVideoTrack.add(localView)
        setMirror(view: localView, isMirror: true)
    }
    
    func onRemoteVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) onRemoteVideoTrack")
        remoteVideoTrack = track
        remoteVideoTrack.add(remoteView)
    }
}

extension VideoCallController: RTCVideoViewDelegate {
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
            
        if videoView as? RTCEAGLVideoView == remoteView {
            print("\(TAG) \(#function) remoteTrack size \(size)")
            remoteVideoSize = size
        } else {
            print("\(TAG) \(#function) localTrack size \(size)")
            localVideoSize = size
        }
        
        UIView.animate(withDuration: 0.4) {
            self.changeViewSize()
        }
    }
}
