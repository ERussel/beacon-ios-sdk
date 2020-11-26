//
//  RoomState.swift
//  BeaconSDK
//
//  Created by Julia Samol on 18.11.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation

extension Matrix.EventService.SyncResponse {
    
    struct RoomState: Codable {
        let events: [Matrix.EventService.StateEvent]?
    }
}
