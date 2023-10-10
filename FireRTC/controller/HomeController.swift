//
//  HomeController.swift
//  FireRTC
//
//  Created by young on 2023/07/18.
//

import UIKit
import AVFAudio
import AVFoundation

class HomeController: UITabBarController {
    private let TAG = "HomeController"
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var ivAddContact: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("\(TAG) \(#function)")
//        ivAddContact.frame = CGRectMake(-100, -100, 0, 0)
//        navigationBar.title = "Title"
        let tabIndex = SharedPreference.instance.getTabIndex()
        selectedIndex = tabIndex
        if (tabIndex == 0) {
            ivAddContact.isHidden = false
            navigationBar.title = "Contacts"
        } else if (tabIndex == 1) {
            ivAddContact.isHidden = true
            navigationBar.title = "History"
        } else {
            ivAddContact.isHidden = true
            navigationBar.title = "Settings"
        }
        requestMicrophonePermission()
        requestCameraPermission()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("\(TAG) \(#function)")
        
        let sp = SharedPreference.instance
        if (!sp.isSign()) {
            let _ = MoveTo.controller(ui: self, identifier: MoveTo.signIdentifier)
        }
        let tabIndex = sp.getTabIndex()
        selectedIndex = tabIndex
        if (tabIndex == 0) {
            ivAddContact.isHidden = false
            navigationBar.title = "Contacts"
        } else if (tabIndex == 1) {
            ivAddContact.isHidden = true
            navigationBar.title = "History"
        } else {
            ivAddContact.isHidden = true
            navigationBar.title = "Settings"
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if (tabBar.items != nil) {
            let sp = SharedPreference.instance
            if (tabBar.items!.firstIndex(of: item) == 0) {
                ivAddContact.isHidden = false
                navigationBar.title = "Contacts"
                sp.setTabIndex(value: 0)
            } else if (tabBar.items!.firstIndex(of: item) == 1) {
                ivAddContact.isHidden = true
                navigationBar.title = "History"
                sp.setTabIndex(value: 1)
            } else {
                ivAddContact.isHidden = true
                navigationBar.title = "Settings"
                sp.setTabIndex(value: 2)
            }
        } else {
            ivAddContact.isHidden = true
        }
    }
    
    @IBAction func addContact(_ sender: Any) {
        print("\(TAG) \(#function)")
        let _ = MoveTo.controller(ui: self, identifier: MoveTo.addContactIdentifier, action: true)
    }
    
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
            if granted {
                print("Mic: 권한 허용")
            } else {
                print("Mic: 권한 거부")
            }
        })
    }
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
            if granted {
                print("Camera: 권한 허용")
            } else {
                print("Camera: 권한 거부")
            }
        })
    }
}
