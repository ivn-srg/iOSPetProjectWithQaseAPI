@testable import QaseAPIProj
import Testing
import UIKit

@Suite @MainActor
struct DesignTokenTests {
    @Test func primaryButtonWhiteTextMeetsContrastInBothThemes() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for color in [AppTheme.Palette.buttonStart, AppTheme.Palette.buttonEnd] {
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                #expect(color.resolvedColor(with: traits).getRed(
                    &red,
                    green: &green,
                    blue: &blue,
                    alpha: &alpha
                ))
                let shade = 1 - AppTheme.Palette.buttonContrastOverlay
                let components = [Double(red) * shade, Double(green) * shade, Double(blue) * shade].map {
                    $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4)
                }
                let luminance = components[0] * 0.2126 + components[1] * 0.7152 + components[2] * 0.0722
                #expect(1.05 / (luminance + 0.05) >= 4.5)
            }
        }
    }
}
