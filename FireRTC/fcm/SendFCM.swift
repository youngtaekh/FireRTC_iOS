//
//  SendFCM.swift
//  FireRTC
//
//  Created by young on 2023/08/17.
//

import Foundation
import Alamofire

class SendFCM {
    static func test() {
        AF.request("http://www.statiz.co.kr/schedule.php?opt=8&sy=2023").responseString() { response in
//            print(response)
            switch response.result {
                case .success:
                    try! print(response.result.get())
//                    if let data = try! response.result.get() as? [String: Any] {
//                        print(data)
//                    }
                case .failure(let error):
                    print("Error: \(error)")
                    return
            }
        }
    }
    
    static func sendMessage(payload: Payload) {
        let headers: HTTPHeaders = [HTTPHeader(name: "Authorization", value: "key=AAAAxajhs4s:APA91bFbKcfhRGmIK_pn5HAQZgWoCpbF_qxaRNe2hG_QZLOBuwNfF3b2AGKpA8LcGd5QVAmIDazBnJBwC26rinf4G6kkPG1yyy63hdAqQx-q68axHZ9Hz-XgzziTPiI0fm1cfDXSNOIR"), HTTPHeader(name: "Content-Type", value: "application/json")]
        AF.request(
            "https://fcm.googleapis.com/fcm/send",
            method: .post,
            parameters: payload,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).responseString() { response in
            switch response.result {
                case .success:
                    print("SendFCM Success \(payload.data.callType) \(payload.data.type)")
                case .failure(let error):
                    print("SendFCM Error \(payload.data.callType) \(payload.data.type): \(error)")
                    return
            }
        }
    }
    
    static func getPayload(
        to: String,
        type: FCMType,
        callType: Call.Category,
        spaceId: String? = nil,
        callId: String? = nil,
        chatId: String? = nil,
        messageId: String? = nil,
        targetOS: String? = nil,
        sdp: String? = nil,
        message: String? = nil
    ) -> Payload {
        let notification = Notification(title: SharedPreference.instance.getName(), body: "\(callType) \(type)")
        let data = Data(
            content_available: true,
            userId: SharedPreference.instance.getID(),
            name: SharedPreference.instance.getName(),
            type: type.rawValue,
            callType: callType.rawValue,
            fcmToken: SharedPreference.instance.getFcmToken(),
            callId: callId,
            spaceId: spaceId,
            chatId: chatId,
            messageId: messageId,
            targetOS: "iOS",
            sdp: sdp,
            message: message
        )
        if targetOS == nil || targetOS!.lowercased() == "ios" {
            let payload = Payload(to: to, data: data, notification: notification)
            return payload
        } else {
            let payload = Payload(to: to, data: data, notification: nil)
            return payload
        }
    }
    
    struct Data: Codable {
        let content_available: Bool
        let userId: String
        let name: String
        let type: String
        let callType: String
        let fcmToken: String
        let callId: String?
        let spaceId: String?
        let chatId: String?
        let messageId: String?
        let targetOS: String?
        let sdp: String?
        let message: String?
    }
    
    struct Notification: Codable {
        let title: String
        let body: String
    }
    
    struct Payload: Codable {
        let to: String
        let data: Data
        let notification: Notification?
    }
    
    enum FCMType: String {
        case Offer = "Offer"
        case Answer = "Answer"
        case Cancel = "Cancel"
        case Decline = "Decline"
        case Bye = "Bye"
        case Busy = "Busy"
        case New = "New"
        case Leave = "Leave"
        case Sdp = "Sdp"
        case Ice = "Ice"
        case Message = "Message"
        case Else = "Else"
    }
}
