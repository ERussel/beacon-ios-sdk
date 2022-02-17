//
//  TransferSubstrateResponse.swift
//  
//
//  Created by Julia Samol on 11.01.22.
//

import Foundation

public enum TransferSubstrateResponse: BlockchainBeaconResponseProtocol, Equatable {
    case broadcast(_ broadcast: BroadcastTransferSubstrateResponse)
    case broadcastAndReturn(_ broadcastAndReturn: BroadcastAndReturnTransferSubstrateResponse)
    case `return`(_ return: ReturnTransferSubstrateResponse)
    
    // MARK: Attributes
    
    /// The value that identifies the request to which the message is responding.
    public var id: String { common.id }
    
    /// The version of the message.
    public var version: String { common.version }
    
    /// The origination data of the request.
    public var requestOrigin: Beacon.Origin { common.requestOrigin }
    
    private var common: BlockchainBeaconResponseProtocol {
        switch self {
        case let .broadcast(content):
            return content
        case let .broadcastAndReturn(content):
            return content
        case let .`return`(content):
            return content
        }
    }
}
