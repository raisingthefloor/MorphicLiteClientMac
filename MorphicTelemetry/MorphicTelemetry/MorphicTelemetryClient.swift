// Copyright 2021 Raising the Floor - International
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/raisingthefloor/morphic-macos/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Foundation
import MQTTNIO
import NIO

public struct MorphicTelemetryClient {

    private var mqttClient: MQTTClient
    private var mqttClientConfig: TelemetryClientConfig

    private let clientId: String
    private let softwareVersion: String

    private enum SessionState
    {
        case stopped
        case starting
        case started
        case stopping
    }
    private var sessionState: SessionState = .stopped
    private var isConnected = false
    private var isPermanentlyClosed = false

    public var siteId: String? = nil

    public class TelemetryClientConfig
    {
        public var clientId: String
        public var username: String
        public var password: String
        
        public init(clientId: String, username: String, password: String) {
            self.clientId = clientId
            self.username = username
            self.password = password
        }
    }
    //
    public class TcpTelemetryClientConfig: TelemetryClientConfig
    {
        public var hostname: String // = "localhost"
        public var port: UInt16? // = nil
        public var useTls: Bool // = false
        
        public init(clientId: String, username: String, password: String, hostname: String, port: UInt16?, useTls: Bool) {
            self.hostname = hostname
            self.port = port
            self.useTls = useTls
            
            super.init(clientId: clientId, username: username, password: password)
        }
    }
    //
    public class WebsocketTelemetryClientConfig: TelemetryClientConfig
    {
        public var hostname: String // = "localhost"
        public var port: UInt16? // = nil
        public var path: String? // = nil
        public var useTls: Bool // = false
        
        public init(clientId: String, username: String, password: String, hostname: String, port: UInt16?, path: String?, useTls: Bool) {
            self.hostname = hostname
            self.port = port
            self.path = path
            self.useTls = useTls
            
            super.init(clientId: clientId, username: username, password: password)
        }
    }

    public init(config: TelemetryClientConfig, softwareVersion: String) {
        self.mqttClientConfig = config
        self.softwareVersion = softwareVersion
        
        // initialize and capture our MQTT client and its configuration options

        var hostname: String
        var mqttPort: Int
        var mqttClientConfiguration: MQTTClient.Configuration

        // configure a keepAliveInterval of 45 seconds (since the default for this library is 90 seconds...and RabbitMQ times out after 60 seconds)
        let keepAliveInterval = TimeAmount.seconds(45)
        
        if let config = self.mqttClientConfig as? TcpTelemetryClientConfig {
            hostname = config.hostname
            
            if config.useTls == false {
                mqttPort = Int(config.port ?? 1883)
                mqttClientConfiguration = .init(keepAliveInterval: keepAliveInterval, userName: config.username, password: config.password)
            } else {
                mqttPort = Int(config.port ?? 8883)
                mqttClientConfiguration = .init(keepAliveInterval: keepAliveInterval, userName: config.username, password: config.password, useSSL: true)
            }
        } else if let config = self.mqttClientConfig as? WebsocketTelemetryClientConfig {
            hostname = config.hostname

            var webSocketURLPath: String

            if config.useTls == false {
                mqttPort = Int(config.port ?? 80)
                webSocketURLPath = "http://"
            } else {
                mqttPort = Int(config.port ?? 443)
                webSocketURLPath = "https://"
            }
                        
            webSocketURLPath += config.hostname
            webSocketURLPath += ":" + String(mqttPort)
            if var pathComponent = config.path {
                // sanity check: make sure the path component starts with "/" or "#"
                if let firstLetterOfPathComponent = pathComponent.first {
                    if firstLetterOfPathComponent != "/" && firstLetterOfPathComponent != "#" {
                        pathComponent = "/" + pathComponent
                    }
                }
                
                webSocketURLPath += pathComponent
            }
            
            mqttClientConfiguration = .init(keepAliveInterval: keepAliveInterval, userName: config.username, password: config.password, useSSL: config.useTls, useWebSockets: true, webSocketURLPath: webSocketURLPath)
        } else {
            fatalError("unknown config type")
        }
        
        let mqttClient = MQTTClient(
            host: hostname,
            port: mqttPort,
            identifier: self.mqttClientConfig.clientId,
            // TODO: should I use .createNew or shared() ???
            eventLoopGroupProvider: .createNew,
            configuration: mqttClientConfiguration
        )
        self.mqttClient = mqttClient
        
        // set up disconnect handler (to handle automatic reconnection)
        mqttClient.addCloseListener(named: "closed") { result in
            MorphicTelemetryClient.mqttClientDisconnected(mqttClient: mqttClient)
        }
        
        self.clientId = self.mqttClientConfig.clientId
    }
    
    public mutating func startSession() {
        switch self.sessionState {
        case .started,
             .starting:
            // if our session is already started (or is starting), just return
            return
        case .stopping:
            // if our session is stopping, wait until the session is stopped
            while self.sessionState == .stopping
            {
                if (self.isPermanentlyClosed == true)
                {
                    return
                }
                // TODO: we should consider waiting _asynchronously_ since this could block an important thread otherwise
                Thread.sleep(forTimeInterval: TimeInterval(0.1))
            }
            // re-call this function with the updated state
            // NOTE: alternatively we could put this sessionstate check in a loop (refactored out into another function); that would avoid potential but extremely unlikely deep recursion
            self.startSession()
            return
        case .stopped:
            // if our session is stopped, continue; this is the appropriate state to call this function
            break
        }

        if (self.isPermanentlyClosed == true) {
            fatalError("Cannot re-start a session after the object has been disposed");
        }
        
        self.sessionState = .starting
        
        // connect to the telemetry server in the background
        let mqttClient = self.mqttClient
        let _ = mqttClient.connect(cleanSession: true, will: nil).always({ result in
            switch result {
            case .success(_):
                // connected
                MorphicTelemetryClient.mqttClientConnected(mqttClient: mqttClient)
                // TODO: we might want to consider letting our caller know that we are connected
            case .failure:
                // could not connect; call our disconnected callback to try again (after a waiting period)
                MorphicTelemetryClient.mqttClientDisconnected(mqttClient: mqttClient)
                // TODO: we might want to consider letting our caller know that we are in a "connecting" or "failure" state
            }
        })

        self.sessionState = .started
    }

    public mutating func endSession() {
        let mqttClient = self.mqttClient

        // attempt to shut down the mqttClient gracefully
        _ = try? mqttClient.syncShutdownGracefully()

        // mark our object as permanently closed
        self.isPermanentlyClosed = true
        
        // TODO: manually set "isConnected" to false just in case our handler didn't get called in the event of failure...and to prevent any timing issues in regards to "messagesToSendEvent.Set()" getting called before the event handler
        self.isConnected = false
        
        mqttClient.removeCloseListener(named: "disconnected")
        
        _ = mqttClient.disconnect()
    }
    
    private static func mqttClientConnected(mqttClient: MQTTClient) {
    }

    // NOTE: this callback handles both disconnections (post-successful-connection) and connection attempt failures
    private static func mqttClientDisconnected(mqttClient: MQTTClient) {
    }
    
    private struct MqttEventMessage: Codable
    {
        var id: UUID
        var recordType: String
        var recordVersion: Int
        var sentAt: Date
        var siteId: String?
        var deviceId: String
        var softwareVersion: String
        var osName: String
        var osVersion: String
        var eventName: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case recordType = "record_type"
            case recordVersion = "record_version"
            case sentAt = "sent_at"
            case siteId = "site_id"
            case deviceId = "device_id"
            case softwareVersion = "software_version"
            case osName = "os_name"
            case osVersion = "os_version"
            case eventName = "event_name"
        }
    }

    public func enqueueActionMessage(eventName: String) {
        // NOTE: we capture the timestamp up front just to alleviate any potential for the timestamp to be captured late
        let capturedAtTimestamp = Date()

        let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionAsString = String(operatingSystemVersion.majorVersion) + "." + String(operatingSystemVersion.minorVersion) + "." + String(operatingSystemVersion.patchVersion)
        
        let actionMessage = MqttEventMessage(
            id: UUID(),
            recordType: "event",
            recordVersion: 1,
            sentAt: capturedAtTimestamp,
            siteId: self.siteId,
            deviceId: self.clientId,
            softwareVersion: self.softwareVersion,
            osName: "macOS",
            osVersion: osVersionAsString,
            eventName: eventName)

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        let jsonAsData = try! jsonEncoder.encode(actionMessage)
        let jsonAsString = String(data: jsonAsData, encoding: .utf8)!
        let payload = ByteBufferAllocator().buffer(string: jsonAsString)
        
        // NOTE: we're firing off this message asynchronously; ideally if this were in a queue we would be doing a ".wait()" and watching for errors...and handling each one synchronously!
        _ = self.mqttClient.publish(
            to: "telemetry",
            payload: payload,
            qos: .atLeastOnce
        )
    }

}
