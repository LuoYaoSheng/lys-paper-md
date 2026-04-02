//
//  MarkdownFormatter.swift
//  PaperMD
//
//  Applies Markdown syntax highlighting to NSTextStorage.
//

import Cocoa

class MarkdownFormatter {

    // MARK: - Font Management

    private static var baseFontSize: CGFloat = 16

    private static var baseFont: NSFont {
        NSFont.systemFont(ofSize: baseFontSize)
    }

    private static var boldFont: NSFont {
        NSFont.boldSystemFont(ofSize: baseFontSize)
    }

    private static var italicFont: NSFont {
        // Try Menlo which has an italic variant
        if let font = NSFont(name: "Menlo-Italic", size: baseFontSize) {
            return font
        }
        // Try Monaco italic
        if let font = NSFont(name: "Monaco-Italic", size: baseFontSize) {
            return font
        }
        // Try Courier Oblique
        if let font = NSFont(name: "Courier-Oblique", size: baseFontSize) {
            return font
        }
        // Try Helvetica Oblique
        if let font = NSFont(name: "Helvetica-Oblique", size: baseFontSize) {
            return font
        }
        // Fallback: use base font with underline
        return baseFont
    }

    private static var monoFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: baseFontSize - 2, weight: .regular)
    }

    private static var headingFont: NSFont {
        NSFont.boldSystemFont(ofSize: baseFontSize)
    }

    // MARK: - Colors

    private static let headingColor: NSColor = .systemBlue
    private static let codeColor: NSColor = .systemPink
    private static let linkColor: NSColor = .systemBlue
    private static let imageColor: NSColor = .systemPurple
    private static let listMarkerColor: NSColor = .systemOrange
    private static let quoteColor: NSColor = .systemTeal
    private static let metaColor: NSColor = .secondaryLabelColor
    private static let hrColor: NSColor = .separatorColor
    private static let htmlTagColor: NSColor = .systemBrown
    private static var taskColor: NSColor = .systemGray

    // MARK: - Public Methods

    static func applyFormatting(to textStorage: NSTextStorage, editedRange: NSRange) {
        let text = textStorage.string

        // Safety check: ensure text is not empty and range is valid
        guard !text.isEmpty else { return }
        guard editedRange.location <= text.count else { return }

        // Only reformat lines that were affected by the edit
        let affectedRange = lineRange(for: editedRange, in: text)
        guard affectedRange.location < text.count else { return }

        // Expand range to include potential code blocks
        let expandedRange = expandRangeToIncludeCodeBlocks(affectedRange, in: text)

        // Reset attributes in affected range to base
        textStorage.setAttributes([.font: baseFont, .foregroundColor: NSColor.labelColor], range: expandedRange)

        // Process each line in the affected range
        let nsString = text as NSString
        var inCodeBlock = false

        nsString.enumerateSubstrings(in: expandedRange, options: .byLines) { line, lineRange, _, _ in
            guard let line = line else { return }

            // Track code block state
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") || line.trimmingCharacters(in: .whitespaces).hasPrefix("~~~") {
                inCodeBlock.toggle()
                self.applyCodeBlockFenceFormatting(line: line, range: lineRange, to: textStorage)
                return
            }

            if inCodeBlock {
                self.applyCodeBlockContentFormatting(range: lineRange, to: textStorage)
                return
            }

            // Check for Setext-style header underline (=== or ---)
            if isSetextHeaderUnderline(line) {
                self.applySetextHeaderFormatting(line: line, range: lineRange, to: textStorage, text: text as NSString)
                return
            }

            self.applyLineFormatting(line: line, range: lineRange, to: textStorage)
        }
    }

    static func setFontSize(_ size: Int) {
        baseFontSize = CGFloat(size)
    }

    // MARK: - Private Methods - Range Expansion

    private static func expandRangeToIncludeCodeBlocks(_ range: NSRange, in text: String) -> NSRange {
        let lines = text.components(separatedBy: .newlines)
        var startLine = 0
        var endLine = lines.count - 1

        // Find the line numbers for the range
        var currentPos = 0
        for (i, line) in lines.enumerated() {
            if currentPos + line.utf16.count >= range.location {
                startLine = i
                break
            }
            currentPos += line.utf16.count + 1
        }

        currentPos = 0
        for (i, line) in lines.enumerated() {
            if currentPos + line.utf16.count >= range.location + range.length {
                endLine = i
                break
            }
            currentPos += line.utf16.count + 1
        }

        // Expand backwards to find code block start
        var inBlock = false
        for i in (0...startLine).reversed() {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inBlock = true
                startLine = i
                break
            }
            if inBlock && trimmed.hasPrefix("```") {
                inBlock = false
                break
            }
        }

        // Expand forwards to find code block end
        inBlock = false
        for i in startLine..<min(lines.count, endLine + 100) {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inBlock = !inBlock
                if !inBlock {
                    endLine = i
                    break
                }
            }
            if i == endLine && inBlock {
                endLine = i
            }
        }

        // Convert back to character range
        var startChar = 0
        for i in 0..<startLine {
            startChar += lines[i].utf16.count + 1
        }

        var endChar = startChar
        for i in startLine...endLine {
            endChar += lines[i].utf16.count + 1
        }

        return NSRange(location: startChar, length: max(range.length, endChar - startChar))
    }

    // MARK: - Private Methods - Line Formatting

    private static func applyLineFormatting(line: String, range: NSRange, to textStorage: NSTextStorage) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Horizontal rules (---, ***, ___)
        if isHorizontalRule(trimmed) {
            applyHorizontalRuleFormatting(range: range, to: textStorage)
            return
        }

        // ATX-style headers (# ## ### etc.)
        if trimmed.hasPrefix("#") {
            applyATXHeaderFormatting(line: line, trimmed: trimmed, range: range, to: textStorage)
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

    // MARK: - Code Blocks

    private static func applyCodeBlockFenceFormatting(line: String, range: NSRange, to textStorage: NSTextStorage) {
        textStorage.addAttribute(.font, value: monoFont, range: range)
        textStorage.addAttribute(.foregroundColor, value: metaColor, range: range)

        // Highlight language specifier if present
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.count > 3 {
            let fenceEnd = trimmed.index(trimmed.startIndex, offsetBy: 3)
            let afterFence = trimmed[fenceEnd...].trimmingCharacters(in: .whitespaces)

            if !afterFence.isEmpty {
                let langStart = range.location + (trimmed.distance(from: trimmed.startIndex, to: fenceEnd))
                let langLength = afterFence.count
                let langRange = NSRange(location: langStart, length: min(langLength, range.length))

                textStorage.addAttribute(.foregroundColor, value: codeColor, range: langRange)
            }
        }
    }

    private static func applyCodeBlockContentFormatting(range: NSRange, to textStorage: NSTextStorage) {
        textStorage.addAttribute(.font, value: monoFont, range: range)
        textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
    }

    // MARK: - Headers

    private static func applyATXHeaderFormatting(line: String, trimmed: String, range: NSRange, to textStorage: NSTextStorage) {
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
            textStorage.addAttribute(.foregroundColor, value: metaColor, range: markerRange)
        }
    }

    private static func isSetextHeaderUnderline(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return false }

        let firstChar = trimmed.first
        guard firstChar == "=" || firstChar == "-" else { return false }

        // All chars must be the same
        for char in trimmed where !char.isWhitespace {
            if char != firstChar { return false }
        }

        return true
    }

    private static func applySetextHeaderFormatting(line: String, range: NSRange, to textStorage: NSTextStorage, text: NSString) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let isH1 = trimmed.first == "="

        // Get the previous line (actual header text)
        let prevLineEnd = range.location - 1
        guard prevLineEnd >= 0 else { return }

        let prevLineStart = text.lineRange(for: NSRange(location: prevLineEnd, length: 0)).location

        if prevLineStart >= range.location { return }

        let headerTextRange = NSRange(location: prevLineStart, length: range.location - 1 - prevLineStart)
        let size: CGFloat = isH1 ? 28 : 24

        // Apply header formatting to the text line
        let headerFont = NSFont.boldSystemFont(ofSize: size)
        textStorage.addAttribute(.font, value: headerFont, range: headerTextRange)
        textStorage.addAttribute(.foregroundColor, value: headingColor, range: headerTextRange)

        // Format the underline
        textStorage.addAttribute(.font, value: boldFont, range: range)
        textStorage.addAttribute(.foregroundColor, value: metaColor, range: range)
    }

    // MARK: - Blockquotes

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
            // Find all quote markers (nested quotes: > > >)
            var offset = leadingWhitespace
            var quoteDepth = 0

            while offset < line.count {
                let idx = line.index(line.startIndex, offsetBy: offset)
                let char = line[idx]

                if char == ">" {
                    quoteDepth += 1
                    let markerRange = NSRange(location: range.location + offset, length: 1)
                    textStorage.addAttribute(.font, value: boldFont, range: markerRange)
                    textStorage.addAttribute(.foregroundColor, value: metaColor, range: markerRange)

                    offset += 1
                    // Skip space after >
                    if offset < line.count {
                        let nextIdx = line.index(line.startIndex, offsetBy: offset)
                        if line[nextIdx].isWhitespace {
                            offset += 1
                        }
                    }
                } else if !char.isWhitespace {
                    break
                } else {
                    offset += 1
                }
            }

            // Apply quote color to the content based on depth
            if quoteDepth > 0 && offset < line.count {
                let contentRange = NSRange(location: range.location + offset, length: range.length - offset)
                // Vary the color by depth
                let colors: [NSColor] = [.labelColor, quoteColor, .systemGreen, .systemOrange]
                let colorIndex = min(quoteDepth - 1, colors.count - 1)
                textStorage.addAttribute(.foregroundColor, value: colors[colorIndex], range: contentRange)
            }

            // Apply inline formatting to quote content
            applyInlineFormatting(line: line, range: range, to: textStorage)
        }
    }

    // MARK: - Horizontal Rules

    private static func isHorizontalRule(_ trimmed: String) -> Bool {
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
        textStorage.addAttribute(.foregroundColor, value: hrColor, range: range)
    }

    // MARK: - Lists

    private static func isListItem(_ line: String) -> Bool {
        guard !line.isEmpty else { return false }

        // Check for - , * , + (with optional leading whitespace)
        var idx = line.startIndex
        while idx < line.endIndex && line[idx].isWhitespace {
            idx = line.index(after: idx)
        }

        if idx < line.endIndex {
            let char = line[idx]
            if char == "-" || char == "*" || char == "+" {
                let nextIdx = line.index(after: idx)
                if nextIdx < line.endIndex && line[nextIdx] == " " {
                    return true
                }
            }
        }

        // Check for numbered list like "1. "
        let numberedPattern = #"^\s*\d+\.\s"#
        if let match = try? NSRegularExpression(pattern: numberedPattern).firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            return match.range.location != NSNotFound
        }

        return false
    }

    private static func getMarkerInfo(_ line: String) -> (length: Int, type: ListMarkerType, content: String?) {
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

                    // Check for task list - [ ] or - [x]
                    let remaining = String(line[idx...])
                    if remaining.hasPrefix("[ ]") || remaining.hasPrefix("[x]") || remaining.hasPrefix("[X]") {
                        let checkboxLength: Int
                        let isChecked: Bool
                        if remaining.hasPrefix("[x]") || remaining.hasPrefix("[X]") {
                            checkboxLength = 4
                            isChecked = true
                        } else {
                            checkboxLength = 4
                            isChecked = false
                        }

                        let totalLength = line.distance(from: line.startIndex, to: idx) + checkboxLength
                        return (totalLength, .task(isChecked), nil)
                    }

                    let length = line.distance(from: line.startIndex, to: idx)
                    return (length, .bullet, nil)
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
                let length = line.distance(from: line.startIndex, to: idx)
                return (length, .numbered, nil)
            }
        }

        return (0, .bullet, nil)
    }

    private enum ListMarkerType {
        case bullet
        case numbered
        case task(Bool) // true = checked, false = unchecked
    }

    private static func applyListFormatting(line: String, range: NSRange, to textStorage: NSTextStorage) {
        let markerInfo = getMarkerInfo(line)

        if markerInfo.length > 0 {
            let markerRange = NSRange(location: range.location, length: min(markerInfo.length, range.length))

            switch markerInfo.type {
            case .bullet:
                // Keep the source Markdown unchanged and only style the marker.
                textStorage.addAttribute(.foregroundColor, value: listMarkerColor, range: markerRange)

            case .numbered:
                textStorage.addAttribute(.foregroundColor, value: metaColor, range: markerRange)

            case .task(let isChecked):
                let taskMarkerColor = isChecked ? NSColor.systemGreen : taskColor
                textStorage.addAttribute(.foregroundColor, value: taskMarkerColor, range: markerRange)
            }
        }
    }

    // MARK: - Inline Formatting

    private static func applyInlineFormatting(line: String, range: NSRange, to textStorage: NSTextStorage) {
        // Code blocks take priority (shouldn't format inside code)
        let codeRanges = findInlineCodeRanges(in: line)

        // Bold (**text**)
        if line.contains("**") {
            let matches = findInlineMatches(pattern: #"(\*\*)([^*]+?)(\*\*)"#, in: line)
            for match in matches {
                if !isInsideCode(match.fullRange, codeRanges: codeRanges) {
                    applyInlineStyle(match: match, baseRange: range, to: textStorage, attributes: [.font: boldFont])
                }
            }
        }

        // Italic (*text* or _text_)
        if line.contains("*") || line.contains("_") {
            // Check for *text* (but not **text**)
            let starMatches = findInlineMatches(pattern: #"(\*)(?!\*)([^*\n]+?)(\*)(?!\*)"#, in: line)
            for match in starMatches {
                if !isInsideCode(match.fullRange, codeRanges: codeRanges) {
                    if italicFont.fontName == baseFont.fontName {
                        applyInlineStyle(match: match, baseRange: range, to: textStorage, attributes: [.font: italicFont, .underlineStyle: 0])
                    } else {
                        applyInlineStyle(match: match, baseRange: range, to: textStorage, attributes: [.font: italicFont])
                    }
                }
            }

            // Check for _text_ (but not __text__)
            let underscoreMatches = findInlineMatches(pattern: #"(_)(?!__)([^_\n]+?)(_)(?!_)"#, in: line)
            for match in underscoreMatches {
                if !isInsideCode(match.fullRange, codeRanges: codeRanges) {
                    applyInlineStyle(match: match, baseRange: range, to: textStorage, attributes: [.font: italicFont])
                }
            }
        }

        // Bold (__text__)
        if line.contains("__") {
            let matches = findInlineMatches(pattern: #"(__)([^_]+?)(__)"#, in: line)
            for match in matches {
                if !isInsideCode(match.fullRange, codeRanges: codeRanges) {
                    applyInlineStyle(match: match, baseRange: range, to: textStorage, attributes: [.font: boldFont])
                }
            }
        }

        // Strikethrough (~~text~~)
        if line.contains("~~") {
            let matches = findInlineMatches(pattern: #"(~~)(.+?)(~~)"#, in: line)
            for match in matches {
                if !isInsideCode(match.fullRange, codeRanges: codeRanges) {
                    applyInlineStyle(match: match, baseRange: range, to: textStorage, attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
                }
            }
        }

        // Inline code (`code`)
        for codeRange in codeRanges {
            let absoluteRange = NSRange(location: range.location + codeRange.location, length: codeRange.length)
            if absoluteRange.location + absoluteRange.length <= range.location + range.length {
                textStorage.addAttribute(.font, value: monoFont, range: absoluteRange)
                textStorage.addAttribute(.foregroundColor, value: codeColor, range: absoluteRange)

                // Dim the backticks
                if codeRange.length >= 2 {
                    let startTick = NSRange(location: absoluteRange.location, length: 1)
                    let endTick = NSRange(location: absoluteRange.location + absoluteRange.length - 1, length: 1)
                    textStorage.addAttribute(.foregroundColor, value: metaColor, range: startTick)
                    textStorage.addAttribute(.foregroundColor, value: metaColor, range: endTick)
                }
            }
        }

        // Links [text](url)
        if line.contains("[") {
            let matches = findInlineMatches(pattern: #"(\[)([^\]]+?)(\]\()([^)]+?)(\))"#, in: line)
            for match in matches {
                if !isInsideCode(match.fullRange, codeRanges: codeRanges) {
                    // For links, capture group 2 is the display text
                    applyLinkStyle(match: match, baseRange: range, to: textStorage)
                }
            }
        }

        // Images ![alt](url)
        if line.contains("![") {
            let matches = findInlineMatches(pattern: #"(!\[)([^\]]+?)(\]\()([^)]+?)(\))"#, in: line)
            for match in matches {
                if !isInsideCode(match.fullRange, codeRanges: codeRanges) {
                    applyImageStyle(match: match, baseRange: range, to: textStorage)
                }
            }
        }

        // HTML tags
        if line.contains("<") {
            applyHTMLTagFormatting(line: line, range: range, to: textStorage, codeRanges: codeRanges)
        }
    }

    private static func findInlineCodeRanges(in line: String) -> [NSRange] {
        var ranges: [NSRange] = []
        var searchStart = line.startIndex

        while let startIndex = line[searchStart...].firstIndex(of: "`") {
            let absoluteStart = line.distance(from: line.startIndex, to: startIndex)

            // Find closing backtick
            searchStart = line.index(after: startIndex)
            guard let endIndex = line[searchStart...].firstIndex(of: "`") else {
                break
            }

            let absoluteEnd = line.distance(from: line.startIndex, to: endIndex)
            ranges.append(NSRange(location: absoluteStart, length: absoluteEnd - absoluteStart + 1))

            searchStart = line.index(after: endIndex)
        }

        return ranges
    }

    private static func isInsideCode(_ range: NSRange, codeRanges: [NSRange]) -> Bool {
        return codeRanges.contains { codeRange in
            NSLocationInRange(range.location, codeRange) ||
            NSLocationInRange(range.location + range.length - 1, codeRange) ||
            (range.location < codeRange.location && range.location + range.length > codeRange.location + codeRange.length)
        }
    }

    private static func applyHTMLTagFormatting(line: String, range: NSRange, to textStorage: NSTextStorage, codeRanges: [NSRange]) {
        // Pattern for HTML tags: <tag attr="value">
        let pattern = #"<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let lineRange = NSRange(location: 0, length: line.utf16.count)
        let matches = regex.matches(in: line, options: [], range: lineRange)

        for match in matches {
            let tagRange = match.range
            if !isInsideCode(tagRange, codeRanges: codeRanges) {
                let absoluteRange = NSRange(location: range.location + tagRange.location, length: tagRange.length)
                if absoluteRange.location + absoluteRange.length <= range.location + range.length {
                    textStorage.addAttribute(.font, value: monoFont, range: absoluteRange)
                    textStorage.addAttribute(.foregroundColor, value: htmlTagColor, range: absoluteRange)

                    // Highlight tag name separately
                    if match.numberOfRanges > 1 {
                        let nameRange = match.range(at: 1)
                        let absoluteNameRange = NSRange(location: range.location + nameRange.location, length: nameRange.length)
                        textStorage.addAttribute(.foregroundColor, value: codeColor, range: absoluteNameRange)
                    }
                }
            }
        }
    }

    private static func applyLinkStyle(match: InlineMatch, baseRange: NSRange, to textStorage: NSTextStorage) {
        // match structure: [displayText](url)
        // Groups: 1="[", 2=displayText, 3="](", 4=url, 5=")”

        // Display text (group 2)
        let textContentRange = match.range(at: 2)
        let globalTextRange = NSRange(location: baseRange.location + textContentRange.location, length: textContentRange.length)

        if globalTextRange.location + globalTextRange.length <= baseRange.location + baseRange.length {
            textStorage.addAttribute(.foregroundColor, value: linkColor, range: globalTextRange)
            textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: globalTextRange)
        }

        // Dim delimiters and URL
        let delimiterRanges = [match.range(at: 1), match.range(at: 3), match.range(at: 4), match.range(at: 5)]
        for delimRange in delimiterRanges {
            if delimRange.location != NSNotFound {
                let globalDelimRange = NSRange(location: baseRange.location + delimRange.location, length: delimRange.length)
                if globalDelimRange.location + globalDelimRange.length <= baseRange.location + baseRange.length {
                    textStorage.addAttribute(.foregroundColor, value: metaColor, range: globalDelimRange)
                }
            }
        }
    }

    private static func applyImageStyle(match: InlineMatch, baseRange: NSRange, to textStorage: NSTextStorage) {
        // match structure: ![alt](url)
        // Groups: 1="![", 2=alt, 3="](", 4=url, 5=")”

        // Alt text (group 2)
        let altRange = match.range(at: 2)
        let globalAltRange = NSRange(location: baseRange.location + altRange.location, length: altRange.length)

        if globalAltRange.location + globalAltRange.length <= baseRange.location + baseRange.length {
            textStorage.addAttribute(.foregroundColor, value: imageColor, range: globalAltRange)
        }

        // Dim delimiters and URL
        let delimiterRanges = [match.range(at: 1), match.range(at: 3), match.range(at: 4), match.range(at: 5)]
        for delimRange in delimiterRanges {
            if delimRange.location != NSNotFound {
                let globalDelimRange = NSRange(location: baseRange.location + delimRange.location, length: delimRange.length)
                if globalDelimRange.location + globalDelimRange.length <= baseRange.location + baseRange.length {
                    textStorage.addAttribute(.foregroundColor, value: metaColor, range: globalDelimRange)
                }
            }
        }
    }

    // MARK: - Inline Match Helpers

    private struct InlineMatch {
        let fullRange: NSRange
        let contentRange: NSRange
        let delimiterRanges: [NSRange]

        func range(at group: Int) -> NSRange {
            if group == 0 { return fullRange }
            if group == 2 { return contentRange }
            if group - 1 < delimiterRanges.count {
                return delimiterRanges[group - 1]
            }
            return NSRange(location: NSNotFound, length: 0)
        }
    }

    private static func findInlineMatches(pattern: String, in line: String) -> [InlineMatch] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

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
        baseRange: NSRange,
        to textStorage: NSTextStorage,
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
                textStorage.addAttribute(.foregroundColor, value: metaColor, range: globalDelimRange)
            }
        }
    }

    // MARK: - Utility

    private static func lineRange(for range: NSRange, in text: String) -> NSRange {
        guard !text.isEmpty else { return NSRange(location: 0, length: 0) }
        guard range.location <= text.count else { return NSRange(location: 0, length: 0) }

        let start = text.index(text.startIndex, offsetBy: min(range.location, text.count))
        let end = text.index(start, offsetBy: min(range.length, text.distance(from: start, to: text.endIndex)), limitedBy: text.endIndex) ?? text.endIndex

        let lineStart = text.lineRange(for: start..<start).lowerBound
        let lineEnd = text.lineRange(for: end..<end).upperBound

        let location = text.distance(from: text.startIndex, to: lineStart)
        let length = text.distance(from: lineStart, to: lineEnd)

        return NSRange(location: location, length: length)
    }
}
