//
//  YubiKeyConnection.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 18.04.2022.
//
import YubiKit
import OSLog

class YubiKeyConnection: NSObject {
    
    var accessoryConnection: YKFAccessoryConnection?
    var nfcConnection: YKFNFCConnection?
    var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?
    let logger = Logger()
    
    override init() {
        super.init()
        YubiKitManager.shared.delegate = self
        YubiKitManager.shared.startAccessoryConnection()
    }
    
    func connection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        logger.info("Starting connection callback")
        if let connection = accessoryConnection {
            logger.info("Using accessory connection")
            completion(connection)
            logger.info("Accessory connection callback completed")
        } else {
            logger.info("Using NFC connection")
            connectionCallback = completion
            YubiKitManager.shared.startNFCConnection()
        }
    }
}

extension YubiKeyConnection: YKFManagerDelegate {
    func didConnectNFC(_ connection: YKFNFCConnection) {
       logger.info("NFC connected")
       nfcConnection = connection
        if let callback = connectionCallback {
            defer {
                self.logger.info("Closing NFC connection")
                connection.stop()
            }
            callback(connection)
            logger.info("NFC connection callback completed")
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
