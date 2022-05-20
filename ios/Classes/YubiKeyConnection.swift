//
//  YubiKeyConnection.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 18.04.2022.
//
import YubiKit
import OSLog

class YubiKeyConnection: NSObject, FlutterStreamHandler {
    
    var accessoryConnection: YKFAccessoryConnection?
    var nfcConnection: YKFNFCConnection?
    var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?
    let logger = Logger()
    var eventSink: FlutterEventSink?
    
    override init() {
        super.init()
        YubiKitManager.shared.delegate = self
        start()
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
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        if(accessoryConnection != nil || nfcConnection != nil) {
            events("deviceConnected")
        } else {
            events("deviceDisconnected")
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

extension YubiKeyConnection: YKFManagerDelegate {
    func didConnectNFC(_ connection: YKFNFCConnection) {
        logger.info("NFC connected")
        nfcConnection = connection
        if let eventSink = eventSink {
            eventSink("deviceConnected")
        }
        if let callback = connectionCallback {
            callback(connection)
            logger.info("NFC connection callback completed")
        }
    }
    
    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        logger.info("NFC disconnected")
        nfcConnection = nil
        if let eventSink = eventSink {
            eventSink("deviceDisconnected")
        }
    }
    
    func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        logger.info("Accessory connected")
        accessoryConnection = connection
        if let eventSink = eventSink {
            eventSink("deviceConnected")
        }
    }
    
    func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        logger.info("Accessory disconnected")
        accessoryConnection = nil
        if let eventSink = eventSink {
            eventSink("deviceDisconnected")
        }
    }
}
