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

    // Container view for split view and status bar
    private var containerView: NSView!

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
        textStorage.addLayoutManager(layoutManager)

        // Create text container
        let textContainer = NSTextContainer(containerSize: NSSize(width: frameRect.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        // Create text view with custom text storage
        textView = MarkdownTextView(frame: NSRect(x: 0, y: 0, width: frameRect.width, height: frameRect.height), textContainer: textContainer)

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
        // Create container view
        containerView = NSView(frame: bounds)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // Create split view
        splitView = NSSplitView()
        splitView.dividerStyle = .thin
        splitView.isVertical = true
        splitView.translatesAutoresizingMaskIntoConstraints = false

        // Create outline sidebar
        outlineView = OutlineView()
        outlineView.translatesAutoresizingMaskIntoConstraints = false

        // Set up heading click handler
        outlineView.onHeadingSelected = { [weak self] (lineNumber: Int) in
            self?.scrollToLine(lineNumber)
        }

        // Note: document will be set by makeWindowControllers in Document.swift

        // Create scroll view for text
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

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

        // Create status bar
        statusBar = StatusBar()
        statusBar.translatesAutoresizingMaskIntoConstraints = false

        // Add split view and status bar to container
        containerView.addSubview(splitView)
        containerView.addSubview(statusBar)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Container fills the view
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Split view fills container except status bar
            splitView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: containerView.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: statusBar.topAnchor),

            // Status bar at bottom
            statusBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 28)
        ])

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

        // Update status bar stats
        updateStatusBar()
    }

    private func updateStatusBar() {
        let text = textView.string
        let stats = DocumentStats(text: text)
        statusBar.stats = stats
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
}
