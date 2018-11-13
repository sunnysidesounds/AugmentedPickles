//
//  DLARSessionState.swift
//  ARKitPlanesAndObjects
//
//  Created by Ignacio Nieto Carvajal on 13/11/2017.
//  Copyright © 2017 Digital Leaves. All rights reserved.
//

import Foundation

enum ARSessionState: String, CustomStringConvertible {
    case initialized = "initialized"
    case ready = "ready"
    case temporarilyUnavailable = "temporarily unavailable"
    case failed = "failed"

    var description: String {
        switch self {
        case .initialized:
            return "Look for a plane to place your item"
        case .ready:
            return "Click any plane to place your item!"
        case .temporarilyUnavailable:
            return "Temporarily unavailable. Please wait"
        case .failed:
            return "Please restart App."
        }
    }
}
