enum DeviceCountFormatter {
    private static let romanNumerals = [
        (1_000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
        (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
        (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]

    private static let greekNumerals = [
        (900, "ϡ"), (800, "ω"), (700, "ψ"), (600, "χ"), (500, "φ"),
        (400, "υ"), (300, "τ"), (200, "σ"), (100, "ρ"),
        (90, "ϟ"), (80, "π"), (70, "ο"), (60, "ξ"), (50, "ν"),
        (40, "μ"), (30, "λ"), (20, "κ"), (10, "ι"),
        (9, "θ"), (8, "η"), (7, "ζ"), (6, "ϛ"), (5, "ε"),
        (4, "δ"), (3, "γ"), (2, "β"), (1, "α"),
    ]

    private static let egyptianNumerals = [
        (1_000_000, "𓁨"),
        (100_000, "𓆐"),
        (10_000, "𓂭"),
        (1_000, "𓆼"),
        (100, "𓍢"),
        (10, "𓎆"),
        (1, "𓏺"),
    ]

    static func string(for value: Int, representation: NumberRepresentation) -> String {
        switch representation {
        case .base10:
            return value > 99 ? "99＋" : String(value)
        case .egyptian:
            return additiveString(for: value, numerals: egyptianNumerals)
        case .greek:
            return additiveString(for: value, numerals: greekNumerals)
        case .roman:
            return additiveString(for: value, numerals: romanNumerals)
        }
    }

    private static func additiveString(
        for value: Int,
        numerals: [(value: Int, symbol: String)]
    ) -> String {
        var remainder = abs(value)
        var result = ""

        for numeral in numerals {
            let count = remainder / numeral.value
            if count > 0 {
                result += String(repeating: numeral.symbol, count: count)
                remainder -= numeral.value * count
            }
        }

        return value < 0 ? "-\(result)" : result
    }
}
