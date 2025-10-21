//
//  SimpleLog.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 27/11/22.
//

class SimpleLog: Log {
    func i(_ message: String) {
        print(message)
    }
    
    func e(_ message: String) {
        print("ERROR: \(message)")
    }
}

private extension SimpleLog {
    func print(_ message: String) {
#if DEBUG
        Swift.print(message)
#endif
    }
}
