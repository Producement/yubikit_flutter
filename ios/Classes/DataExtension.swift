//
//  DataExtension.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 20.06.2022.
//

import Foundation

extension Data {
    var hexDescription: String {
        return reduce("") { $0 + String(format: "%02x", $1) }
    }
    
    var bytes: [UInt8] {
        var byteArray = [UInt8](repeating: 0, count: count)
        copyBytes(to: &byteArray, count: count)
        return byteArray
    }
}
