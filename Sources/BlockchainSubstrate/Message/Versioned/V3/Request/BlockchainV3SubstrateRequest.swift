//
//  BlockchainV3SubstrateRequest.swift
//  
//
//  Created by Julia Samol on 11.01.22.
//

import Foundation
import BeaconCore

public enum BlockchainV3SubstrateRequest: BlockchainV3SubstrateRequestProtocol {
    case transfer(TransferV3SubstrateRequest)
    case sign(SignV3SubstrateRequest)
    
    // MARK: BeaconMessage Compatibility
    
    public init(from blockchainRequest: Substrate.Request.Blockchain) throws {
        switch blockchainRequest {
        case let .transfer(content):
            self = .transfer(TransferV3SubstrateRequest(from: content))
        case let .sign(content):
            self = .sign(SignV3SubstrateRequest(from: content))
        }
    }
    
    public func toBeaconMessage(
        id: String,
        version: String,
        senderID: String,
        origin: Beacon.Origin,
        accountID: String,
        completion: @escaping (Result<BeaconMessage<Substrate>, Error>) -> ()
    ) {
        switch self {
        case let .transfer(content):
            content.toBeaconMessage(
                id: id,
                version: version,
                senderID: senderID,
                origin: origin,
                accountID: accountID,
                completion: completion
            )
        case let .sign(content):
            content.toBeaconMessage(
                id: id,
                version: version,
                senderID: senderID,
                origin: origin,
                accountID: accountID,
                completion: completion
            )
        }
    }
    
    // MARK: Attributes
    
    public var type: String {
        switch self {
        case let .transfer(content):
            return content.type
        case let .sign(content):
            return content.type
        }
    }
    public var scope: Substrate.Permission.Scope {
        switch self {
        case let .transfer(content):
            return content.scope
        case let .sign(content):
            return content.scope
        }
    }
    
    // MARK: Codable
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case TransferV3SubstrateRequest.type:
            self = .transfer(try TransferV3SubstrateRequest(from: decoder))
        case SignV3SubstrateRequest.type:
            self = .sign(try SignV3SubstrateRequest(from: decoder))
        default:
            throw Beacon.Error.unknownMessageType(type, version: "3")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .transfer(content):
            try content.encode(to: encoder)
        case let .sign(content):
            try content.encode(to: encoder)
        }
    }
    
    // MARK: Types
    
    enum CodingKeys: String, CodingKey {
        case type
    }
}

// MARK: Protocol

public protocol BlockchainV3SubstrateRequestProtocol: BlockchainV3BeaconRequestContentDataProtocol {
    var type: String { get }
    var scope: Substrate.Permission.Scope { get }
}
