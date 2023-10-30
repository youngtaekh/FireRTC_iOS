//
//  AppDelegate.swift
//  FireRTC
//
//  Created by young on 2023/07/17.
//

import UIKit
import Firebase
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        return [[.banner, .list, .sound]]
    }
    
    // Receive FCM Message
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let fm = FirebaseMessage(data: userInfo)
        
        if (fm.type != nil) {
            print("didReceiveRemoteNotification(\(fm.userId!) \(fm.type!) \(fm.callType!) \(fm.targetOS!)")
            let callVM = CallViewModel.instance
            switch (SendFCM.FCMType(rawValue: fm.type!)) {
                case .Offer:
                    receiveOffer(firebaseMessage: fm)
                case .Answer:
                    receiveAnswer(firebaseMessage: fm)
                case .Cancel, .Decline, .Bye, .Busy:
                    if fm.callType == Call.Category.MESSAGE.rawValue {
                        MessageViewModel.instance.onTerminatedCall()
                    } else {
                        callVM.onTerminatedCall()
                    }
                case .Ice:
                    if fm.callType == Call.Category.MESSAGE.rawValue {
                        MessageViewModel.instance.addRemoteCandidate(sdp: fm.sdp!)
                    } else {
                        callVM.addRemoteCandidate(sdp: fm.sdp!)
                    }
                case .Message:
                    print("type is Message \(String(describing: fm.message))")
                    MessageViewModel.instance.onMessageReceived(firebaseMessage: fm)
                case .New:
                    print("type is New")
                case .Leave:
                    print("type is Leave")
                case .Sdp:
                    print("type is Sdp")
                case .none:
                    print("type is none")
                case .Else:
                    print("type is Else")
            }
        } else {
            print("AppDelegate didReceiveRemoteNotification type is nil")
        }
    }
    
    func receiveOffer(firebaseMessage fm: FirebaseMessage) {
        if (CallViewModel.instance.space != nil) {
            let category = Call.Category(rawValue: fm.callType!) ?? .AUDIO
            SendFCM.sendMessage(
                payload: SendFCM.getPayload(
                    to: fm.fcmToken!,
                    type: .Busy,
                    callType: category,
                    targetOS: fm.targetOS
                )
            )
            SpaceRepository.getSpace(id: fm.spaceId!) { result in
                switch (result) {
                    case .success(let space):
                        print("getSpace success \(space)")
                        CallViewModel.instance.busy()
                    case .failure(let err):
                        print("getSpace failure \(err)")
                }
            }
            let call = Call(spaceId: fm.spaceId!, type: category, direction: .Answer, terminated: true)
            SpaceRepository.addCallList(spaceId: fm.spaceId!, callId: call.id)
            CallRepository.post(call: call) { err in
                if err != nil {
                    print("post call failure \(err!)")
                }
            }
        } else if (fm.callType == Call.Category.MESSAGE.rawValue) {
            MessageViewModel.instance.onIncomingCall(firebaseMessage: fm)
        } else {
            let callVM = CallViewModel.instance
            CallRepository.getCall(id: fm.callId!) { result in
                switch (result) {
                    case .success(let call):
                        if call.sdp != nil {
                            callVM.onIncomingCall(firebaseMessage: fm, remoteSDP: call.sdp!)
                        }
                    case .failure(let err):
                        print("failure \(err)")
                }
            }
        }
    }
    
    func receiveAnswer(firebaseMessage fm: FirebaseMessage) {
        if (fm.callType == Call.Category.MESSAGE.rawValue) {
            MessageViewModel.instance.onAnswerCall(sdp: fm.sdp)
        } else {
            let callVM = CallViewModel.instance
            CallRepository.getCall(id: fm.callId!) { result in
                switch (result) {
                    case .success(let call):
                        if call.sdp != nil {
                            callVM.onAnswerCall(isOffer: false, sdp: call.sdp!)
                        }
                    case .failure(let err):
                        print("failure \(err)")
                }
            }
        }
    }
    
}

extension AppDelegate: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if (fcmToken != nil) {
            print("fcmToken: \(fcmToken!)")
            SharedPreference.instance.setFcmToken(token: fcmToken!)
        }
    }
}

extension UIViewController {
    func hideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
