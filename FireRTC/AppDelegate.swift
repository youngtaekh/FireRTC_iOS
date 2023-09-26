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
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
//            UNUserNotificationCenter.current().delegate = self
//
//            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//            UNUserNotificationCenter.current().requestAuthorization(
//                options: authOptions,
//                completionHandler: { _, _ in }
//            )
        } else {
//            let settings: UIUserNotificationSettings =
//            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        print("asdf")
//        return [[.list, .sound]]
        return [[.banner, .list, .sound]]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        print("zxcv")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("didReceiveRemoteNotification")
    }
    
    // Receive FCM Message
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let userId = userInfo[USER_ID] as? String
        let type = userInfo[TYPE] as? String
        let spaceId = userInfo[SPACE_ID] as? String
        let callId = userInfo[CALL_ID] as? String
        let chatId = userInfo[CHAT_ID] as? String
        let callType = userInfo[CALL_TYPE] as? String
        let sdp = userInfo[SDP] as? String
        let fcmToken = userInfo[FCM_TOKEN] as? String
        let message = userInfo[MESSAGE] as? String
        print("didReceiveRemoteNotification(\(userId!) \(type!) \(callType!)")
        
        if (type != nil) {
            let callVM = CallViewModel.instance
            switch (SendFCM.FCMType(rawValue: type!)) {
                case .Offer:
                    receiveOffer(spaceId: spaceId, callId: callId, chatId: chatId, callType: callType!, userId: userId!, sdp: sdp, fcmToken: fcmToken!)
                case .Answer:
                    receiveAnswer(callId: callId, callType: callType!, sdp: sdp)
                case .Cancel, .Decline, .Bye, .Busy:
                    if callType == Call.Category.MESSAGE.rawValue {
                        MessageViewModel.instance.onTerminatedCall()
                    } else {
                        callVM.onTerminatedCall()
                    }
                case .Ice:
                    if callType == Call.Category.MESSAGE.rawValue {
                        MessageViewModel.instance.addRemoteCandidate(sdp: sdp!)
                    } else {
                        callVM.addRemoteCandidate(sdp: sdp!)
                    }
                case .Message:
                    print("type is Message")
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
        }
    }
    
    func receiveOffer(spaceId: String?, callId: String?, chatId: String?, callType: String, userId: String, sdp: String?, fcmToken: String) {
        if (CallViewModel.instance.space != nil) {
            let category = Call.Category(rawValue: callType) ?? .AUDIO
            SendFCM.sendMessage(payload: SendFCM.getPayload(to: fcmToken, type: .Busy, callType: category))
            SpaceRepository.getSpace(id: spaceId!) { result in
                switch (result) {
                    case .success(let space):
                        print("getSpace success \(space)")
                        CallViewModel.instance.busy()
                    case .failure(let err):
                        print("getSpace failure \(err)")
                }
            }
            let call = Call(spaceId: spaceId!, type: category, direction: .Answer, terminated: true)
            SpaceRepository.addCallList(spaceId: spaceId!, callId: call.id)
            CallRepository.post(call: call) { err in
                if err != nil {
                    print("post call failure \(err!)")
                }
            }
        } else if (callType == Call.Category.MESSAGE.rawValue) {
            MessageViewModel.instance.onIncomingCall(userId: userId, chatId: chatId, message: nil, sdp: sdp, fcmToken: fcmToken)
        } else {
            let callVM = CallViewModel.instance
            CallRepository.getCall(id: callId!) { result in
                switch (result) {
                    case .success(let call):
                        if call.sdp != nil {
                            callVM.onIncomingCall(spaceId: spaceId!, type: callType, counterpartId: userId, fcmToken: fcmToken, remoteSDP: call.sdp!)
                        }
                    case .failure(let err):
                        print("failure \(err)")
                }
            }
        }
    }
    
    func receiveAnswer(callId: String?, callType: String, sdp: String?) {
        if (callType == Call.Category.MESSAGE.rawValue) {
            MessageViewModel.instance.onAnswerCall(sdp: sdp)
        } else {
            let callVM = CallViewModel.instance
            CallRepository.getCall(id: callId!) { result in
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
