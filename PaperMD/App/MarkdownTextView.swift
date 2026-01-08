//
//  MarkdownTextView.swift
//  PaperMD
//
//  Custom NSTextView with smart Markdown editing features.
//

import Cocoa

class MarkdownTextView: NSTextView {

    // MARK: - Properties

    // Document URL for image storage
    var documentURL: URL?

    // Register for dragged types
    override var acceptableDragTypes: [NSPasteboard.PasteboardType] {
        return [
            .png,
            .tiff,
            .fileURL,
            .string
        ]
    }

    // MARK: - Initialization

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupDragAndDrop()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDragAndDrop()
    }

    private func setupDragAndDrop() {
        // Register for dragged types
        registerForDraggedTypes([
            .png,
            .tiff,
            .fileURL,
            .string
        ])
    }

    // MARK: - First Responder

    override var acceptsFirstResponder: Bool {
        return true
    }

    // Ensure the textView has a valid undoManager
    override var undoManager: UndoManager? {
        if let manager = super.undoManager {
            return manager
        }
        // If the textView doesn't have an undoManager yet, return the window's undoManager
        return window?.undoManager
    }

    // MARK: - Text Editing with Undo Support

    override func shouldChangeText(in affectedCharRange: NSRange, replacementString: String?) -> Bool {
        // Enable undo registration before text changes
        // This ensures typing is recorded for undo
        let result = super.shouldChangeText(in: affectedCharRange, replacementString: replacementString)
        NSLog("PaperMD: shouldChangeText called, result=\(result), undoManager=\(undoManager?.canUndo ?? false)")
        return result
    }

    // MARK: - Undo/Redo Support

    @objc func undo(_ sender: Any?) {
        undoManager?.undo()
    }

    @objc func redo(_ sender: Any?) {
        undoManager?.redo()
    }

    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        // Enable/disable undo menu items based on undoManager state
        guard let action = item.action else { return super.validateUserInterfaceItem(item) }

        let actionString = NSStringFromSelector(action)
        if actionString == "undo:" {
            return undoManager?.canUndo ?? false
        }
        if actionString == "redo:" {
            return undoManager?.canRedo ?? false
        }

        return super.validateUserInterfaceItem(item)
    }

    // MARK: - Paste as Plain Text / Image

    override func paste(_ sender: Any?) {
        // First check for image in pasteboard
        if ImageHandler.handlePastedImage(in: self, documentURL: documentURL) {
            return
        }

        // Always paste as plain text to avoid bringing in unwanted formatting
        let pasteboard = NSPasteboard.general
        guard let plainText = pasteboard.string(forType: .string) else {
            super.paste(sender)
            return
        }

        // Insert plain text at current selection
        let selectedRange = self.selectedRange
        replaceCharacters(in: selectedRange, with: plainText)

        // Set selection to end of pasted text
        let newRange = NSRange(location: selectedRange.location + plainText.count, length: 0)
        setSelectedRange(newRange)
    }

    // MARK: - Key Handling

    override func keyDown(with event: NSEvent) {
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Don't intercept command key combinations - let them go to menu actions
        // This allows ⌘S (save), ⌘C (copy), ⌘V (paste), etc. to work
        if modifiers.contains(.command) {
            super.keyDown(with: event)
            return
        }

        // Handle Enter key for smart list continuation
        if keyCode == 36 && modifiers.isEmpty { // 36 is Return key
            if handleReturnKey() {
                return
            }
        }

        // Handle Tab key for list indentation
        if keyCode == 48 && modifiers.isEmpty { // 48 is Tab key
            if handleTabKey(forward: true) {
                return
            }
        }

        // Handle Shift-Tab for unindenting
        if keyCode == 48 && modifiers.contains(.shift) { // 48 is Tab key
            if handleTabKey(forward: false) {
                return
            }
        }

        // Handle Backspace for empty list item termination
        if keyCode == 51 && modifiers.isEmpty { // 51 is Delete/Backspace
            if handleBackspaceKey() {
                return
            }
        }

        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Handle ⌘Z and ⌘Shift+Z directly for undo/redo
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        NSLog("PaperMD: performKeyEquivalent keyCode=\(keyCode), modifiers=\(modifiers), characters=\(event.characters ?? "none")")

        // ⌘Z = undo (keyCode 6)
        // ⌘Shift+Z = redo (keyCode 6 with shift)
        if modifiers.contains(.command) {
            if keyCode == 6 {  // Z key
                NSLog("PaperMD: Detected ⌘Z, canUndo=\(undoManager?.canUndo ?? false), redoing=\(undoManager?.canRedo ?? false)")
                if modifiers.contains(.shift) {
                    // Redo
                    NSLog("PaperMD: Calling redo()")
                    undoManager?.redo()
                } else {
                    // Undo
                    NSLog("PaperMD: Calling undo()")
                    undoManager?.undo()
                }
                return true
            }
        }

        // Let NSTextView handle other standard key equivalents
        return super.performKeyEquivalent(with: event)
    }

    // MARK: - Smart List Continuation

    private func handleReturnKey() -> Bool {
        let text = string as NSString
        let selectedRange = self.selectedRange

        // Find the start of the current line
        let lineRange = text.lineRange(for: selectedRange)
        let currentLine = text.substring(with: lineRange)

        // Check if this line is a list item
        if let listMarker = detectListMarker(in: currentLine) {
            // Check if the cursor is at the end of the line (content after cursor is just whitespace)
            let textAfterCursor = text.substring(with: NSRange(location: selectedRange.location + selectedRange.length, length: lineRange.location + lineRange.length - selectedRange.location - selectedRange.length))

            if textAfterCursor.trimmingCharacters(in: .whitespaces).isEmpty {
                // Check if the line only contains the marker (empty list item)
                let content = String(currentLine.dropFirst(listMarker.count)).trimmingCharacters(in: .whitespaces)

                if content.isEmpty {
                    // Empty list item - terminate the list
                    // Remove the marker and let default newline behavior proceed
                    let rangeToRemove = NSRange(location: lineRange.location, length: listMarker.count)
                    replaceCharacters(in: rangeToRemove, with: "")
                    // Then let the default behavior handle the newline
                    return false
                } else {
                    // Non-empty list item - continue the list
                    insertNewlineWithListMarker(listMarker)
                    return true
                }
            }
        }

        return false
    }

    private func insertNewlineWithListMarker(_ marker: String) {
        let selectedRange = self.selectedRange

        // Insert newline with marker
        let insertion = "\n\(marker)"
        replaceCharacters(in: selectedRange, with: insertion)

        // Move cursor after the marker
        let newLocation = selectedRange.location + insertion.count
        setSelectedRange(NSRange(location: newLocation, length: 0))

        // Mark document as edited
        needsDisplay = true
    }

    private func detectListMarker(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Unordered list: - , * , + (followed by space)
        let unorderedPatterns = ["^- ", "^* ", "^+ "]
        for pattern in unorderedPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) {
                let markerRange = match.range
                if markerRange.location < trimmed.utf16.count {
                    return String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: markerRange.location)..<trimmed.index(trimmed.startIndex, offsetBy: markerRange.location + markerRange.length)])
                }
            }
        }

        // Ordered list: 1. , 2. , etc.
        let orderedPattern = #"^\d+\.\s+"#
        if let regex = try? NSRegularExpression(pattern: orderedPattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) {
            let markerRange = match.range
            if markerRange.location < trimmed.utf16.count {
                let marker = String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: markerRange.location)..<trimmed.index(trimmed.startIndex, offsetBy: markerRange.location + markerRange.length)])

                // Increment the number for ordered lists
                if let currentNumber = extractNumber(from: marker) {
                    let newMarker = "\(currentNumber + 1). "
                    return newMarker
                }
                return marker
            }
        }

        // Task list: - [ ] or - [x]
        let taskPattern = #"^-\s\[\s?\]\s+"#
        if let regex = try? NSRegularExpression(pattern: taskPattern),
           regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) != nil {
            return "- [ ] "
        }

        return nil
    }

    private func extractNumber(from marker: String) -> Int? {
        let numberPattern = #"^(\d+)\."#
        if let regex = try? NSRegularExpression(pattern: numberPattern),
           let match = regex.firstMatch(in: marker, range: NSRange(location: 0, length: marker.utf16.count)),
           let numberRange = Range(match.range(at: 1), in: marker) {
            return Int(marker[numberRange])
        }
        return nil
    }

    // MARK: - Tab Indentation

    private func handleTabKey(forward: Bool) -> Bool {
        let text = string as NSString
        let selectedRange = self.selectedRange

        // Find the start of the current line
        let lineRange = text.lineRange(for: selectedRange)
        let currentLine = text.substring(with: lineRange)

        // Check if this line is a list item
        if let _ = detectListMarker(in: currentLine) {
            if forward {
                // Indent: add two spaces at the beginning
                let indent = "  "
                replaceCharacters(in: NSRange(location: lineRange.location, length: 0), with: indent)
                // Move cursor
                setSelectedRange(NSRange(location: selectedRange.location + indent.count, length: selectedRange.length))
            } else {
                // Unindent: remove two spaces if present
                let lineStart = text.substring(with: NSRange(location: lineRange.location, length: min(2, lineRange.length)))
                if lineStart.hasPrefix("  ") || lineStart.hasPrefix("\t") {
                    let charsToRemove = lineStart.hasPrefix("  ") ? 2 : 1
                    replaceCharacters(in: NSRange(location: lineRange.location, length: charsToRemove), with: "")
                    // Move cursor
                    setSelectedRange(NSRange(location: selectedRange.location - charsToRemove, length: selectedRange.length))
                }
            }
            return true
        }

        return false
    }

    // MARK: - Backspace Handling

    private func handleBackspaceKey() -> Bool {
        let text = string as NSString
        let selectedRange = self.selectedRange

        guard selectedRange.length == 0 else {
            // Has selection - let default behavior handle it
            return false
        }

        guard selectedRange.location > 0 else {
            return false
        }

        // Find the start of the current line
        let lineRange = text.lineRange(for: selectedRange)
        let currentLine = text.substring(with: lineRange)

        // Check if this is an empty list item (only the marker)
        if let marker = detectListMarker(in: currentLine) {
            let content = String(currentLine.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)

            if content.isEmpty {
                // Check if cursor is right after the marker
                let cursorPositionInLine = selectedRange.location - lineRange.location
                if cursorPositionInLine >= marker.count {
                    // Remove the entire line (marker + leading spaces)
                    let rangeToRemove = NSRange(location: lineRange.location, length: lineRange.length - 1) // -1 to exclude newline

                    // Also need to remove the newline from previous line
                    let startToDelete = lineRange.location > 0 ? lineRange.location - 1 : 0
                    let finalRange = NSRange(location: startToDelete, length: lineRange.location > 0 ? rangeToRemove.length + 1 : rangeToRemove.length)

                    replaceCharacters(in: finalRange, with: "")
                    setSelectedRange(NSRange(location: startToDelete, length: 0))
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Drag and Drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if canAcceptDrag(sender) {
            return .copy
        }
        return super.draggingEntered(sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if canAcceptDrag(sender) {
            return .copy
        }
        return super.draggingUpdated(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        // Check for image file URLs
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in fileURLs {
                // Try to load as image
                if let image = NSImage(contentsOf: url) {
                    let characterIndex = characterIndexForPoint(sender.draggingLocation)
                    if ImageHandler.handleDroppedImage(in: self, at: characterIndex, image: image, documentURL: documentURL) {
                        return true
                    }
                }
            }
        }

        // Check for direct image data
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData) {
            let characterIndex = characterIndexForPoint(sender.draggingLocation)
            return ImageHandler.handleDroppedImage(in: self, at: characterIndex, image: image, documentURL: documentURL)
        }

        // Default handling for text
        return super.performDragOperation(sender)
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        // Clean up after drag operation
        super.concludeDragOperation(sender)
    }

    private func canAcceptDrag(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        // Check for file URLs
        if pasteboard.availableType(from: [.fileURL]) != nil {
            return true
        }

        // Check for image data
        if pasteboard.availableType(from: [.png, .tiff]) != nil {
            return true
        }

        return false
    }

    private func characterIndexForPoint(_ point: NSPoint) -> Int {
        let localPoint = convert(point, from: nil)
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else {
            return 0
        }
        return layoutManager.characterIndex(for: localPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}
