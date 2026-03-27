import UIKit

extension UIColor {

    // MARK: - App Palette

    /// Nền chính — #221910
    static let appBackground = UIColor(hex: "#221910")!

    /// Accent / nút chính — #BD660F
    static let appAccent = UIColor(hex: "#BD660F")!

    /// Thành công — #10B981
    static let appSuccess = UIColor(hex: "#10B981")!

    /// Nguy hiểm / xoá — #EF4444
    static let appDanger = UIColor(hex: "#EF4444")!

    /// Vô hiệu hoá — #334155
    static let appDisabled = UIColor(hex: "#334155")!

    /// Văn bản trên nền tối (trắng)
    static let appTextPrimary   = UIColor.white

    /// Văn bản phụ (trắng 60%)
    static let appTextSecondary = UIColor.white.withAlphaComponent(0.6)

    // MARK: - Hex initialiser (public — replaces private copies in every file)

    convenience init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }

        let len = cleaned.count
        guard len == 6 || len == 8 else { return nil }

        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else { return nil }

        let r, g, b, a: CGFloat
        if len == 6 {
            r = CGFloat((value >> 16) & 0xFF) / 255
            g = CGFloat((value >>  8) & 0xFF) / 255
            b = CGFloat( value        & 0xFF) / 255
            a = 1
        } else {
            r = CGFloat((value >> 24) & 0xFF) / 255
            g = CGFloat((value >> 16) & 0xFF) / 255
            b = CGFloat((value >>  8) & 0xFF) / 255
            a = CGFloat( value        & 0xFF) / 255
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
