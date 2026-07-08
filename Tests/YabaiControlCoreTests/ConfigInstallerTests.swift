import Foundation
import YabaiControlCore

func runConfigInstallerTests(_ t: TestRunner) {
    let dir = NSTemporaryDirectory() + "yctest-" + UUID().uuidString
    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: dir) }

    // exists reflects file presence
    let existsPath = dir + "/exists-probe"
    t.check(ConfigInstaller.exists(at: existsPath) == false, "exists is false for a missing file")
    try? "x".write(toFile: existsPath, atomically: true, encoding: .utf8)
    t.check(ConfigInstaller.exists(at: existsPath) == true, "exists is true after a write")

    // write to an absent path creates the file and returns nil backup
    let absentPath = dir + "/absent"
    let absentBackup = try? ConfigInstaller.write("hello", to: absentPath, timestamp: "T1")
    t.check((absentBackup ?? nil) == nil, "write to absent path returns nil backup")
    t.check((try? String(contentsOfFile: absentPath, encoding: .utf8)) == "hello", "absent path gets exact contents")

    // write to an existing path backs up the original, then writes
    let existingPath = dir + "/existing"
    try? "original".write(toFile: existingPath, atomically: true, encoding: .utf8)
    let existingBackup = try? ConfigInstaller.write("new", to: existingPath, timestamp: "T2")
    t.check((existingBackup ?? nil) == existingPath + ".bak.T2", "existing path returns timestamped backup path")
    t.check((try? String(contentsOfFile: existingPath, encoding: .utf8)) == "new", "existing path overwritten with new contents")
    t.check((try? String(contentsOfFile: existingPath + ".bak.T2", encoding: .utf8)) == "original", "backup preserves original contents")
}
