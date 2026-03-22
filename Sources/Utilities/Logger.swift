import Foundation

enum Log: @unchecked Sendable {

    private static let logFile: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sibraDir = appSupport.appendingPathComponent("Sibra")
        let logsDir = sibraDir.appendingPathComponent("logs")
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        return logsDir.appendingPathComponent("Sibra.log")
    }()

    static var logPath: String { logFile.path }

    static func info(_ msg: String) {
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] INFO: \(msg)"
        append(line)
    }

    static func error(_ msg: String) {
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] ERROR: \(msg)"
        append(line)
    }

    private static func append(_ line: String) {
        guard let data = (line + "\n").data(using: .utf8) else { return }

        // Atomic write handles create + write atomically, no handle leak
        try? data.write(to: logFile, options: .atomic)
    }
}
