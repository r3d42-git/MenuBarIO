enum DeviceCountFormatter {
    static func string(for value: Int) -> String {
        value > 99 ? "99＋" : String(value)
    }
}
