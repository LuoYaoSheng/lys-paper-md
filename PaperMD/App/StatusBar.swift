//
//  StatusBar.swift
//  PaperMD
//
//  Status bar showing word count, character count, and reading time.
//

import Cocoa

class StatusBar: NSView {

    private var wordCountField: NSTextField!
    private var charCountField: NSTextField!
    private var readingTimeField: NSTextField!

    var stats: DocumentStats = .empty {
        didSet {
            updateDisplay()
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // Create stack view for horizontal layout
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Word count
        wordCountField = createStatField()
        stackView.addArrangedSubview(wordCountField)

        // Separator
        let separator1 = createSeparator()
        stackView.addArrangedSubview(separator1)

        // Character count
        charCountField = createStatField()
        stackView.addArrangedSubview(charCountField)

        // Separator
        let separator2 = createSeparator()
        stackView.addArrangedSubview(separator2)

        // Reading time
        readingTimeField = createStatField()
        stackView.addArrangedSubview(readingTimeField)

        addSubview(stackView)

        // Constrain stack view to fill the status bar
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 28)
        ])

        updateDisplay()
    }

    private func createStatField() -> NSTextField {
        let field = NSTextField(labelWithString: "")
        field.font = NSFont.systemFont(ofSize: 11)
        field.textColor = NSColor.secondaryLabelColor
        field.isEditable = false
        field.isSelectable = false
        return field
    }

    private func createSeparator() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.separatorColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }

    private func updateDisplay() {
        wordCountField.stringValue = "\(stats.wordCount) words"
        charCountField.stringValue = "\(stats.characterCount) characters"
        readingTimeField.stringValue = "\(stats.readingTime) min read"
    }
}

// MARK: - Document Stats

struct DocumentStats {
    let wordCount: Int
    let characterCount: Int
    let readingTime: Int

    static let empty = DocumentStats(wordCount: 0, characterCount: 0, readingTime: 0)

    init(wordCount: Int, characterCount: Int, readingTime: Int) {
        self.wordCount = wordCount
        self.characterCount = characterCount
        // Reading time: average 200 words per minute
        self.readingTime = max(1, wordCount / 200)
    }

    init(text: String) {
        self.characterCount = text.count

        // Count words (sequences of non-whitespace characters)
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        self.wordCount = words.count

        // Reading time: average 200 words per minute
        self.readingTime = max(1, wordCount / 200)
    }
}
