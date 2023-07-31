//
//  SharedPreference.swift
//  FireRTC
//
//  Created by young on 2023/07/18.
//

import Foundation

class SharedPreference: NSObject {
    private let TAG = "SharedPreference"
    
    private let SIGN = "sign"
    private let TAB_INDEX = "tabIndex"
    
    static let instance = SharedPreference()
    var preference: UserDefaults
    
    private override init() {
        self.preference = UserDefaults.standard
    }
    
    func setSign(value: Bool) { putBool(key: SIGN, value: value) }
    func isSign() -> Bool { return getBool(key: SIGN) }
    
    func setTabIndex(value: Int) { putInt(key: TAB_INDEX, value: value) }
    func getTabIndex() -> Int { return getInt(key: TAB_INDEX) }
    
    func setID(id: String) { putString(key: ID, value: id) }
    func getID() -> String { return getString(key: ID) }
    func setName(name: String) { putString(key: NAME, value: name) }
    func getName() -> String { return getString(key: NAME) }
    func setFcmToken(token: String) { putString(key: FCM_TOKEN, value: token) }
    func getFcmToken() -> String { getString(key: FCM_TOKEN)}
    
    private func putString(key: String, value: String) {
        preference.set(value, forKey: key)
        preference.synchronize()
    }
    
    private func getString(key: String) -> String {
        let value = preference.string(forKey: key)
        if (value == nil) {
            return ""
        }
        return value!
    }
    
    private func putInt(key: String, value: Int) {
        preference.set(value, forKey: key)
        preference.synchronize()
    }
    
    private func getInt(key: String) -> Int {
        let value = preference.integer(forKey: key)
        return value
    }
    
    private func putBool(key: String, value: Bool) {
        preference.set(value, forKey: key)
        preference.synchronize()
    }
    
    private func getBool(key: String) -> Bool {
        return preference.bool(forKey: key)
    }
}
