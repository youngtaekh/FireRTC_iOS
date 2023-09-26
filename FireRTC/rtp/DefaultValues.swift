//
//  DefaultValues.swift
//  FireRTC
//
//  Created by young on 2023/08/10.
//

import Foundation

class DefaultValues {
    static let isAudio: Bool = false
    static let isVideo: Bool = false
    static let isScreen: Bool = false
    static let isDataChannel: Bool = false
    static let enableStat: Bool = false
    static let recordAudio: Bool = false
    
    static let isOrdered = true
    static let isNegotiated = false
    static let maxRetransmitTimeMs: Int32 = -1
    static let maxRetransmitPreference: Int32 = -1
    static let dataId: Int32 = -1
    static let subProtocol = ""
}
