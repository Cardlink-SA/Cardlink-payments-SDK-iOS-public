//
//  Installments.swift
//  Cardlink Mobile Payments SDK
//
//  Created by GeorgeSyk on 26/2/25.
//

final class Installments {
    
    
    private struct InstallmentsRange {
        let lowBoundAmount: Int
        let upperBoundAmount: Int
        let installments: Int
    }
    
    // [ (50, 3), (150, 2) , (500, 6)]
    // 0..49.99 -> installments 0
    // 50..149.99 -> installments 3
    // 150..499.99 -> instalmments 2
    // 500.. -> installments 6
    // If installments_variations empty then use sdk.settings?.max_installments
 
    static func generateInstallemnts(sdk: CardlinkSDK) -> [InstallmentsVariation] {
        guard var amount = sdk.payment?.amount,
              let allVariations = sdk.settings?.installments_variations else {
            return []
        }
        
        amount = amount / 100
        
        var variationsFormatted: [InstallmentsVariation] = []
        
        
        var variationsRanges: [InstallmentsRange] = allVariations.enumerated().compactMap { (index, element) -> InstallmentsRange? in
            guard let amount = element.amount else {
                return nil
            }
            
            if index == .zero {
                return .init(lowBoundAmount: 0, upperBoundAmount: Int(amount), installments: .zero)
            } else {
                if let previousAmount = allVariations[index - 1].amount,
                   let previousInstallment = allVariations[index - 1].installments {
                    return .init(lowBoundAmount: Int(previousAmount), upperBoundAmount: Int(amount), installments: previousInstallment)
                }
            }
            
            return nil
        }
        
        if let lastAmount = allVariations.last?.amount {
            variationsRanges.append(.init(lowBoundAmount: Int(lastAmount),
                                          upperBoundAmount: Int(INT32_MAX),
                                          installments: allVariations.last?.installments ?? .zero))
        }

        variationsRanges.forEach { installmentsRange in
            if amount >= installmentsRange.lowBoundAmount && installmentsRange.installments > .zero {
                variationsFormatted.append(.init(amount: Int64(bitPattern: UInt64(amount)), installments: installmentsRange.installments))
            }
        }

        if allVariations.isEmpty,
           let maxInstallments = sdk.settings?.max_installments,
           maxInstallments > .zero {
            variationsFormatted.append(.init(amount: .zero, installments: maxInstallments))
        }
        
        variationsFormatted = variationsFormatted.sorted(by: { previous, next in
            return previous.installments ?? .zero < next.installments ?? .zero
        })
        
        if !variationsFormatted.isEmpty {
            variationsFormatted.insert(InstallmentsVariation(amount: 0, installments: 0), at: 0)
        }

        return variationsFormatted
    }
}
