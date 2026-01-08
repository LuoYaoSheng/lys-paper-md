//
//  Document.swift
//  PaperMD
//
//  NSDocument subclass for Markdown documents.
//

import Cocoa

class Document: NSDocument {

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
        window.title = "Untitled"

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

        // Set up window controller
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)

        // Show window
        window.makeKeyAndOrderFront(nil)

        // Make text view first responder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.makeFirstResponder(editorView.textView)
        }
    }

    override func data(ofType typeName: String) throws -> Data {
        // Get current text from text view
        if let textView = textView {
            rawText = textView.string
        }
        NSLog("PaperMD: data(ofType:) called, fileURL: \(String(describing: fileURL)), returning \(rawText.count) characters")
        return rawText.data(using: .utf8) ?? Data()
    }

    override func read(from data: Data, ofType typeName: String) throws {
        rawText = String(data: data, encoding: .utf8) ?? ""
        NSLog("PaperMD: read(from:) called, read \(rawText.count) characters")
    }

    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        NSLog("PaperMD: prepareSavePanel called")
        // Set default file extension to .md
        savePanel.allowedFileTypes = ["md"]
        savePanel.allowsOtherFileTypes = true
        savePanel.canCreateDirectories = true

        // Set the default filename with .md extension
        if displayName.isEmpty || displayName == "Untitled" {
            savePanel.nameFieldStringValue = "untitled.md"
        } else {
            // Ensure current name has .md extension
            if !displayName.hasSuffix(".md") {
                savePanel.nameFieldStringValue = displayName + ".md"
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
