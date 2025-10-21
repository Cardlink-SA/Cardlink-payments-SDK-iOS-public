//
//  String+.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 28/11/22.
//

extension String {
    func trimLeadingSpaces() -> String {
        return trimLeading(" ")
    }
    
    func trimLeading(_ character: Character) -> String {
        var t = self
        while t.hasPrefix(String(character)) {
            t = "" + t.dropFirst()
        }
        return t
    }
    
    func trimTrailing(_ character: Character) -> String {
        var t = self
        while t.hasSuffix(String(character)) {
            t = "" + t.dropLast()
        }
        return t
    }
    
    func trimWhiteSpace() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func removeNonDigits() -> String {
        return filter("0123456789".contains)
    }
    
    func asciiAt(_ index: Int) -> String? {
        guard
            let index = self.index(startIndex, offsetBy: index, limitedBy: endIndex),
            index < endIndex
        else {
            return nil
        }
        
        return String(self[index])
    }
    
    func intAt(_ index: Int) -> Int {
        return Int(asciiAt(index) ?? "") ?? 0
    }
    
    func jsonDictionary() -> [ String : Any ]? {
        do {
            guard
                let stringData = data(using: .utf8),
                let jsonObject = try JSONSerialization.jsonObject(with: stringData, options: []) as? [String: Any]
            else {
                return nil
            }
            
            return jsonObject
        } catch {
            return nil
        }
    }
    
    func jsonType<Type: Decodable>() -> Type? {
        do {
            guard
                let stringData = data(using: .utf8)
            else {
                return nil
            }
            
            return try JSONDecoder().decode(Type.self, from: stringData)
        } catch {
            SimpleLog().e(error.localizedDescription)
            return nil
        }
    }
    
    func properHtmlStructure() -> String {
        if self.localizedCaseInsensitiveContains("<head>") {
            return self
        }
        
        return """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no" />
</head>
<body>
\(self)
</body>
</html
"""
    }
}
