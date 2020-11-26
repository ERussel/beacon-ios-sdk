//
//  Response.swift
//  BeaconSDK
//
//  Created by Julia Samol on 13.11.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation

extension Beacon {
    
    public enum Response {
        case permission(Permission)
        case operation(Operation)
        case signPayload(SignPayload)
        case broadcast(Broadcast)
        case error(Error)
    }
}
