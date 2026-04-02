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

    // Focus mode callback
    var onFocusModeChanged: ((Bool) -> Void)?

    // Focus mode state
    private var isFocusMode: Bool = false {
        didSet {
            onFocusModeChanged?(isFocusMode)
            statusBar?.isHidden = isFocusMode
        }
    }

    // The split view
    private var splitView: NSSplitView!

    // The outline sidebar
    private var outlineView: OutlineView!

    // The scroll view
    private var scrollView: NSScrollView!

    // Status bar
    private var statusBar: StatusBar!

    // The text view (public for Document to access)
    let textView: MarkdownTextView

    // Custom text storage for Markdown formatting
    private let textStorage: NSTextStorage

    override init(frame frameRect: NSRect) {
        // Create custom text storage
        textStorage = NSTextStorage()

        // Create layout manager
        let layoutManager = NSLayoutManager()
        layoutManager.usesFontLeading = false
        textStorage.addLayoutManager(layoutManager)

        // Calculate content width (excluding sidebar)
        let contentWidth = frameRect.width - 200

        // Create text container with proper size
        let textContainer = NSTextContainer(containerSize: NSSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)

        // Create text view with custom text storage
        textView = MarkdownTextView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: frameRect.height), textContainer: textContainer)

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
        // Create split view with frame
        splitView = NSSplitView(frame: bounds)
        splitView.dividerStyle = .thin
        splitView.isVertical = true
        splitView.autoresizingMask = [.width, .height]

        // Create outline sidebar with frame
        let outlineFrame = NSRect(x: 0, y: 0, width: 200, height: bounds.height)
        outlineView = OutlineView(frame: outlineFrame)

        // Set up heading click handler
        outlineView.onHeadingSelected = { [weak self] (lineNumber: Int) in
            self?.scrollToLine(lineNumber)
        }

        // Note: document will be set by makeWindowControllers in Document.swift

        // Create scroll view for text with frame
        let scrollViewFrame = NSRect(x: 200, y: 0, width: bounds.width - 200, height: bounds.height)
        scrollView = NSScrollView(frame: scrollViewFrame)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.autoresizingMask = [.width, .height]

        // Configure text view
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width

        // Calculate content width (total width minus sidebar minus status bar adjustment)
        let contentWidth = max(bounds.width - 200, 100) // Minimum 100pt width

        // Update text container size to match scroll view content area
        textView.textContainer?.containerSize = NSSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false

        textView.font = NSFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isSelectable = true
        textView.backgroundColor = .textBackgroundColor

        // IMPORTANT: Enable undo/redo by using the window's undoManager
        // This ensures typing actions are recorded for undo
        textView.undoManager?.disableUndoRegistration()
        textView.undoManager?.enableUndoRegistration()

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

        // Create status bar with frame
        let statusBarFrame = NSRect(x: 0, y: bounds.height - 28, width: bounds.width, height: 28)
        statusBar = StatusBar(frame: statusBarFrame)
        statusBar.autoresizingMask = [.width]

        // Adjust split view frame to make room for status bar
        splitView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 28)

        // Add to view
        addSubview(splitView)
        addSubview(statusBar)

        // Listen for text changes to mark document as edited and apply formatting
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange(_:)),
            name: NSText.didChangeNotification,
            object: textView
        )

        // Listen for preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged(_:)),
            name: .preferencesChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func textDidChange(_ notification: Notification) {
        // Mark document as edited whenever text changes
        document?.updateChangeCount(.changeDone)

        // Avoid rebuilding formatting while the IME composition is active.
        // This keeps marked text stable for Chinese/Japanese/Korean input.
        if textView.hasMarkedText() {
            updateStatusBar()
            return
        }

        // Apply Markdown formatting (deferred to avoid blocking input)
        applyMarkdownFormatting()

        // Update outline
        updateOutline()

        // Update status bar stats
        updateStatusBar()
    }

    @objc private func preferencesChanged(_ notification: Notification) {
        // Update font size in formatter
        MarkdownFormatter.setFontSize(Preferences.shared.fontSize)

        // Update text view font
        textView.font = NSFont.systemFont(ofSize: CGFloat(Preferences.shared.fontSize))

        // Reapply formatting
        applyMarkdownFormatting()
    }

    private func updateStatusBar() {
        let text = textView.string
        let stats = DocumentStats(text: text)
        statusBar.stats = stats
    }

    // MARK: - Public Methods

    func reapplyFormatting() {
        // Apply formatting to entire document
        guard let storage = textView.textStorage, textView.string.count > 0 else { return }
        let fullRange = NSRange(location: 0, length: textView.string.count)
        MarkdownFormatter.applyFormatting(to: storage, editedRange: fullRange)

        // Update outline
        updateOutline()

        // Update status bar
        updateStatusBar()
    }

    private func applyMarkdownFormatting() {
        // Guard against empty text
        guard textView.string.count > 0 else { return }
        guard !textView.hasMarkedText() else { return }

        // Get the edited range from the notification
        let editedRange = textView.selectedRange

        // Apply formatting asynchronously to avoid blocking input
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let storage = self.textView.textStorage else { return }
            guard !self.textView.hasMarkedText() else { return }
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

    // MARK: - Focus Mode

    func toggleFocusMode() {
        isFocusMode.toggle()
        updateFocusMode()
    }

    private func updateFocusMode() {
        // Animate sidebar collapse/expand
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true

            if isFocusMode {
                // Hide sidebar by collapsing to zero width
                splitView.setPosition(0, ofDividerAt: 0)
                outlineView.isHidden = true
            } else {
                // Show sidebar by restoring to 200px
                outlineView.isHidden = false
                splitView.setPosition(200, ofDividerAt: 0)
            }
        }
    }

    // MARK: - Sidebar Toggle

    func toggleSidebar() {
        // Toggle sidebar visibility
        let isCollapsed = splitView.isSubviewCollapsed(outlineView)
        if isCollapsed {
            outlineView.isHidden = false
            splitView.setPosition(200, ofDividerAt: 0)
        } else {
            splitView.setPosition(0, ofDividerAt: 0)
            outlineView.isHidden = true
        }
    }

    // MARK: - Responder Chain

    override var acceptsFirstResponder: Bool {
        return true
    }
}
