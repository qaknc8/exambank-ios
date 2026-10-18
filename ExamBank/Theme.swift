import SwiftUI
import UIKit

extension Color {
    static let brand = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.44, green: 0.89, blue: 0.73, alpha: 1)
        }
        return UIColor(red: 0.12, green: 0.45, blue: 0.38, alpha: 1)
    })

    static let brandDeep = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.60, green: 0.95, blue: 0.82, alpha: 1)
        }
        return UIColor(red: 0.06, green: 0.28, blue: 0.24, alpha: 1)
    })

    static let paper = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.055, green: 0.075, blue: 0.069, alpha: 1)
        }
        return UIColor(red: 0.965, green: 0.957, blue: 0.933, alpha: 1)
    })

    static let card = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.095, green: 0.122, blue: 0.112, alpha: 1)
        }
        return UIColor.white
    })

    static let ink = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.92, green: 0.95, blue: 0.93, alpha: 1)
        }
        return UIColor(red: 0.07, green: 0.17, blue: 0.15, alpha: 1)
    })

    static let inkSoft = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.66, green: 0.73, blue: 0.70, alpha: 1)
        }
        return UIColor(red: 0.34, green: 0.40, blue: 0.38, alpha: 1)
    })

    static let line = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.18, green: 0.23, blue: 0.21, alpha: 1)
        }
        return UIColor(red: 0.88, green: 0.88, blue: 0.85, alpha: 1)
    })

    static let brandWash = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.30, green: 0.62, blue: 0.52, alpha: 1)
        }
        return UIColor(red: 0.72, green: 0.90, blue: 0.82, alpha: 1)
    })
}

extension View {
    func examCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                Color.card,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.line, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }
}
