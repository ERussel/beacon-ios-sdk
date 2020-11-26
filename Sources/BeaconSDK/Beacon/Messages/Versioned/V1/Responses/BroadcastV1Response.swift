//
//  BroadcastV1Response.swift
//  BeaconSDK
//
//  Created by Julia Samol on 13.11.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation

extension Beacon.Message.Versioned.V1 {
    
    struct BroadcastResponse: Codable {
        let type: `Type`
        let version: String
        let id: String
        let beaconID: String
        let transactionHash: String
        
        init(version: String, id: String, beaconID: String, transactionHash: String) {
            type = .broadcastResponse
            self.version = version
            self.id = id
            self.beaconID = beaconID
            self.transactionHash = transactionHash
        }
        
        // MARK: BeaconMessage Compatibility
        
        init(from beaconMessage: Beacon.Response.Broadcast, version: String, senderID: String) {
            self.init(version: version, id: beaconMessage.id, beaconID: senderID, transactionHash: beaconMessage.transactionHash)
        }
        
        func toBeaconMessage(
            with origin: Beacon.Origin,
            using storage: ExtendedStorage,
            completion: @escaping (Result<Beacon.Message, Error>) -> ()
        ) {
            let message = Beacon.Message.response(
                Beacon.Response.broadcast(
                    Beacon.Response.Broadcast(id: id, transactionHash: transactionHash)
                )
            )
            
            completion(.success(message))
        }
        
        // MARK: Codable
        
        enum CodingKeys: String, CodingKey {
            case type
            case version
            case id
            case beaconID = "beaconId"
            case transactionHash
        }
    }
}
