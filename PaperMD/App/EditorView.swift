//
//  EditorView.swift
//  PaperMD
//
//  The main editor view containing the text editor and outline sidebar.
//

import Cocoa

class EditorView: NSView {

    // Reference to the document
    weak var document: Document?

    // The split view
    private var splitView: NSSplitView!

    // The outline sidebar
    private var outlineView: OutlineView!

    // The scroll view
    private var scrollView: NSScrollView!

    // The text view (public for Document to access)
    let textView: NSTextView

    // Custom text storage for Markdown formatting
    private let textStorage: NSTextStorage

    override init(frame frameRect: NSRect) {
        // Create custom text storage
        textStorage = NSTextStorage()

        // Create layout manager
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        // Create text container
        let textContainer = NSTextContainer(containerSize: NSSize(width: frameRect.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        // Create text view with custom text storage
        textView = NSTextView(frame: NSRect(x: 0, y: 0, width: frameRect.width, height: frameRect.height), textContainer: textContainer)

        super.init(frame: frameRect)

        // Set up the view
        setupView()

        // Apply initial formatting
        applyMarkdownFormatting()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Create split view
        splitView = NSSplitView(frame: bounds)
        splitView.dividerStyle = .thin
        splitView.isVertical = true
        splitView.autoresizingMask = [.width, .height]

        // Create outline sidebar
        let outlineFrame = NSRect(x: 0, y: 0, width: 200, height: bounds.height)
        outlineView = OutlineView(frame: outlineFrame)

        // Set up heading click handler
        outlineView.onHeadingSelected = { [weak self] (lineNumber: Int) in
            self?.scrollToLine(lineNumber)
        }

        // Note: document will be set by makeWindowControllers in Document.swift

        // Create scroll view for text
        scrollView = NSScrollView(frame: NSRect(x: 200, y: 0, width: bounds.width - 200, height: bounds.height))
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

        // Add views to split view
        splitView.addArrangedSubview(outlineView)
        splitView.addArrangedSubview(scrollView)

        // Set sidebar width
        splitView.setPosition(200, ofDividerAt: 0)

        // Add to view
        addSubview(splitView)

        // Listen for text changes to mark document as edited and apply formatting
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

        // Apply Markdown formatting (deferred to avoid blocking input)
        applyMarkdownFormatting()

        // Update outline
        updateOutline()
    }

    private func applyMarkdownFormatting() {
        // Guard against empty text
        guard textView.string.count > 0 else { return }

        // Get the edited range from the notification
        let editedRange = textView.selectedRange

        // Apply formatting asynchronously to avoid blocking input
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let storage = self.textView.textStorage else { return }
            MarkdownFormatter.applyFormatting(to: storage, editedRange: editedRange)
        }
    }

    private func updateOutline() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let storage = self.textView.textStorage else { return }
            self.outlineView.updateOutline(from: storage)
        }
    }

    private func scrollToLine(_ lineNumber: Int) {
        let text = textView.string
        let lines = text.components(separatedBy: .newlines)

        guard lineNumber >= 0, lineNumber < lines.count else { return }

        // Calculate character position of the line
        var charIndex = 0
        for i in 0..<lineNumber {
            charIndex += lines[i].utf16.count + 1 // +1 for newline
        }

        // Set the cursor to the line
        let length = lines[lineNumber].utf16.count
        guard charIndex < text.count else { return }

        let range = NSRange(location: charIndex, length: length)
        textView.setSelectedRange(range)
        textView.scrollRangeToVisible(range)

        // Flash the selection to show where we jumped
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.textView.setSelectedRange(NSRange(location: charIndex, length: 0))
        }
    }
}
