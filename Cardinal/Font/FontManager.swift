import SwiftUI
import CoreText

enum CustomFont {
    static let mabryProRegular = "MabryPro-Regular"
    static let mabryProBold = "MabryPro-Bold"
    static let mabryProMedium = "MabryPro-Medium"
    static let mabryProLight = "MabryPro-Light"
    static let mabryProBlack = "MabryPro-Black"
    static let mabryProItalic = "MabryPro-Italic"
    static let mabryProBoldItalic = "MabryPro-BoldItalic"
    static let mabryProMediumItalic = "MabryPro-MediumItalic"
    static let mabryProLightItalic = "MabryPro-LightItalic"
    static let mabryProBlackItalic = "MabryPro-BlackItalic"
    
    static let allFonts: [(String, String)] = [
        (mabryProRegular, "ttf"),
        (mabryProBold, "ttf"),
        (mabryProMedium, "ttf"),
        (mabryProLight, "ttf"),
        (mabryProBlack, "ttf"),
        (mabryProItalic, "ttf"),
        (mabryProBoldItalic, "ttf"),
        (mabryProMediumItalic, "ttf"),
        (mabryProLightItalic, "ttf"),
        (mabryProBlackItalic, "ttf")
    ]
}

extension Font {
    static func mabryPro(size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        let fontName: String = {
            switch weight {
            case .black:
                return italic ? CustomFont.mabryProBlackItalic : CustomFont.mabryProBlack
            case .bold:
                return italic ? CustomFont.mabryProBoldItalic : CustomFont.mabryProBold
            case .medium:
                return italic ? CustomFont.mabryProMediumItalic : CustomFont.mabryProMedium
            case .light:
                return italic ? CustomFont.mabryProLightItalic : CustomFont.mabryProLight
            default:
                return italic ? CustomFont.mabryProItalic : CustomFont.mabryProRegular
            }
        }()
        
        return .custom(fontName, size: size)
    }
}

extension UIFont {
    static func registerCustomFonts() {
        for (fontName, extension_) in CustomFont.allFonts {
            guard let fontURL = Bundle.main.url(forResource: fontName, withExtension: extension_) else {
                print("⚠️ Failed to find font file \(fontName)")
                continue
            }
            
            var error: Unmanaged<CFError>?
            guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) else {
                print("⚠️ Failed to register font \(fontName): \(error?.takeRetainedValue().localizedDescription ?? "")")
                continue
            }
            
            print("✅ Successfully registered font: \(fontName)")
        }
    }
} 