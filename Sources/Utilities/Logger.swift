import Foundation

enum Log: @unchecked Sendable {
    // Hardcoded absolute path so it works regardless of how app is launched
    private static let logFile: URL = URL(fileURLWithPath: "/tmp/Sibra.log")

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

        if FileManager.default.fileExists(atPath: logFile.path) {
            if let handle = try? FileHandle(forWritingTo: logFile) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logFile, options: .atomic)
        }
    }
}
