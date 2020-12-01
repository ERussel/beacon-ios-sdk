//
//  SignPayloadV2Response.swift
//  BeaconSDK
//
//  Created by Julia Samol on 13.11.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation

extension Beacon.Message.Versioned.V2 {
    
    struct SignPayloadResponse: V2MessageProtocol, Codable {
        let type: `Type`
        let version: String
        let id: String
        let senderID: String
        let signature: String
        
        init(version: String, id: String, senderID: String, signature: String) {
            type = .signPayloadResponse
            self.version = version
            self.id = id
            self.senderID = senderID
            self.signature = signature
        }
        
        // MARK: BeaconMessage Compatibility
        
        init(from beaconMessage: Beacon.Response.SignPayload, version: String, senderID: String) {
            self.init(version: version, id: beaconMessage.id, senderID: senderID, signature: beaconMessage.signature)
        }
        
        func comesFrom(_ appMetadata: Beacon.AppMetadata) -> Bool {
            appMetadata.senderID == senderID
        }
        
        func toBeaconMessage(
            with origin: Beacon.Origin,
            using storage: StorageManager,
            completion: @escaping (Result<Beacon.Message, Error>) -> ()
        ) {
            let message = Beacon.Message.response(
                Beacon.Response.signPayload(
                    Beacon.Response.SignPayload(id: id, signature: signature)
                )
            )
            
            completion(.success(message))
        }
        
        // MARK: Codable
        
        enum CodingKeys: String, CodingKey {
            case type
            case version
            case id
            case senderID = "senderId"
            case signature
        }
    }
}
