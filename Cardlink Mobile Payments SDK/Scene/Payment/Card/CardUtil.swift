//
//  CardUtil.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 11/1/23.
//

class CardUtil {
    static func removeNonDigits(string: String, andPreserveCursorPosition cursorPosition: inout Int) -> String {
        var digitsOnlyString = ""
        let originalCursorPosition = cursorPosition
        
        for i in Swift.stride(from: 0, to: string.count, by: 1) {
            let characterToAdd = string[string.index(string.startIndex, offsetBy: i)]
            if characterToAdd >= "0" && characterToAdd <= "9" {
                digitsOnlyString.append(characterToAdd)
            }
            else if i < originalCursorPosition {
                cursorPosition -= 1
            }
        }
        
        return digitsOnlyString
    }
    
    static func panWithSpacesCursorPositionAndGroups(pan: String, cursorPosition: Int) -> (String, Int, [Int]) {
        var newCursorPosition = cursorPosition
        
        // Mapping of card prefix to pattern is taken from
        // https://baymard.com/checkout-usability/credit-card-patterns
        
        // UATP cards have 4-5-6 (XXXX-XXXXX-XXXXXX) format
        let is456 = pan.hasPrefix("1")
        
        // These prefixes reliably indicate either a 4-6-5 or 4-6-4 card. We treat all these
        // as 4-6-5-4 to err on the side of always letting the user type more digits.
        let is465 = [
            // Amex
            "34", "37",
            
            // Diners Club
            "300", "301", "302", "303", "304", "305", "309", "36", "38", "39"
        ].contains { pan.hasPrefix($0) }
        
        // In all other cases, assume 4-4-4-4-3.
        // This won't always be correct; for instance, Maestro has 4-4-5 cards according
        // to https://baymard.com/checkout-usability/credit-card-patterns, but I don't
        // know what prefixes identify particular formats.
        let is4444 = !(is456 || is465)
        
        var panWithSpaces = ""
        let cursorPositionInSpacelessString = cursorPosition
        
        for i in 0..<pan.count {
            let needs465Spacing = (is465 && (i == 4 || i == 10 || i == 15))
            let needs456Spacing = (is456 && (i == 4 || i == 9 || i == 15))
            let needs4444Spacing = (is4444 && i > 0 && (i % 4) == 0)
            
            if needs465Spacing || needs456Spacing || needs4444Spacing {
                panWithSpaces.append(" ")
                
                if i < cursorPositionInSpacelessString {
                    newCursorPosition += 1
                }
            }
            
            let characterToAdd = pan[pan.index(pan.startIndex, offsetBy:i)]
            panWithSpaces.append(characterToAdd)
        }
        
        let groups: [ Int ]
        if is456 {
            if pan.count > 15 {
                groups = [ 4, 5, 6, 4 ]
            } else {
                groups = [ 4, 5, 6 ]
            }
        } else if is465 {
            if pan.count > 14 {
                if pan.count > 15 {
                    groups = [ 4, 6, 5, 4 ]
                } else {
                    groups = [ 4, 6, 5 ]
                }
            } else {
                groups = [ 4, 6, 4 ]
            }
        } else {
            if pan.count > 16 {
                groups = [ 4, 4, 4, 4, 3 ]
            } else {
                groups = [ 4, 4, 4, 4 ]
            }
        }
        
        return (panWithSpaces, newCursorPosition, groups)
    }
    
    static func panPreview(_ panSoFar: String, groups: [ Int ]) -> String {
        var panPreview = ""
        var currentIndex = panSoFar.index(panSoFar.startIndex, offsetBy: 0, limitedBy: panSoFar.endIndex)
        var i = 0
        for group in groups {
            for _ in 0 ..< group {
                let character: String
                if let currentIndex = currentIndex {
                    character = currentIndex < panSoFar.endIndex
                    ? String(panSoFar[currentIndex])
                    : "•"
                } else {
                    character = "•"
                }
                
                panPreview += character
                if let currentIndex2 = currentIndex {
                    currentIndex = panSoFar.index(currentIndex2, offsetBy: 1, limitedBy: panSoFar.endIndex)
                } else {
                    currentIndex = nil
                }
            }
            
            if let currentIndex2 = currentIndex {
                currentIndex = panSoFar.index(currentIndex2, offsetBy: 1, limitedBy: panSoFar.endIndex)
            } else {
                currentIndex = nil
            }
            
            if i + 1 < groups.count {
                panPreview += " "
            }
            
            i += 1
        }
        
        return panPreview
    }
    
    static func dateWithSeparators(
        _ string: String,
        currentValue: String?,
        previousValue: String?,
        preserveCursorPosition cursorPosition: inout Int
    ) -> String {
        var string = string
        var stringWithAddedSeparator = ""
        let cursorPositionInSpacelessString = cursorPosition
        
        let firstCharacter = string.intAt(0)
        if firstCharacter > 1 {
            if string.count == 1 {
                string = "0\(firstCharacter)"
                cursorPosition += 2
            } else {
                return ""
            }
        }
        
        for i in 0..<string.count {
            if i == 1 {
                if
                    string.intAt(0) != 0 && string.intAt(1) > 2 ||
                        i == 1 && string.intAt(0) == 0 && string.intAt(1) == 0
                {
                    return stringWithAddedSeparator
                }
            }
            
            let characterToAdd = string[string.index(string.startIndex, offsetBy:i)]
            stringWithAddedSeparator.append(characterToAdd)
            
            if previousValue?.last == "/" && string.count == 2 && currentValue?.count == 2 {
                return stringWithAddedSeparator
            }
            
            if
                !(previousValue?.count == 3 && string.count == 2) &&
                    i == 1 && string.count > 1 && string.asciiAt(i) != "/"
            {
                stringWithAddedSeparator.append("/")
                if i < cursorPositionInSpacelessString {
                    cursorPosition += 1
                }
            }
        }
        
        return stringWithAddedSeparator
    }
    
    static func formattedCardHolder(_ cardHolder: String) -> String {
        return cardHolder.replacingOccurrences(of: "[^a-zA-Z0-9 .'-]", with: "", options: [ .regularExpression ])
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: [ .regularExpression ])
            .replacingOccurrences(of: "'{2,}", with: "'", options: [ .regularExpression ])
            .replacingOccurrences(of: "\\.{2,}", with: ".", options: [ .regularExpression ])
            .replacingOccurrences(of: "-{2,}", with: "-", options: [ .regularExpression ])
            .trimLeadingSpaces()
            .uppercased()
    }
}
