//
//  YubiKeyConnection.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 18.04.2022.
//
import OSLog
import YubiKit

class YubiKeyConnection: NSObject {
    let logger = Logger()
    var accessoryConnection: YKFAccessoryConnection?
    var nfcConnection: YKFNFCConnection?
    var connectionCallback: ((_ connection: YKFConnectionProtocol?, _ error: Error?) -> Void)?
    static let shared = YubiKeyConnection()
    
    override private init() {
        super.init()
        YubiKitManager.shared.delegate = self
        start()
    }

    func connection(completion: @escaping (_ connection: YKFConnectionProtocol?, _ error: Error?) -> Void) {
        logger.info("Starting connection callback")
        if let connection = accessoryConnection {
            logger.info("Using accessory connection")
            completion(connection, nil)
            logger.info("Accessory connection callback completed")
        } else {
            logger.info("Using NFC connection")
            connectionCallback = completion
            YubiKitManager.shared.startNFCConnection()
        }
    }
    
    func start() {
        logger.info("Starting accessory connection")
        YubiKitManager.shared.startAccessoryConnection()
        Thread.sleep(forTimeInterval: 1.0) // Wait for accessory connection to initialize
    }
    
    func stop() {
        logger.info("Stopping connection")
        if nfcConnection != nil {
            YubiKitManager.shared.stopNFCConnection()
            Thread.sleep(forTimeInterval: 4.0) // Approximate time it takes for the NFC modal to dismiss
        }
    }
}

extension YubiKeyConnection: YKFManagerDelegate {
    func didConnectNFC(_ connection: YKFNFCConnection) {
        logger.info("NFC connected")
        nfcConnection = connection
        if let callback = connectionCallback {
            callback(connection, nil)
            connectionCallback = nil
            logger.info("NFC connection callback completed")
        } else {
            logger.error("No NFC callback!")
        }
    }
    
    func didFailConnectingNFC(_ error: Error) {
        logger.error("Failed to connect to NFC")
        if let callback = connectionCallback {
            callback(nil, error)
        }
    }
    
    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        logger.info("NFC disconnected")
        nfcConnection = nil
    }
    
    func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        logger.info("Accessory connected")
        accessoryConnection = connection
    }
    
    func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        logger.info("Accessory disconnected")
        accessoryConnection = nil
    }
}
