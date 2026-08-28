import Foundation

enum USBFormatting {
    static func chargePercentage(currentCapacity: Int, maximumCapacity: Int) -> Int? {
        guard currentCapacity >= 0, maximumCapacity > 0 else { return nil }

        let percentage = (Double(currentCapacity) / Double(maximumCapacity)) * 100
        guard percentage.isFinite else { return nil }
        return Int(min(max(percentage, 0), 100))
    }

    static func megabitsPerSecond(fromBitsPerSecond bitsPerSecond: Double) -> Int? {
        guard bitsPerSecond.isFinite, bitsPerSecond > 0 else { return nil }

        let megabitsPerSecond = bitsPerSecond / 1_000_000
        guard megabitsPerSecond >= 1, megabitsPerSecond < Double(Int.max) else { return nil }
        return Int(megabitsPerSecond)
    }

    static func thunderboltMegabitsPerSecond(fromLinkBandwidth linkBandwidth: Int) -> Int? {
        guard linkBandwidth > 0 else { return nil }

        let (megabitsPerSecond, overflow) = linkBandwidth.multipliedReportingOverflow(by: 100)
        return overflow ? nil : megabitsPerSecond
    }

    static func usbVersionLabel(from binaryCodedDecimal: Int?) -> String? {
        guard let binaryCodedDecimal else { return nil }

        let major = (binaryCodedDecimal >> 8) & 0xFF
        let minorHigh = (binaryCodedDecimal >> 4) & 0x0F
        let minorLow = binaryCodedDecimal & 0x0F
        let minor = minorHigh * 10 + minorLow

        func format(_ label: String) -> String {
            "\(label) (0x\(String(format: "%04X", binaryCodedDecimal)))"
        }

        switch major {
        case 1 where binaryCodedDecimal == 0x0100:
            return format("USB 1.0")
        case 1 where binaryCodedDecimal == 0x0110:
            return format("USB 1.1")
        case 1:
            return format("USB 1.\(minor)")
        case 2:
            return format("USB \(major).\(minor)")
        case 3 where binaryCodedDecimal >= 0x0320:
            return format("USB 3.2")
        case 3 where binaryCodedDecimal >= 0x0310:
            return format("USB 3.1")
        case 3:
            return format("USB 3.0")
        case 4 where binaryCodedDecimal >= 0x0420:
            return format("USB4 2.0")
        case 4:
            return format("USB4")
        default:
            let version = minor == 0 ? "\(major)" : "\(major).\(minor)"
            return format("USB \(version)")
        }
    }

    static func speedTierLabel(for megabitsPerSecond: Int) -> String {
        switch megabitsPerSecond {
        case 1, 2: "USB 1.0 \("low_speed".localized) (1.5 Mbps)"
        case 12: "USB 1.1 \("full_speed".localized) (12 Mbps)"
        case 480: "USB 2.0 \("high_speed".localized) (480 Mbps)"
        case 5_000: "USB 3.0 / 3.1 Gen1 / 3.2 Gen1x1 (5 Gbps)"
        case 10_000: "USB 3.1 Gen2 / 3.2 Gen2x1 (10 Gbps)"
        case 20_000: "USB 3.2 Gen2x2 / USB4 Gen2x2 (20 Gbps)"
        case 40_000: "USB4 Gen3x2 / Thunderbolt 3/4 (40 Gbps)"
        case 80_000: "USB4 v2 Gen4x2 / Thunderbolt 5 (80 Gbps)"
        default: transferRate(megabitsPerSecond)
        }
    }

    static func transferRate(_ megabitsPerSecond: Int) -> String {
        if megabitsPerSecond >= 1_000 {
            return String(format: "%.1f Gbps", Double(megabitsPerSecond) / 1_000)
        }
        return "\(megabitsPerSecond) Mbps"
    }
}
