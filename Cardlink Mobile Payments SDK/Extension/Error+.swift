//
//  Error+.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 3/12/22.
//

extension Error {
    func isNetworkOffline() -> Bool {
        let error = self as NSError
        return error.domain == NSURLErrorDomain && (
            error.code == NSURLErrorNotConnectedToInternet
        )
    }
}
