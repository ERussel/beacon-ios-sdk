//
//  MockCoinRegistry.swift
//  BeaconSDKTests
//
//  Created by Julia Samol on 01.12.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation
@testable import BeaconSDK

class MockCoinRegistry: CoinRegistryProtocol {
    func get(_ type: CoinType) -> Coin {
        MockCoin()
    }
}
