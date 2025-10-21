//
//  Sequence+.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 11/3/23.
//

extension Sequence where Element: Hashable {
    func toSet() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
