//
//  RTPListener.swift
//  FireRTC
//
//  Created by young on 2023/08/18.
//

import Foundation

protocol RTPListener {
    func onDescriptionSuccess(type: Int, sdp: String)
    func onIceCandidate(candidate: String)
    func onPCConnected()
    func onPCDisconnected()
    func onPCFailed()
    func onPCClosed()
//    func onPCStatsReady(reports: Array<StatsReport?>?)
    func onPCError(description: String?)
    func onMessage(message: String)
}
