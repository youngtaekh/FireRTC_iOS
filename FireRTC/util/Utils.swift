//
//  Utils.swift
//  FireRTC
//
//  Created by young on 2023/08/11.
//

import Foundation
import WebRTC

class Utils {
    private static let TAG = "Utils"
    
    static func dictionaryWithJSONString(jsonString: String) -> [String: Any]? {
        if let data = jsonString.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print("\(Utils.TAG) \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    static func dictionaryWithJSONData(jsonData: Data?) -> [String: Any]? {
        if let data = jsonData {
            do {
                return try JSONSerialization.jsonObject(with: data) as? [String: Any]
            } catch {
                print("\(Utils.TAG) \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    static func serversFromDictionary(dict: [String: Any]?) -> [RTCIceServer] {
        var servers = [RTCIceServer]()
        if let dictionary = dict {
            let name = dictionary["username"] as? String
            let password = dictionary["password"] as? String
            let uris = dictionary["uris"] as! [String]
            
            for uri in uris {
                servers.append(RTCIceServer.init(urlStrings: [uri], username: name, credential: password))
            }
        }
        return servers
    }
}
