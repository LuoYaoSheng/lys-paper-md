//
//  ExportHelper.swift
//  PaperMD
//
//  Handles export to HTML and PDF formats.
//

import Cocoa

class ExportHelper {

    // MARK: - HTML Export

    static func convertToHTML(markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)

        // Process line by line
        var result = ""
        var inCodeBlock = false

        for line in lines {
            // Check for code block
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                inCodeBlock.toggle()
                if inCodeBlock {
                    result += "<pre><code>"
                } else {
                    result += "</code></pre>\n"
                }
                continue
            }

            if inCodeBlock {
                result += line + "\n"
                continue
            }

            // Process each line
            result += processLine(line) + "\n"
        }

        // Wrap in HTML structure
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Document</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.6; }
                h1, h2, h3, h4, h5, h6 { margin-top: 1.5em; margin-bottom: 0.5em; font-weight: 600; }
                h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                h2 { font-size: 1.5em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                h3 { font-size: 1.25em; }
                code { background: #f4f4f4; padding: 0.2em 0.4em; border-radius: 3px; font-family: 'SF Mono', Monaco, monospace; font-size: 0.9em; }
                pre { background: #f4f4f4; padding: 1em; border-radius: 5px; overflow-x: auto; }
                pre code { background: none; padding: 0; }
                blockquote { border-left: 4px solid #ddd; padding-left: 1em; margin-left: 0; color: #666; }
                ul, ol { padding-left: 2em; }
                a { color: #0066cc; text-decoration: none; }
                a:hover { text-decoration: underline; }
                hr { border: none; border-top: 1px solid #eee; margin: 2em 0; }
            </style>
        </head>
        <body>
        \(result)
        </body>
        </html>
        """
    }

    private static func processLine(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        var result = line

        // Horizontal rule
        if isHorizontalRule(trimmed) {
            return "<hr>"
        }

        // Headers
        if trimmed.hasPrefix("#") {
            return processHeader(trimmed)
        }

        // Blockquote
        if trimmed.hasPrefix(">") {
            return processBlockquote(line)
        }

        // Lists
        if isListItem(line) {
            return processListItem(line)
        }

        // Inline formatting
        result = processInlineFormatting(result)

        return result
    }

    private static func processHeader(_ trimmed: String) -> String {
        var level = 0
        for char in trimmed {
            if char == "#" {
                level += 1
            } else {
                break
            }
        }

        let content = trimmed.dropFirst(level).trimmingCharacters(in: .whitespaces)
        let inlineContent = processInlineFormatting(content)

        switch level {
        case 1: return "<h1>\(inlineContent)</h1>"
        case 2: return "<h2>\(inlineContent)</h2>"
        case 3: return "<h3>\(inlineContent)</h3>"
        case 4: return "<h4>\(inlineContent)</h4>"
        case 5: return "<h5>\(inlineContent)</h5>"
        case 6: return "<h6>\(inlineContent)</h6>"
        default: return "<p>\(inlineContent)</p>"
        }
    }

    private static func processBlockquote(_ line: String) -> String {
        var content = line
        if content.hasPrefix(">") {
            content = String(content.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        let inlineContent = processInlineFormatting(content)
        return "<blockquote>\(inlineContent)</blockquote>"
    }

    private static func processListItem(_ line: String) -> String {
        var content = line

        // Remove list marker
        if let markerRange = line.range(of: #"^[\s]*[-*+]\s"#, options: .regularExpression) {
            content = String(line[markerRange.upperBound...])
        } else if let markerRange = line.range(of: #"^[\s]*\d+\.\s"#, options: .regularExpression) {
            content = String(line[markerRange.upperBound...])
        }

        let inlineContent = processInlineFormatting(content)
        return "<li>\(inlineContent)</li>"
    }

    private static func processInlineFormatting(_ line: String) -> String {
        var result = line

        // Bold **text**
        result = result.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)

        // Italic *text*
        result = result.replacingOccurrences(of: #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, with: "<em>$1</em>", options: .regularExpression)

        // Strikethrough ~~text~~
        result = result.replacingOccurrences(of: #"~~(.+?)~~"#, with: "<del>$1</del>", options: .regularExpression)

        // Inline code `text`
        result = result.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)

        // Links [text](url)
        result = result.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)

        // Images ![alt](url)
        result = result.replacingOccurrences(of: #"!\[(.+?)\]\((.+?)\)"#, with: "<img src=\"$2\" alt=\"$1\">", options: .regularExpression)

        return result
    }

    private static func isHorizontalRule(_ trimmed: String) -> Bool {
        guard trimmed.count >= 3 else { return false }
        let firstChar = trimmed.first
        guard firstChar == "-" || firstChar == "*" || firstChar == "_" else { return false }

        for char in trimmed where !char.isWhitespace {
            if char != firstChar { return false }
        }

        return true
    }

    private static func isListItem(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return false }

        let unorderedPattern = #"^[\s]*[-*+]\s"#
        let orderedPattern = #"^[\s]*\d+\.\s"#

        let lineRange = NSRange(location: 0, length: line.utf16.count)

        if let _ = try? NSRegularExpression(pattern: unorderedPattern).firstMatch(in: line, range: lineRange) {
            return true
        }

        if let _ = try? NSRegularExpression(pattern: orderedPattern).firstMatch(in: line, range: lineRange) {
            return true
        }

        return false
    }

    private static func isOrderedList(_ trimmed: String) -> Bool {
        let pattern = #"^\d+\.\s"#
        if let _ = try? NSRegularExpression(pattern: pattern).firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) {
            return true
        }
        return false
    }

    // MARK: - Save to File

    static func saveToURL(_ content: String, url: URL, fileType: ExportFileType) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
        NSLog("PaperMD: Exported to \(fileType.rawValue) at \(url.path)")
    }

    // MARK: - Print (PDF via Print)

    static func printDocument(textView: NSTextView, window: NSWindow) {
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic

        let printOp = NSPrintOperation(view: textView, printInfo: printInfo)
        printOp.showsPrintPanel = true
        printOp.run()
    }
}

// MARK: - Export File Type

enum ExportFileType: String {
    case html = "html"
    case pdf = "pdf"
}
