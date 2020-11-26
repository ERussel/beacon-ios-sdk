//
//  MatrixClient.swift
//  BeaconSDK
//
//  Created by Julia Samol on 16.11.20.
//  Copyright © 2020 Papers AG. All rights reserved.
//

import Foundation

class Matrix {
    private let store: Store
    private let userService: UserService
    private let eventService: EventService
    private let roomService: RoomService
    
    private let pollQueue: DispatchQueue = DispatchQueue(label: "it.airgap.beacon-sdk.beacon-matrix-poll", target: .global(qos: .default))
    
    init(store: Store, userService: UserService, eventService: EventService, roomService: RoomService) {
        self.store = store
        self.userService = userService
        self.eventService = eventService
        self.roomService = roomService
    }
    
    // MARK: State
    
    func joinedRooms(completion: @escaping (Result<[Room], Swift.Error>) -> ()) {
        store.state { state in
            completion(state.map { $0.rooms.values.filter { $0.status == .joined } })
        }
    }
    
    func invitedRooms(completion: @escaping (Result<[Room], Swift.Error>) -> ()) {
        store.state { state in
            completion(state.map { $0.rooms.values.filter { $0.status == .invited } })
        }
    }
    
    func leftRooms(completion: @escaping (Result<[Room], Swift.Error>) -> ()) {
        store.state { state in
            completion(state.map { $0.rooms.values.filter { $0.status == .left } })
        }
    }
    
    func subscribe(for kind: Matrix.Event.Kind, listener: @escaping (Matrix.Event) -> ()) {
        let listener = Store.EventsListener { events in
            events
                .filter { $0.isOf(kind: kind) }
                .forEach { listener($0) }
        }
        
        store.add(eventsListener: listener)
    }
    
    // MARK: Sync
    
    func start(userID: String, password: String, deviceID: String, completion: @escaping (Result<(), Swift.Error>) -> ()) {
        userService.login(user: userID, password: password, deviceID: deviceID) { [weak self] result in
            guard let response = result.get(ifFailure: completion) else { return }
            
            guard let accessToken = response.accessToken else {
                completion(.failure(Error.login("Login was successful, but accessToken has not been provided.")))
                return
            }
            
            guard let selfStrong = self else {
                completion(.failure(Error.unknown))
                return
            }
            
            selfStrong.store.intent(action: .initialize(userID: userID, deviceID: deviceID, accessToken: accessToken)) { result in
                guard result.isSuccess(otherwise: completion) else { return }
                selfStrong.poll(completion: completion)
            }
        }
    }
    
    func sync(completion: @escaping (Result<Sync, Swift.Error>) -> ()) {
        store.state { [weak self] in
            guard let state = $0.get(ifFailure: completion) else { return }
            guard let accessToken = state.accessToken else {
                completion(.failure(Error.requiresAuthorization("sync")))
                return
            }
            
            self?.eventService.sync(withToken: accessToken, since: state.syncToken, timeout: state.pollingTimeout) { result in
                completion(result.map { Sync(from: $0) })
            }
        }
    }
    
    private func poll(completion: @escaping (Result<(), Swift.Error>) -> ()) {
        poll { [weak self] (result, callbackReturn) in
            guard let selfStrong = self else {
                completion(.failure(Error.unknown))
                return
            }
            
            switch result {
            case let .success(response):
                selfStrong.store.state {
                    if let state = $0.get(ifFailure: completion), !state.isPolling {
                        completion(.success(()))
                    }
                
                    selfStrong.store.intent(
                        action: .onSyncSuccess(
                            syncToken: response.nextBatch,
                            pollingTimeout: 3000,
                            rooms: response.rooms,
                            events: response.events
                        )
                    ) { _ in callbackReturn() }
                }
            case let .failure(error):
                selfStrong.store.state {
                    if let state = $0.get(ifFailure: completion), !state.isPolling {
                        completion(.failure(error))
                    }
                    
                    selfStrong.store.intent(action: .onSyncFailure) { _ in callbackReturn() }
                }
            }
        }
    }
    
    private func poll(
        every interval: DispatchTimeInterval = .milliseconds(0),
        onResult callback: @escaping (Result<Sync, Swift.Error>, @escaping () -> ()) -> ()
    ) {
        pollQueue.async {
            self.sync { result in
                callback(result) { [weak self] in
                    switch result {
                    case .success(_):
                        self?.schedule(after: interval) {
                            self?.poll(every: interval, onResult: callback)
                        }
                    case .failure(_):
                        self?.store.state { [weak self] in
                            guard let state = try? $0.get() else { return }
                            if state.pollingRetries < Beacon.Configuration.matrixMaxSyncRetries {
                                self?.schedule(after: interval) {
                                    self?.poll(every: interval, onResult: callback)
                                }
                            } /* else: max retries exceeded */
                        }
                    }
                }
            }
        }
    }
    
    private func schedule(after delay: DispatchTimeInterval, action: @escaping () -> ()) {
        pollQueue.asyncAfter(deadline: .now() + delay, execute: action)
    }
    
    // MARK: Room Management
    
    func createTrustedPrivateRoom(members: [String], completion: @escaping (Result<Room?, Swift.Error>) -> ()) {
        store.state { [weak self] in
            guard let state = $0.get(ifFailure: completion) else { return }
            guard let accessToken = state.accessToken else {
                completion(.failure(Error.requiresAuthorization("createTrustedPrivateRoom")))
                return
            }
            
            guard let selfStrong = self else {
                completion(.failure(Error.unknown))
                return
            }
            
            let roomRequest = RoomService.CreateRequest(invite: members, preset: .trustedPrivateChat, isDirect: true)
            selfStrong.roomService.createRoom(withToken: accessToken, configuredWith: roomRequest) { result in
                completion(result.map { $0.roomID.map { Matrix.Room.init(status: .unknown, id: $0) } })
            }
        }
    }
    
    // MARK: Event Management
    
    func send(textMessage message: String, to room: Matrix.Room, completion: @escaping (Result<(), Swift.Error>) -> ()) {
        store.state { [weak self] in
            guard let state = $0.get(ifFailure: completion) else { return }
            guard let accessToken = state.accessToken else {
                completion(.failure(Error.requiresAuthorization("send")))
                return
            }
            
            guard let selfStrong = self else {
                completion(.failure(Error.unknown))
                return
            }
            
            selfStrong.createTxnID { result in
                guard let txnID = result.get(ifFailure: completion) else { return }
                selfStrong.eventService.send(withToken: accessToken, textMessage: message, to: room.id, txnID: txnID) { result in
                    completion(result.map { _ in () })
                }
            }
        }
    }
    
    private func createTxnID(completion: @escaping (Result<String, Swift.Error>) -> ()) {
        store.state { [weak self] in
            guard let state = $0.get(ifFailure: completion) else { return }
            let timestamp = Date().currentTimeMillis
            let counter = state.transactionCounter
            
            guard let selfStrong = self else {
                completion(.failure(Error.unknown))
                return
            }
            
            selfStrong.store.intent(action: .onTxnIDCreated) { result in
                completion(result.map { "m\(timestamp).\(counter)" })
            }
        }
    }
    
    // MARK: Types
    
    enum Error: Swift.Error {
        case login(String? = nil)
        case requiresAuthorization(String)
        case relevantRoomNotFound
        case unknown
    }
}
