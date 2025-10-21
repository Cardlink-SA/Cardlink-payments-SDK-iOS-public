//
//  LibraryModule.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 27/11/22.
//

class LibraryModule {
    let log: Log = SimpleLog()
    let network: Network
    
    init(sdk: CardlinkSDK) {
        network = AlamoFireNetwork(baseURL: sdk.serverURL)
    }
}
