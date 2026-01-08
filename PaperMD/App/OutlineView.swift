//
//  OutlineView.swift
//  PaperMD
//
//  Sidebar showing document structure (headings).
//

import Cocoa

class OutlineView: NSView {

    // MARK: - Properties

    private var scrollView: NSScrollView!
    private var outlineTable: NSTableView!
    private var headings: [Heading] = []

    // Callback when a heading is selected
    var onHeadingSelected: ((Int) -> Void)?

    weak var document: DocumentTextProvider? {
        didSet {
            if document != nil {
                reloadOutline()
            }
        }
    }

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // Create scroll view
        scrollView = NSScrollView(frame: bounds)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .noBorder

        // Create table view
        outlineTable = NSTableView(frame: bounds)
        outlineTable.style = .plain
        outlineTable.headerView = nil
        outlineTable.usesAlternatingRowBackgroundColors = false
        outlineTable.intercellSpacing = NSSize(width: 0, height: 4)
        outlineTable.selectionHighlightStyle = .regular
        outlineTable.allowsEmptySelection = true
        outlineTable.allowsMultipleSelection = false
        outlineTable.delegate = self
        outlineTable.dataSource = self
        outlineTable.target = self
        outlineTable.doubleAction = #selector(tableRowDoubleClicked(_:))

        // Create column
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("OutlineColumn"))
        column.title = ""
        column.width = bounds.width
        outlineTable.addTableColumn(column)

        scrollView.documentView = outlineTable
        addSubview(scrollView)
    }

    // MARK: - Public Methods

    func reloadOutline() {
        guard let doc = document else {
            headings = []
            outlineTable.reloadData()
            return
        }

        let text = doc.getText()
        headings = parseHeadings(from: text)
        outlineTable.reloadData()
    }

    func updateOutline(from textStorage: NSTextStorage) {
        let text = textStorage.string
        headings = parseHeadings(from: text)
        outlineTable.reloadData()
    }

    // MARK: - Actions

    @objc private func tableRowDoubleClicked(_ sender: NSTableView) {
        let clickedRow = sender.clickedRow
        guard clickedRow >= 0, clickedRow < headings.count else { return }

        let heading = headings[clickedRow]
        onHeadingSelected?(heading.lineNumber)
    }

    // MARK: - Private Methods

    private func parseHeadings(from text: String) -> [Heading] {
        var result: [Heading] = []
        let lines = text.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                var level = 0
                for char in trimmed {
                    if char == "#" {
                        level += 1
                    } else {
                        break
                    }
                }

                // Get heading text (remove # markers)
                let headingText = trimmed.dropFirst(level).trimmingCharacters(in: .whitespaces)

                if !headingText.isEmpty {
                    let heading = Heading(
                        level: min(level, 6),
                        title: String(headingText),
                        lineNumber: index
                    )
                    result.append(heading)
                }
            }
        }

        return result
    }
}

// MARK: - NSTableViewDataSource

extension OutlineView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return headings.count
    }
}

// MARK: - NSTableViewDelegate

extension OutlineView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < headings.count else { return nil }

        let heading = headings[row]
        // Use unique identifier per heading level for proper cell reuse
        let cellId = NSUserInterfaceItemIdentifier("OutlineCell-Level\(heading.level)")

        var cell = tableView.makeView(withIdentifier: cellId, owner: nil) as? NSTableCellView
        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = cellId

            let textField = NSTextField(labelWithString: "")
            textField.isEditable = false
            textField.isSelectable = false
            textField.drawsBackground = false
            textField.lineBreakMode = .byTruncatingTail
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField

            // Calculate indentation for this level
            let indent = CGFloat(heading.level - 1) * 16

            // Add constraints with proper indentation
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4 + indent),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }

        if let textField = cell?.textField {
            textField.stringValue = heading.title
            textField.font = headingFont(for: heading.level)
        }

        return cell
    }

    private func headingFont(for level: Int) -> NSFont {
        switch level {
        case 1:
            return NSFont.boldSystemFont(ofSize: 14)
        case 2:
            return NSFont.boldSystemFont(ofSize: 13)
        default:
            return NSFont.systemFont(ofSize: 13)
        }
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        guard row >= 0, row < headings.count else { return false }

        let heading = headings[row]
        onHeadingSelected?(heading.lineNumber)
        return true
    }
}

// MARK: - Heading Model

struct Heading {
    let level: Int
    let title: String
    let lineNumber: Int
}
