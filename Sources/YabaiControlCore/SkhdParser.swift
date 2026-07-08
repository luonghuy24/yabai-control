import Foundation

/// One `keys : action` line parsed from an skhd config.
public struct SkhdBinding {
    public let keys: String
    public let action: String

    public init(keys: String, action: String) {
        self.keys = keys
        self.action = action
    }
}

/// Parses skhd config text into displayable bindings.
public enum SkhdParser {
    /// Bindings read from the user's `~/.skhdrc` (empty if it doesn't exist).
    public static func bindings() -> [SkhdBinding] {
        let path = NSHomeDirectory() + "/.skhdrc"
        let content = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        return bindings(from: content)
    }

    /// Bindings parsed from arbitrary skhd config text. Skips blank lines,
    /// `#` comments, and `::` mode declarations; splits each remaining line on
    /// its first colon. Long actions are truncated for display.
    public static func bindings(from content: String) -> [SkhdBinding] {
        var result: [SkhdBinding] = []
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("::") { continue }
            guard let separator = line.range(of: ":") else { continue }
            let keys = String(line[line.startIndex..<separator.lowerBound]).trimmingCharacters(in: .whitespaces)
            if keys.isEmpty { continue }
            var action = String(line[separator.upperBound...]).trimmingCharacters(in: .whitespaces)
            if action.count > 64 {
                action = String(action.prefix(61)) + "…"
            }
            result.append(SkhdBinding(keys: keys, action: action))
        }
        return result
    }
}
