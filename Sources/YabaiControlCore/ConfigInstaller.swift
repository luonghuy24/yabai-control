import Foundation

/// Writes config files to disk, backing up any existing file first.
public enum ConfigInstaller {
    /// True if a regular (non-directory) file exists at `path`.
    public static func exists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let present = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return present && !isDirectory.boolValue
    }

    /// Writes `contents` (UTF-8) to `path`. If a file already exists there, it is
    /// first moved to `"<path>.bak.<timestamp>"`. Creates the parent directory if
    /// needed. Throws before writing if the backup move fails, so the original is
    /// never lost. Returns the backup path if one was created, else `nil`.
    @discardableResult
    public static func write(_ contents: String, to path: String, timestamp: String) throws -> String? {
        let fileManager = FileManager.default

        let parent = (path as NSString).deletingLastPathComponent
        if !parent.isEmpty && !fileManager.fileExists(atPath: parent) {
            try fileManager.createDirectory(atPath: parent, withIntermediateDirectories: true)
        }

        var backupPath: String?
        if exists(at: path) {
            let backup = "\(path).bak.\(timestamp)"
            if fileManager.fileExists(atPath: backup) {
                try fileManager.removeItem(atPath: backup)
            }
            try fileManager.moveItem(atPath: path, toPath: backup)
            backupPath = backup
        }

        try contents.write(toFile: path, atomically: true, encoding: .utf8)
        return backupPath
    }
}
