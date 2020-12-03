//
//  MockAccountUtils.swift
//  BeaconSDKTests
//
//  Created by Julia Samol on 01.12.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation
@testable import BeaconSDK

class MockAccountUtils: AccountUtilsProtocol {
    func getAccountIdentifier(forAddress address: String, on network: Beacon.Network) throws -> String {
        address
    }
}
