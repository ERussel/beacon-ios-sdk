//
//  P2PIdentifier.swift
//  
//
//  Created by Julia Samol on 31.08.21.
//

import Foundation

extension Transport.P2P {
    
    struct Identifier {
        private static let prefix: Character = "@"
        private static let separator: Character = ":"
        
        let publicKeyHash: HexString
        let relayServer: String
        
        init(publicKeyHash: HexString, relayServer: String) {
            self.publicKeyHash = publicKeyHash
            self.relayServer = relayServer
        }
        
        init(publicKeyHash: [UInt8], relayServer: String) {
            self.init(publicKeyHash: HexString(from: publicKeyHash), relayServer: relayServer)
        }
        
        init(fromValue value: String) throws {
            guard Identifier.isValid(value) else {
                throw Error.invalidValue
            }
            
            let parts = value
                .split(separator: Identifier.separator, maxSplits: 1, omittingEmptySubsequences: false)
                .map { String($0) }
            
            guard parts.count == 2 else {
                throw Error.invalidValue
            }
            
            guard let publicKeyHash = try? HexString(from: parts[0].removing(prefix: Identifier.prefix)) else {
                throw Error.invalidValue
            }
            
            let relayServer = parts[1]
            
            self.init(publicKeyHash: publicKeyHash, relayServer: relayServer)
        }
        
        static func isValid(_ value: String) -> Bool {
            value.range(of: "^\(prefix)(.+)\(separator)(.+)$", options: .regularExpression) != nil
        }
        
        func asString() -> String {
            "\(Identifier.prefix)\(publicKeyHash.asString())\(Identifier.separator)\(relayServer)"
        }
        
        // MARK: Types
        
        enum Error: Swift.Error {
            case invalidValue
        }
    }
}
