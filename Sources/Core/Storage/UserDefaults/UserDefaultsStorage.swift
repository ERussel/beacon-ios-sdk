//
//  UserDefaultsStorage.swift
//
//
//  Created by Julia Samol on 10.11.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation

public struct UserDefaultsStorage: Storage {
    
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: Peers
    
    public func getPeers(completion: @escaping (Result<[Beacon.Peer], Error>) -> ()) {
        completeCatching(completion: completion) {
            try userDefaults.get([Beacon.Peer].self, forKey: .peers) ?? []
        }
    }
    
    public func set(_ peers: [Beacon.Peer], completion: @escaping (Result<(), Error>) -> ()) {
        completeCatching(completion: completion) {
            if peers.isEmpty {
                userDefaults.removeObject(forKey: .peers)
            } else {
                try userDefaults.set(peers, forKey: .peers)
            }
        }
    }
    
    // MARK: AppMetadata
    
    public func getAppMetadata<T: AppMetadataProtocol>(completion: @escaping (Result<[T], Error>) -> ()) {
        completeCatching(completion: completion) {
            try userDefaults.get([T].self, forKey: .appMetadata) ?? []
        }
    }
    
    public func set<T: AppMetadataProtocol>(_ appMetadata: [T], completion: @escaping (Result<(), Error>) -> ()) {
        completeCatching(completion: completion) {
            if appMetadata.isEmpty {
                userDefaults.removeObject(forKey: .appMetadata)
            } else {
                try userDefaults.set(appMetadata, forKey: .appMetadata)
            }
        }
    }
    
    // MARK: Permissions
    
    public func getPermissions<T: PermissionProtocol>(completion: @escaping (Result<[T], Error>) -> ()) {
        completeCatching(completion: completion) {
            try userDefaults.get([T].self, forKey: .permissions) ?? []
        }
    }
    
    public func set<T: PermissionProtocol>(_ permissions: [T], completion: @escaping (Result<(), Error>) -> ()) {
        completeCatching(completion: completion) {
            if permissions.isEmpty {
                userDefaults.removeObject(forKey: .permissions)
            } else {
                try userDefaults.set(permissions, forKey: .permissions)
            }
        }
    }
    
    public func getLegacyPermissions<T: LegacyPermissionProtocol>(completion: @escaping (Result<[T], Error>) -> ()) {
        completeCatching(completion: completion) {
            try userDefaults.get([T].self, forKey: .permissions, version: T.fromVersion) ?? []
        }
    }
    
    public func setLegacy<T: LegacyPermissionProtocol>(_ permissions: [T], completion: @escaping (Result<(), Error>) -> ()) {
        completeCatching(completion: completion) {
            if permissions.isEmpty {
                userDefaults.removeObject(forKey: .permissions, version: T.fromVersion)
            } else {
                try userDefaults.set(permissions, forKey: .permissions, version: T.fromVersion)
            }
        }
    }
    
    // MARK: SDK
    
    public func getSDKVersion(completion: @escaping (Result<String?, Error>) -> ()) {
        let version = userDefaults.string(forKey: .sdkVersion)
        completion(.success(version))
    }
    
    public func setSDKVersion(_ version: String, completion: @escaping (Result<(), Error>) -> ()) {
        userDefaults.set(version, forKey: .sdkVersion)
        completion(.success(()))
    }
    
    public func getMigrations(completion: @escaping (Result<Set<String>, Error>) -> ()) {
        completeCatching(completion: completion) {
            try userDefaults.get(Set<String>.self, forKey: .migrations) ?? []
        }
    }
    
    public func setMigrations(_ migrations: Set<String>, completion: @escaping (Result<(), Error>) -> ()) {
        completeCatching(completion: completion) {
            if migrations.isEmpty {
                userDefaults.removeObject(forKey: .migrations)
            } else {
                try userDefaults.set(migrations, forKey: .migrations)
            }
        }
    }
    
    // MARK: Types
    
    enum Key: String {
        case peers
        case appMetadata
        case permissions
        case matrixRelayServer
        case matrixChannels
        case matrixSyncToken
        case matrixRooms
        case sdkVersion
        case migrations
    }
}

// MARK: Extensions

private extension UserDefaults {
    func set(_ value: String, forKey key: UserDefaultsStorage.Key) {
        set(value, forKey: key.rawValue)
    }
    
    func set<T: Codable>(_ value: T, forKey key: UserDefaultsStorage.Key, version: String? = nil) throws {
        let propertyListEncoder = PropertyListEncoder()
        set(try propertyListEncoder.encode(value), forKey: self.key(from: key, andVersion: version))
    }
    
    func string(forKey key: UserDefaultsStorage.Key) -> String? {
        string(forKey: key.rawValue)
    }
    
    func get<T: Codable>(_ type: T.Type, forKey key: UserDefaultsStorage.Key, version: String? = nil) throws -> T? {
        let propertyListDecoder = PropertyListDecoder()
        if let data = data(forKey: self.key(from: key, andVersion: version)) {
            return try propertyListDecoder.decode(type, from: data)
        } else {
            return nil
        }
    }
    
    func removeObject(forKey key: UserDefaultsStorage.Key, version: String? = nil) {
        removeObject(forKey: self.key(from: key, andVersion: version))
    }
    
    private func key(from key: UserDefaultsStorage.Key, andVersion version: String?) -> String {
        if let version = version {
            return "\(key.rawValue)_\(version)"
        } else {
            return key.rawValue
        }
    }
}
