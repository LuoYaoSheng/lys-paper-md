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

        // Create and add window controller
        let windowController = WindowController(window: window)
        self.addWindowController(windowController)

        // Show window and set first responder
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(editorView.textView)
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
}

// MARK: - Errors

enum DocumentError: Error {
    case encodingError
    case readError
    case writeError
}
