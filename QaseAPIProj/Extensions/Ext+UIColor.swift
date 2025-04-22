//
//  Ext+UIColor.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 07.01.2025.
//

import UIKit

extension UIColor {
    /// Создаёт UIColor из HEX строки
    /// - Parameters:
    ///   - hex: HEX строка формата "#RRGGBB" или "#RRGGBBAA"
    ///   - alpha: Прозрачность (если не указана в HEX строке)
    convenience init?(hex: String, alpha: CGFloat? = nil) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Удаляем "#"
        if hexFormatted.hasPrefix("#") {
            hexFormatted.removeFirst()
        }
        
        // Проверка длины
        guard hexFormatted.count == 6 || hexFormatted.count == 8 else { return nil }
        
        var rgbValue: UInt64 = 0
        let scanner = Scanner(string: hexFormatted)
        guard scanner.scanHexInt64(&rgbValue) else { return nil }
        
        let r, g, b: CGFloat
        var a: CGFloat = 1.0
        
        if hexFormatted.count == 6 {
            r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgbValue & 0x0000FF) / 255.0
            if let customAlpha = alpha { a = customAlpha }
        } else {
            r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgbValue & 0x000000FF) / 255.0
            if let customAlpha = alpha { a = customAlpha } // позволяет перекрыть alpha из hex
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    /// Преобразует UIColor в HEX строку
    func toHex(includeAlpha: Bool = false) -> String {
        guard let components = cgColor.components else { return "#FFFFFF" }
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        
        if components.count >= 3 {
            r = components[0]
            g = components[1]
            b = components[2]
            a = components.count >= 4 ? components[3] : 1.0
        } else if components.count == 2 {
            // Grayscale + alpha
            r = components[0]
            g = components[0]
            b = components[0]
            a = components[1]
        } else if components.count == 1 {
            // Grayscale only
            r = components[0]
            g = components[0]
            b = components[0]
        }
        
        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X",
                          Int(r * 255),
                          Int(g * 255),
                          Int(b * 255),
                          Int(a * 255))
        } else {
            return String(format: "#%02X%02X%02X",
                          Int(r * 255),
                          Int(g * 255),
                          Int(b * 255))
        }
    }
}
