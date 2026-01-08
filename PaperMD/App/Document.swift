//
//  Document.swift
//  PaperMD
//
//  NSDocument subclass for Markdown documents.
//

import Cocoa

// Protocol for document text access - used by OutlineView
protocol DocumentTextProvider: AnyObject {
    func getText() -> String
}

// Make Document conform to DocumentTextProvider for OutlineView
class Document: NSDocument, DocumentTextProvider {

    // The raw markdown text content (source of truth)
    private var rawText: String = ""

    // Reference to the text view for content sync
    weak var textView: NSTextView?

    // Disable window restoration
    override func encodeRestorableState(with coder: NSCoder) {}
    override func restoreState(with coder: NSCoder) {}

    override class var autosavesInPlace: Bool {
        // For new documents, we want to show the save dialog first
        return false
    }

    override func makeWindowControllers() {
        // Only create window controller if we don't have one
        if !windowControllers.isEmpty {
            return
        }

        // Create the window
        let contentRect = NSRect(x: 0, y: 0, width: 800, height: 600)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = displayName.isEmpty ? "Untitled" : displayName

        // Create editor view
        let editorView = EditorView(frame: contentRect)
        editorView.document = self
        window.contentView = editorView

        // Store text view reference
        self.textView = editorView.textView

        // Load content into text view
        if !rawText.isEmpty {
            editorView.textView.string = rawText
        } else {
            editorView.textView.string = "# Hello PaperMD\n\nStart typing your Markdown here..."
        }

        window.center()

        // Set initial first responder before showing window
        window.initialFirstResponder = editorView.textView

        // Create and add window controller
        let windowController = WindowController(window: window)
        self.addWindowController(windowController)

        // Show window - the textView will automatically become first responder
        window.makeKeyAndOrderFront(nil)
    }

    override func data(ofType typeName: String) throws -> Data {
        // Get current text from text view and convert visual bullets back to markdown
        if let textView = textView {
            var text = textView.string

            // Convert "• " back to "- " for list items (preserves user intent)
            text = text.replacingOccurrences(of: "• ", with: "- ")

            rawText = text
        }
        NSLog("PaperMD: data(ofType:) called, typeName: \(typeName), fileURL: \(fileURL?.path ?? "nil"), isEdited: \(isDocumentEdited), returning \(rawText.count) characters")
        return rawText.data(using: .utf8) ?? Data()
    }

    override func save(_ sender: Any?) {
        NSLog("PaperMD: save called, fileURL: \(fileURL?.path ?? "none")")
        super.save(sender)
    }

    override func writeSafely(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) throws {
        NSLog("PaperMD: writeSafely called, url: \(url.path), typeName: \(typeName), saveOperation: \(saveOperation.rawValue)")
        try super.writeSafely(to: url, ofType: typeName, for: saveOperation)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        rawText = String(data: data, encoding: .utf8) ?? ""
        NSLog("PaperMD: read(from:) called, read \(rawText.count) characters")
    }

    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        let fileURLPath = fileURL?.path ?? "nil"
        NSLog("PaperMD: prepareSavePanel called, displayName: \(displayName), fileURL: \(fileURLPath), isEdited: \(isDocumentEdited)")
        // Set default file extension to .md
        if #available(macOS 12.0, *) {
            savePanel.allowedContentTypes = [.plainText]
        } else {
            savePanel.allowedFileTypes = ["md"]
        }
        savePanel.allowsOtherFileTypes = true
        savePanel.canCreateDirectories = true

        // Set the default filename with .md extension
        if displayName.isEmpty || displayName == "Untitled" {
            savePanel.nameFieldStringValue = "untitled.md"
        } else {
            // Ensure current name has .md extension
            if !displayName.hasSuffix(".md") {
                savePanel.nameFieldStringValue = displayName + ".md"
            } else {
                savePanel.nameFieldStringValue = displayName
            }
        }

        return true
    }

    // MARK: - Text Access

    func setText(_ text: String) {
        rawText = text
    }

    func getText() -> String {
        return rawText
    }

    // MARK: - Formatting Actions (called from menu/toolbar)

    @objc func applyBold(_ sender: Any?) {
        guard let textView = textView else { return }
        insertMarkdownAroundSelection(textView: textView, prefix: "**", suffix: "**")
    }

    @objc func applyItalic(_ sender: Any?) {
        guard let textView = textView else { return }
        insertMarkdownAroundSelection(textView: textView, prefix: "*", suffix: "*")
    }

    @objc func applyCode(_ sender: Any?) {
        guard let textView = textView else { return }
        insertMarkdownAroundSelection(textView: textView, prefix: "`", suffix: "`")
    }

    @objc func applyHeading1(_ sender: Any?) {
        guard let textView = textView else { return }
        insertMarkdownAtLineStart(textView: textView, prefix: "# ")
    }

    @objc func applyHeading2(_ sender: Any?) {
        guard let textView = textView else { return }
        insertMarkdownAtLineStart(textView: textView, prefix: "## ")
    }

    @objc func applyHeading3(_ sender: Any?) {
        guard let textView = textView else { return }
        insertMarkdownAtLineStart(textView: textView, prefix: "### ")
    }

    @objc func toggleFocusMode(_ sender: Any?) {
        // Forward to window controller
        if let windowController = windowControllers.first as? WindowController {
            windowController.toggleFocusMode(sender)
        }
    }

    @objc func toggleSidebar(_ sender: Any?) {
        // Forward to window controller
        if let windowController = windowControllers.first as? WindowController {
            windowController.toggleSidebar(sender)
        }
    }

    // MARK: - Undo/Redo Support

    @objc func undo(_ sender: Any?) {
        if let undoManager = textView?.undoManager {
            NSLog("PaperMD: undo called, canUndo=\(undoManager.canUndo)")
            undoManager.undo()
        } else {
            NSLog("PaperMD: undo called but no undoManager")
        }
    }

    @objc func redo(_ sender: Any?) {
        if let undoManager = textView?.undoManager {
            NSLog("PaperMD: redo called, canRedo=\(undoManager.canRedo)")
            undoManager.redo()
        } else {
            NSLog("PaperMD: redo called but no undoManager")
        }
    }

    private func insertMarkdownAroundSelection(textView: NSTextView, prefix: String, suffix: String) {
        let selectedRange = textView.selectedRange
        guard selectedRange.length > 0 else { return }

        let text = textView.string
        let selectedText = (text as NSString).substring(with: selectedRange)

        // Replace selection with formatted text
        let formattedText = "\(prefix)\(selectedText)\(suffix)"
        textView.replaceCharacters(in: selectedRange, with: formattedText)

        // Select the formatted text
        let newRange = NSRange(location: selectedRange.location, length: formattedText.count)
        textView.setSelectedRange(newRange)
    }

    private func insertMarkdownAtLineStart(textView: NSTextView, prefix: String) {
        let text = textView.string as NSString
        let selectedRange = textView.selectedRange

        // Find the start of the current line
        let lineStart = text.lineRange(for: selectedRange).location

        // Check if line already starts with a heading marker
        let lineRange = text.lineRange(for: NSRange(location: lineStart, length: 0))
        let line = text.substring(with: lineRange)

        // Remove existing heading markers if present
        var trimmedLine = line
        while trimmedLine.hasPrefix("#") {
            trimmedLine = String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespaces)
        }

        // Replace the line with heading prefix
        let newLine = "\(prefix)\(trimmedLine)"
        textView.replaceCharacters(in: lineRange, with: newLine)

        // Position cursor after the prefix
        let newCursorPos = lineStart + prefix.count
        textView.setSelectedRange(NSRange(location: newCursorPos, length: 0))
    }

    // MARK: - Menu Validation

    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else {
            return super.validateUserInterfaceItem(item)
        }

        // Undo/Redo validation
        let actionString = NSStringFromSelector(action)
        if actionString == "undo:" {
            return textView?.undoManager?.canUndo ?? false
        }
        if actionString == "redo:" {
            return textView?.undoManager?.canRedo ?? false
        }

        // Enable formatting menu items when we have a text view with selection
        if action == #selector(applyBold(_:)) ||
           action == #selector(applyItalic(_:)) ||
           action == #selector(applyCode(_:)) ||
           action == #selector(applyHeading1(_:)) ||
           action == #selector(applyHeading2(_:)) ||
           action == #selector(applyHeading3(_:)) {
            return textView != nil && textView!.selectedRange.length > 0
        }
        if action == #selector(toggleFocusMode(_:)) ||
           action == #selector(toggleSidebar(_:)) {
            return true
        }

        // For all other menu items (Save, etc.), use default behavior
        return super.validateUserInterfaceItem(item)
    }
}

// MARK: - Errors

enum DocumentError: Error {
    case encodingError
    case readError
    case writeError
}
