//
//  TransferV3SubstrateResponse.swift
//  
//
//  Created by Julia Samol on 11.01.22.
//

import Foundation

public struct TransferV3SubstrateResponse: BlockchainV3SubstrateResponseProtocol {
    public typealias BlockchainType = Substrate
    
    public let type: String
    public let transactionHash: String?
    public let payload: String?
    
    init(transactionHash: String? = nil, payload: String? = nil) {
        self.type = TransferV3SubstrateResponse.type
        self.transactionHash = transactionHash
        self.payload = payload
    }
    
    // MARK: BeaconMessage Compatibility
    
    public init(from blockchainResponse: Substrate.Response.Blockchain) throws {
       switch blockchainResponse {
        case let .transfer(content):
            self.init(from: content)
        default:
            throw Beacon.Error.unknownBeaconMessage
        }
    }
    
    public init(from transferResponse: TransferSubstrateResponse) {
        switch transferResponse {
        case let .broadcast(content):
            self.init(transactionHash: content.transactionHash)
        case let .broadcastAndReturn(content):
            self.init(transactionHash: content.transactionHash, payload: content.payload)
        case let .return(content):
            self.init(payload: content.payload)
        }
    }
    
    public func toBeaconMessage(
        id: String,
        version: String,
        senderID: String,
        origin: Beacon.Origin,
        completion: @escaping (Result<BeaconMessage<Substrate>, Swift.Error>) -> ()
    ) {
        runCatching(completion: completion) {
            let transferResponse: TransferSubstrateResponse
            if let transactionHash = transactionHash, payload == nil {
                transferResponse = .broadcast(
                    .init(
                        id: id,
                        version: version,
                        requestOrigin: origin,
                        transactionHash: transactionHash
                    )
                )
            } else if let transactionHash = transactionHash, let payload = payload {
                transferResponse = .broadcastAndReturn(
                    .init(
                        id: id,
                        version: version,
                        requestOrigin: origin,
                        transactionHash: transactionHash,
                        payload: payload
                    )
                )
            } else if let payload = payload, transactionHash == nil {
                transferResponse = .return(
                    .init(
                        id: id,
                        version: version,
                        requestOrigin: origin,
                        payload: payload
                    )
                )
            } else {
                throw Error.invalidMessage
            }
            
            let substrateMessage: BeaconMessage<Substrate> =
                .response(
                    .blockchain(
                        .transfer(transferResponse)
                    )
                )

            
            completion(.success(substrateMessage))
        }
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case invalidMessage
    }
}

// MARK: Extension

extension TransferV3SubstrateResponse {
    static let type = "transfer_response"
}
