import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)

        do {
            try runBundledAppleScript()
        } catch let error as UserFacingError {
            presentAlert(title: error.title, message: error.message, style: error.style)
        } catch {
            presentAlert(
                title: "執行錯誤",
                message: error.localizedDescription,
                style: .critical
            )
        }

        terminate()
    }

    private func runBundledAppleScript() throws {
        guard let scriptURL = Bundle.main.url(forResource: "PagesMixedFontSetter", withExtension: "applescript") else {
            throw UserFacingError(
                title: "找不到腳本",
                message: "App 內沒有打包到 PagesMixedFontSetter.applescript。",
                style: .critical
            )
        }

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [scriptURL.path]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let outputText = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let message = [errorText, outputText]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")

            throw UserFacingError(
                title: "AppleScript 執行失敗",
                message: message.isEmpty ? "osascript 結束時回傳錯誤。" : message,
                style: .critical
            )
        }
    }

    private func presentAlert(title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    private func terminate() {
        NSApp.terminate(nil)
    }
}

struct UserFacingError: Error {
    let title: String
    let message: String
    let style: NSAlert.Style
}
