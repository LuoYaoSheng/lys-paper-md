//
//  WindowController.swift
//  PaperMD
//
//  Custom window controller for document windows.
//

import Cocoa

class WindowController: NSWindowController {

    private var toolbar: NSToolbar?

    override func windowDidLoad() {
        super.windowDidLoad()
        setupToolbar()
    }

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: NSToolbar.Identifier("PaperMDToolbar"))
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconOnly

        self.toolbar = toolbar
        window?.toolbar = toolbar
    }

    // MARK: - Toolbar Actions

    @objc private func toggleSidebar(_ sender: Any?) {
        // Toggle sidebar by sending notification
        NotificationCenter.default.post(name: .toggleSidebar, object: nil)
    }

    @objc private func togglePreview(_ sender: Any?) {
        // Future: Add HTML preview toggle
        NSLog("PaperMD: Toggle preview clicked")
    }
}

// MARK: - NSToolbarDelegate

extension WindowController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)

        switch itemIdentifier {
        case .toggleSidebar:
            toolbarItem.label = "Sidebar"
            toolbarItem.paletteLabel = "Toggle Sidebar"
            toolbarItem.toolTip = "Toggle Outline Sidebar"
            toolbarItem.target = self
            toolbarItem.action = #selector(toggleSidebar(_:))
            if let image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Sidebar") {
                toolbarItem.image = image
            }

        case .separator:
            return NSToolbarItem(itemIdentifier: .separator)

        case .flexibleSpace:
            return NSToolbarItem(itemIdentifier: .flexibleSpace)

        case .bold:
            toolbarItem.label = "Bold"
            toolbarItem.paletteLabel = "Bold"
            toolbarItem.toolTip = "Bold (⌘B)"
            toolbarItem.target = self
            toolbarItem.action = #selector(applyBold(_:))
            if let image = NSImage(systemSymbolName: "bold", accessibilityDescription: "Bold") {
                toolbarItem.image = image
            }

        case .italic:
            toolbarItem.label = "Italic"
            toolbarItem.paletteLabel = "Italic"
            toolbarItem.toolTip = "Italic (⌘I)"
            toolbarItem.target = self
            toolbarItem.action = #selector(applyItalic(_:))
            if let image = NSImage(systemSymbolName: "italic", accessibilityDescription: "Italic") {
                toolbarItem.image = image
            }

        case .code:
            toolbarItem.label = "Code"
            toolbarItem.paletteLabel = "Code"
            toolbarItem.toolTip = "Inline Code"
            toolbarItem.target = self
            toolbarItem.action = #selector(applyCode(_:))
            if let image = NSImage(systemSymbolName: "chevron.left.forwardslash.chevron.right", accessibilityDescription: "Code") {
                toolbarItem.image = image
            }

        default:
            return nil
        }

        return toolbarItem
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .toggleSidebar,
            .separator,
            .flexibleSpace,
            .bold,
            .italic,
            .code
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .toggleSidebar,
            .separator,
            .flexibleSpace,
            .bold,
            .italic,
            .code
        ]
    }

    // MARK: - Formatting Actions

    @objc private func applyBold(_ sender: Any?) {
        insertMarkdownAroundSelection(prefix: "**", suffix: "**")
    }

    @objc private func applyItalic(_ sender: Any?) {
        insertMarkdownAroundSelection(prefix: "*", suffix: "*")
    }

    @objc private func applyCode(_ sender: Any?) {
        insertMarkdownAroundSelection(prefix: "`", suffix: "`")
    }

    private func insertMarkdownAroundSelection(prefix: String, suffix: String) {
        guard let window = window,
              let editorView = window.contentView?.subviews.first?.subviews.first?.subviews.first as? EditorView else {
            return
        }

        let textView = editorView.textView
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
}

// MARK: - NSToolbarItem.Identifier Extensions

extension NSToolbarItem.Identifier {
    static let toggleSidebar = NSToolbarItem.Identifier("ToggleSidebar")
    static let separator = NSToolbarItem.Identifier("Separator")
    static let flexibleSpace = NSToolbarItem.Identifier("FlexibleSpace")
    static let bold = NSToolbarItem.Identifier("Bold")
    static let italic = NSToolbarItem.Identifier("Italic")
    static let code = NSToolbarItem.Identifier("Code")
}

// MARK: - Notification.Name

extension Notification.Name {
    static let toggleSidebar = Notification.Name("ToggleSidebar")
}
