//
//  Dictionary+.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 28/11/22.
//

extension Dictionary {
    func toJsonString() -> String? {
        guard
            let jsonData = try? JSONSerialization.data(
                withJSONObject: self, options: []
            )
        else {
            return nil
        }

        return String(data: jsonData, encoding: .utf8)
    }
}
