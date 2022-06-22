//
//  FlutterMethodCallExtension.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 20.06.2022.
//

import Foundation

extension FlutterMethodCall {
    func argument<T>(_ index: Int) -> T {
        return (arguments as! [Any?])[index] as! T
    }
}
