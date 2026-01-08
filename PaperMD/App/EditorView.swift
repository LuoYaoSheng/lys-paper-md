//
//  EditorView.swift
//  PaperMD
//
//  The main editor view containing the text editor.
//

import Cocoa

class EditorView: NSView {

    // Reference to the document
    weak var document: Document?

    // The scroll view
    private var scrollView: NSScrollView!

    // The text view (public for Document to access)
    let textView: NSTextView

    override init(frame frameRect: NSRect) {
        // Create text view first
        textView = NSTextView(frame: NSRect(x: 0, y: 0, width: frameRect.width, height: frameRect.height))

        super.init(frame: frameRect)

        // Set up the view
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Create scroll view
        scrollView = NSScrollView(frame: bounds)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .noBorder

        // Configure text view
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.textContainer?.containerSize = NSSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.font = NSFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isSelectable = true

        // Disable automatic substitutions for Markdown editing
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false

        // Connect scroll view and text view
        scrollView.documentView = textView

        // Add to view
        addSubview(scrollView)

        // Listen for text changes to mark document as edited
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange(_:)),
            name: NSText.didChangeNotification,
            object: textView
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func textDidChange(_ notification: Notification) {
        // Mark document as edited whenever text changes
        document?.updateChangeCount(.changeDone)
    }
}
