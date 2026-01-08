//
//  MarkdownFormatter.swift
//  PaperMD
//
//  Applies Markdown syntax highlighting to NSTextStorage.
//

import Cocoa

class MarkdownFormatter {

    // Use simple, standard colors and fonts to avoid crashes
    private static let baseFont = NSFont.systemFont(ofSize: 16)
    private static let boldFont = NSFont.boldSystemFont(ofSize: 16)
    private static let italicFont: NSFont = {
        // Try Menlo which has an italic variant
        if let font = NSFont(name: "Menlo-Italic", size: 16) {
            return font
        }
        // Try Monaco italic
        if let font = NSFont(name: "Monaco-Italic", size: 16) {
            return font
        }
        // Try Courier Oblique
        if let font = NSFont(name: "Courier-Oblique", size: 16) {
            return font
        }
        // Try Helvetica Oblique
        if let font = NSFont(name: "Helvetica-Oblique", size: 16) {
            return font
        }
        // Fallback: use base font with underline
        return baseFont
    }()
    private static let monoFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    // Standard system colors - use more distinct colors
    private static let headingColor: NSColor = .systemBlue
    private static let listMarkerColor: NSColor = .systemRed  // Very distinct color for list markers
    private static let tertiaryColor: NSColor = .tertiaryLabelColor
    private static let hrColor: NSColor = .separatorColor

    // MARK: - Public Methods

    static func applyFormatting(to textStorage: NSTextStorage, editedRange: NSRange) {
        let text = textStorage.string

        // Only reformat lines that were affected by the edit
        let affectedRange = lineRange(for: editedRange, in: text)
        guard affectedRange.location < text.count else { return }

        // Reset attributes in affected range to base
        textStorage.setAttributes([.font: baseFont], range: affectedRange)

        // Process each line in the affected range
        let nsString = text as NSString
        nsString.enumerateSubstrings(in: affectedRange, options: .byLines) { line, lineRange, _, _ in
            guard let line = line else { return }
            self.applyLineFormatting(line: line, range: lineRange, to: textStorage)
        }
    }

    // MARK: - Private Methods

    private static func applyLineFormatting(line: String, range: NSRange, to textStorage: NSTextStorage) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Horizontal rules (---, ***, ___)
        if isHorizontalRule(trimmed) {
            applyHorizontalRuleFormatting(range: range, to: textStorage)
            return
        }

        // Headers (# ## ### etc.)
        if trimmed.hasPrefix("#") {
            applyHeaderFormatting(line: line, trimmed: trimmed, range: range, to: textStorage)
            return
        }

        // Code blocks
        if trimmed.hasPrefix("```") {
            textStorage.addAttribute(.font, value: monoFont, range: range)
            textStorage.addAttribute(.foregroundColor, value: tertiaryColor, range: range)
            return
        }

        // Blockquotes
        if trimmed.hasPrefix(">") {
            applyQuoteFormatting(line: line, range: range, to: textStorage)
            return
        }

        // Lists - check original line, not trimmed
        if isListItem(line) {
            applyListFormatting(line: line, range: range, to: textStorage)
            // Also apply inline formatting to list content
            applyInlineFormatting(line: line, range: range, to: textStorage)
            return
        }

        // Inline formatting for regular paragraphs
        applyInlineFormatting(line: line, range: range, to: textStorage)
    }

    private static func isListItem(_ line: String) -> Bool {
        // Check original line for list markers
        if line.isEmpty { return false }

        // Check for - item (with optional leading whitespace)
        for char in line {
            if char.isWhitespace {
                continue
            }
            if char == "-" || char == "*" || char == "+" {
                // Next char should be space
                let idx = line.firstIndex(of: char)!
                let nextIdx = line.index(after: idx)
                if nextIdx < line.endIndex && line[nextIdx] == " " {
                    return true
                }
            }
            break
        }

        // Check for numbered list like "1. "
        let numberedPattern = #"^\s*\d+\.\s"#
        if let match = try? NSRegularExpression(pattern: numberedPattern, options: []).firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            return match.range.location != NSNotFound
        }

        return false
    }

    private static func getMarkerLength(_ line: String) -> Int {
        var idx = line.startIndex

        // Skip leading whitespace
        while idx < line.endIndex && line[idx].isWhitespace {
            idx = line.index(after: idx)
        }

        let markerStart = idx

        // Check for -, *, +
        if idx < line.endIndex {
            let char = line[idx]
            if char == "-" || char == "*" || char == "+" {
                idx = line.index(after: idx)
                if idx < line.endIndex && line[idx] == " " {
                    idx = line.index(after: idx)
                    return line.distance(from: line.startIndex, to: idx)
                }
            }
        }

        // Check for numbered list
        idx = markerStart
        while idx < line.endIndex && line[idx].isNumber {
            idx = line.index(after: idx)
        }
        if idx < line.endIndex && line[idx] == "." {
            idx = line.index(after: idx)
            if idx < line.endIndex && line[idx] == " " {
                idx = line.index(after: idx)
                return line.distance(from: line.startIndex, to: idx)
            }
        }

        return 0
    }

    private static func applyHeaderFormatting(line: String, trimmed: String, range: NSRange, to textStorage: NSTextStorage) {
        var hashCount = 0
        for char in trimmed {
            if char == "#" { hashCount += 1 } else { break }
        }

        let sizes = [28, 24, 20, 18, 17, 16]
        let index = min(max(hashCount - 1, 0), 5)
        let size = sizes[index]
        let font = NSFont.boldSystemFont(ofSize: CGFloat(size))

        // Count leading # and spaces
        var markerLength = 0
        for char in line {
            if char == "#" || char.isWhitespace {
                markerLength += 1
            } else {
                break
            }
        }

        // Apply header font to entire line
        textStorage.addAttribute(.font, value: font, range: range)
        textStorage.addAttribute(.foregroundColor, value: headingColor, range: range)

        // Dim the # markers
        if markerLength > 0 && markerLength <= range.length {
            let markerRange = NSRange(location: range.location, length: markerLength)
            textStorage.addAttribute(.foregroundColor, value: tertiaryColor, range: markerRange)
        }
    }

    private static func applyQuoteFormatting(line: String, range: NSRange, to textStorage: NSTextStorage) {
        var leadingWhitespace = 0
        for char in line {
            if char.isWhitespace {
                leadingWhitespace += 1
            } else {
                break
            }
        }

        if line.count > leadingWhitespace {
            let markerLocation = range.location + leadingWhitespace
            if markerLocation < range.location + range.length {
                let markerRange = NSRange(location: markerLocation, length: 1)
                textStorage.addAttribute(.font, value: boldFont, range: markerRange)
                textStorage.addAttribute(.foregroundColor, value: tertiaryColor, range: markerRange)
            }
        }
    }

    private static func applyListFormatting(line: String, range: NSRange, to textStorage: NSTextStorage) {
        let markerLength = getMarkerLength(line)

        if markerLength > 0 {
            let markerRange = NSRange(location: range.location, length: min(markerLength, range.length))

            // Get the actual marker text from storage (to detect if already formatted)
            let markerText = (textStorage.string as NSString).substring(with: markerRange)

            // Check if this is an ordered list (numbered) or unordered list
            if isOrderedList(line) {
                // Ordered list: just dim the marker, don't replace
                textStorage.addAttribute(.foregroundColor, value: tertiaryColor, range: markerRange)
            } else {
                // Unordered list: replace with bullet
                // Check if already formatted
                if markerText.contains("•") {
                    textStorage.addAttribute(.foregroundColor, value: tertiaryColor, range: markerRange)
                    return
                }

                // Replace "- " with "• " for visual display
                let bulletAttrString = NSMutableAttributedString(string: "• ")
                bulletAttrString.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: 2))
                bulletAttrString.addAttribute(.foregroundColor, value: tertiaryColor, range: NSRange(location: 0, length: 2))

                textStorage.replaceCharacters(in: markerRange, with: bulletAttrString)
            }
        }
    }

    private static func isOrderedList(_ line: String) -> Bool {
        // Simple check: does line start with (optional whitespace) + digit(s) + "." + space?
        var idx = line.startIndex

        // Skip leading whitespace
        while idx < line.endIndex && line[idx].isWhitespace {
            idx = line.index(after: idx)
        }

        // Check for digit
        var hasDigit = false
        while idx < line.endIndex && line[idx].isNumber {
            hasDigit = true
            idx = line.index(after: idx)
        }

        if !hasDigit { return false }

        // Check for "."
        guard idx < line.endIndex && line[idx] == "." else { return false }
        idx = line.index(after: idx)

        // Check for space
        guard idx < line.endIndex && line[idx] == " " else { return false }

        return true
    }

    private static func isHorizontalRule(_ trimmed: String) -> Bool {
        // Horizontal rules: ---, ***, ___ (with 3 or more characters)
        guard trimmed.count >= 3 else { return false }

        let firstChar = trimmed.first
        guard firstChar == "-" || firstChar == "*" || firstChar == "_" else { return false }

        // All non-whitespace chars must be the same
        for char in trimmed where !char.isWhitespace {
            if char != firstChar { return false }
        }

        return true
    }

    private static func applyHorizontalRuleFormatting(range: NSRange, to textStorage: NSTextStorage) {
        // Apply separator color and slightly thinner font
        textStorage.addAttribute(.foregroundColor, value: hrColor, range: range)
    }

    private static func applyInlineFormatting(line: String, range: NSRange, to textStorage: NSTextStorage) {
        // Bold (**text**)
        if line.contains("**") {
            let matches = findInlineMatches(pattern: #"(\*\*)(.+?)(\*\*)"#, in: line)
            for match in matches {
                applyInlineStyle(match: match, line: line, baseRange: range, to: textStorage, attributes: [.font: boldFont])
            }
        }

        // Italic (*text*)
        if line.contains("*") && !line.contains("**") {
            let matches = findInlineMatches(pattern: #"(\*)(?!\*)(.+?)(\*)(?!\*)"#, in: line)
            for match in matches {
                // If italic font is same as base (fallback), add underline for visibility
                if italicFont.fontName == baseFont.fontName {
                    applyInlineStyle(match: match, line: line, baseRange: range, to: textStorage, attributes: [.font: italicFont, .underlineStyle: 1])
                } else {
                    applyInlineStyle(match: match, line: line, baseRange: range, to: textStorage, attributes: [.font: italicFont])
                }
            }
        }

        // Strikethrough (~~text~~)
        if line.contains("~~") {
            let matches = findInlineMatches(pattern: #"(~)(.+?)(~)"#, in: line)
            for match in matches {
                applyInlineStyle(match: match, line: line, baseRange: range, to: textStorage, attributes: [.strikethroughStyle: 1])
            }
        }

        // Inline code (`code`)
        if line.contains("`") {
            let matches = findInlineMatches(pattern: #"(`)(.+?)(`)"#, in: line)
            for match in matches {
                applyInlineStyle(match: match, line: line, baseRange: range, to: textStorage, attributes: [.font: monoFont, .foregroundColor: NSColor.systemRed])
            }
        }

        // Links [text](url)
        if line.contains("[") {
            let matches = findInlineMatches(pattern: #"(\[)(.+?)(\]\()(.+?)(\))"#, in: line)
            for match in matches {
                // For links, capture group 2 is the display text
                applyInlineStyle(match: match, line: line, baseRange: range, to: textStorage, contentGroup: 2, attributes: [.foregroundColor: NSColor.systemBlue, .underlineStyle: 1])
            }
        }

        // Images ![alt](url)
        if line.contains("![") {
            let matches = findInlineMatches(pattern: #"(!\[(.+?)(\]\()(.+?)(\))"#, in: line)
            for match in matches {
                // For images, capture group 2 is the alt text
                applyInlineStyle(match: match, line: line, baseRange: range, to: textStorage, contentGroup: 2, attributes: [.foregroundColor: NSColor.systemPurple])
            }
        }
    }

    private struct InlineMatch {
        let fullRange: NSRange
        let contentRange: NSRange
        let delimiterRanges: [NSRange]
    }

    private static func findInlineMatches(pattern: String, in line: String) -> [InlineMatch] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }

        let lineRange = NSRange(location: 0, length: line.utf16.count)
        let matches = regex.matches(in: line, options: [], range: lineRange)

        var result: [InlineMatch] = []

        for match in matches {
            if match.numberOfRanges >= 4 {
                let fullRange = match.range(at: 0)
                let contentRange = match.range(at: 2)

                var delimiters: [NSRange] = []
                for i in 1..<match.numberOfRanges where i != 2 {
                    if match.range(at: i).location != NSNotFound {
                        delimiters.append(match.range(at: i))
                    }
                }

                result.append(InlineMatch(fullRange: fullRange, contentRange: contentRange, delimiterRanges: delimiters))
            }
        }

        return result
    }

    private static func applyInlineStyle(
        match: InlineMatch,
        line: String,
        baseRange: NSRange,
        to textStorage: NSTextStorage,
        contentGroup: Int = 2,
        attributes: [NSAttributedString.Key: Any]
    ) {
        // Convert line-relative ranges to absolute ranges
        let globalContentRange = NSRange(location: baseRange.location + match.contentRange.location, length: match.contentRange.length)

        // Validate range
        let maxLocation = baseRange.location + baseRange.length
        guard globalContentRange.location < maxLocation else { return }

        let adjustedLength = min(globalContentRange.length, maxLocation - globalContentRange.location)
        let finalRange = NSRange(location: globalContentRange.location, length: adjustedLength)

        // Apply attributes to content
        textStorage.addAttributes(attributes, range: finalRange)

        // Dim delimiters
        for delimRange in match.delimiterRanges {
            let globalDelimRange = NSRange(location: baseRange.location + delimRange.location, length: min(delimRange.length, baseRange.length))
            if globalDelimRange.location + globalDelimRange.length <= maxLocation {
                textStorage.addAttribute(.foregroundColor, value: tertiaryColor, range: globalDelimRange)
            }
        }
    }

    private static func lineRange(for range: NSRange, in text: String) -> NSRange {
        let start = text.index(text.startIndex, offsetBy: range.location)
        let end = text.index(start, offsetBy: range.length, limitedBy: text.endIndex) ?? text.endIndex

        let lineStart = text.lineRange(for: start..<start).lowerBound
        let lineEnd = text.lineRange(for: end..<end).upperBound

        let location = text.distance(from: text.startIndex, to: lineStart)
        let length = text.distance(from: lineStart, to: lineEnd)

        return NSRange(location: location, length: length)
    }
}
