//
//  Formatters.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 2/12/22.
//

class Formatters {
    private static let currencyFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "EUR"
        nf.generatesDecimalNumbers = true
        nf.alwaysShowsDecimalSeparator = true
        return nf
    } ()
    
    static func formatAmount(_ amount: UInt) -> String {
        return currencyFormatter.string(from: NSDecimalNumber(value: amount).dividing(by: 100)) ?? ""
    }
}
