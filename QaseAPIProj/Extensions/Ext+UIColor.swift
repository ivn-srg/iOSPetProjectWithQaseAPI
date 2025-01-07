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
        
        // Удаляем "#" если есть
        if hexFormatted.hasPrefix("#") {
            hexFormatted.removeFirst()
        }
        
        // Проверяем валидность HEX
        guard hexFormatted.count == 6 || hexFormatted.count == 8 else { return nil }
        
        var rgb: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgb)
        
        let r, g, b: CGFloat
        let a: CGFloat
        
        if hexFormatted.count == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = alpha ?? 1.0
        } else {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    /// Преобразует UIColor в HEX строку
    func toHex(includeAlpha: Bool = false) -> String {
        guard let components = cgColor.components else { return "#FFFFFF" }
        let r = components[0]
        let g = components[1]
        let b = components.count > 2 ? components[2] : 1.0
        let a = components.count > 3 ? components[3] : 1.0
        
        if includeAlpha {
            return String(format: "#%02lX%02lX%02lX%02lX",
                          lroundf(Float(r * 255)),
                          lroundf(Float(g * 255)),
                          lroundf(Float(b * 255)),
                          lroundf(Float(a * 255)))
        } else {
            return String(format: "#%02lX%02lX%02lX",
                          lroundf(Float(r * 255)),
                          lroundf(Float(g * 255)),
                          lroundf(Float(b * 255)))
        }
    }
}
