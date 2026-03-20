import AppKit

Log.info("Sibra starting...")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
