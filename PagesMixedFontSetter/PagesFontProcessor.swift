import AppKit
import Foundation

enum PagesFontProcessor {
    static func collectCJKRanges(in text: String) -> [ClosedRange<Int>] {
        let characters = Array(text)
        guard !characters.isEmpty else {
            return []
        }

        var ranges: [ClosedRange<Int>] = []
        var runStart: Int?

        for (index, character) in characters.enumerated() {
            let position = index + 1
            let isCJK = isCJKCharacter(character)

            if isCJK {
                if runStart == nil {
                    runStart = position
                }
            } else if let start = runStart {
                ranges.append(start...(position - 1))
                runStart = nil
            }
        }

        if let start = runStart {
            ranges.append(start...characters.count)
        }

        return ranges
    }

    private static func isCJKCharacter(_ character: Character) -> Bool {
        for scalar in character.unicodeScalars {
            let value = scalar.value

            if (0x4E00...0x9FFF).contains(value) { return true }
            if (0x3400...0x4DBF).contains(value) { return true }
            if (0x3000...0x303F).contains(value) { return true }
            if (0xFF00...0xFFEF).contains(value) { return true }
            if (0x20000...0x2FA1F).contains(value) { return true }
        }

        return false
    }
}

enum PagesBridge {
    private static let pagesBundleIdentifier = "com.apple.iWork.Pages"

    static func ensurePagesReady() throws {
        let isPagesRunning = NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == pagesBundleIdentifier || app.localizedName == "Pages"
        }
        guard isPagesRunning else {
            throw UserFacingError(
                title: "未偵測到 Pages",
                message: "請先開啟 Pages 應用程式並打開一個文件。",
                style: .critical
            )
        }

        let documentCountScript = """
        tell application "Pages"
            return count of documents
        end tell
        """

        let descriptor = try execute(script: documentCountScript)
        let documentCount = descriptor?.int32Value ?? 0
        guard documentCount > 0 else {
            throw UserFacingError(
                title: "未偵測到文件",
                message: "請先在 Pages 中開啟一個文件。",
                style: .critical
            )
        }
    }

    static func fetchBodyText() throws -> String {
        let script = """
        tell application "Pages"
            tell front document
                return body text as text
            end tell
        end tell
        """

        let descriptor = try execute(script: script)
        return descriptor?.stringValue ?? ""
    }

    static func applyFonts(englishFont: String, chineseFont: String, cjkRanges: [ClosedRange<Int>]) throws {
        let setEnglishFontScript = """
        tell application "Pages"
            activate
            tell front document
                set font of body text to \(appleScriptString(englishFont))
            end tell
        end tell
        """

        _ = try execute(script: setEnglishFontScript)

        guard !cjkRanges.isEmpty else {
            return
        }

        for chunk in cjkRanges.chunked(into: 250) {
            let rangeLiteral = chunk
                .map { "{\($0.lowerBound), \($0.upperBound)}" }
                .joined(separator: ", ")

            let script = """
            set chineseFontName to \(appleScriptString(chineseFont))
            set cjkRanges to {\(rangeLiteral)}
            tell application "Pages"
                tell front document
                    repeat with rangeItem in cjkRanges
                        set startIndex to item 1 of rangeItem
                        set endIndex to item 2 of rangeItem
                        set font of characters startIndex thru endIndex of body text to chineseFontName
                    end repeat
                end tell
            end tell
            """

            _ = try execute(script: script)
        }
    }

    @discardableResult
    private static func execute(script: String) throws -> NSAppleEventDescriptor? {
        guard let appleScript = NSAppleScript(source: script) else {
            throw UserFacingError(
                title: "AppleScript 初始化失敗",
                message: "無法建立執行 Pages 所需的 AppleScript。",
                style: .critical
            )
        }

        var errorInfo: NSDictionary?
        let result = appleScript.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let message = [
                errorInfo[NSAppleScript.errorMessage] as? String,
                errorInfo[NSAppleScript.errorBriefMessage] as? String
            ]
            .compactMap { $0 }
            .joined(separator: "\n")

            throw UserFacingError(
                title: "Pages 操作失敗",
                message: message.isEmpty ? "發生未知的 AppleScript 錯誤。" : message,
                style: .critical
            )
        }

        return result
    }

    private static func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }

        var chunks: [[Element]] = []
        chunks.reserveCapacity((count + size - 1) / size)

        var index = startIndex
        while index < endIndex {
            let nextIndex = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(Array(self[index..<nextIndex]))
            index = nextIndex
        }

        return chunks
    }
}
