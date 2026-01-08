//
//  MenuActions.swift
//  PaperMD
//
//  Helper to set up menu actions programmatically.
//

import Cocoa

class MenuActions {

    static func setupMainMenu() {
        guard let mainMenu = NSApp.mainMenu else { return }

        // Find Format menu and connect actions
        for menuItem in mainMenu.items {
            guard let submenu = menuItem.submenu else { continue }

            if submenu.title == "Format" {
                setupFormatMenu(submenu)
            } else if submenu.title == "View" {
                setupViewMenu(submenu)
            }
        }
    }

    private static func setupFormatMenu(_ menu: NSMenu) {
        for item in menu.items {
            switch item.title {
            case "Bold":
                item.action = #selector(performBold(_:))
                item.target = nil  // Let responder chain handle it
            case "Italic":
                item.action = #selector(performItalic(_:))
                item.target = nil
            case "Code":
                item.action = #selector(performCode(_:))
                item.target = nil
            case "Heading 1":
                item.action = #selector(performHeading1(_:))
                item.target = nil
            case "Heading 2":
                item.action = #selector(performHeading2(_:))
                item.target = nil
            case "Heading 3":
                item.action = #selector(performHeading3(_:))
                item.target = nil
            default:
                break
            }
        }
    }

    private static func setupViewMenu(_ menu: NSMenu) {
        for item in menu.items {
            switch item.title {
            case "Toggle Sidebar":
                item.action = #selector(performToggleSidebar(_:))
                item.target = nil
            case "Toggle Focus Mode":
                item.action = #selector(performToggleFocusMode(_:))
                item.target = nil
            default:
                break
            }
        }
    }

    // MARK: - Action Methods

    @objc static func performBold(_ sender: Any?) {
        applyFormatting { textView in
            insertMarkdown(textView: textView, prefix: "**", suffix: "**")
        }
    }

    @objc static func performItalic(_ sender: Any?) {
        applyFormatting { textView in
            insertMarkdown(textView: textView, prefix: "*", suffix: "*")
        }
    }

    @objc static func performCode(_ sender: Any?) {
        applyFormatting { textView in
            insertMarkdown(textView: textView, prefix: "`", suffix: "`")
        }
    }

    @objc static func performHeading1(_ sender: Any?) {
        applyHeading(prefix: "# ")
    }

    @objc static func performHeading2(_ sender: Any?) {
        applyHeading(prefix: "## ")
    }

    @objc static func performHeading3(_ sender: Any?) {
        applyHeading(prefix: "### ")
    }

    @objc static func performToggleSidebar(_ sender: Any?) {
        NotificationCenter.default.post(name: Notification.Name("ToggleSidebarFromMenu"), object: sender)
    }

    @objc static func performToggleFocusMode(_ sender: Any?) {
        NotificationCenter.default.post(name: Notification.Name("ToggleFocusModeFromMenu"), object: sender)
    }

    // MARK: - Helper Methods

    private static func applyFormatting(_ block: (NSTextView) -> Void) {
        guard let textView = getCurrentTextView() else { return }
        block(textView)
    }

    private static func applyHeading(prefix: String) {
        guard let textView = getCurrentTextView() else { return }

        let text = textView.string as NSString
        let selectedRange = textView.selectedRange
        let lineStart = text.lineRange(for: selectedRange).location
        let lineRange = text.lineRange(for: NSRange(location: lineStart, length: 0))
        let line = text.substring(with: lineRange)

        // Remove existing heading markers
        var trimmedLine = line
        while trimmedLine.hasPrefix("#") {
            trimmedLine = String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespaces)
        }

        let newLine = "\(prefix)\(trimmedLine)"
        textView.replaceCharacters(in: lineRange, with: newLine)

        let newCursorPos = lineStart + prefix.count
        textView.setSelectedRange(NSRange(location: newCursorPos, length: 0))
    }

    private static func insertMarkdown(textView: NSTextView, prefix: String, suffix: String) {
        let selectedRange = textView.selectedRange
        guard selectedRange.length > 0 else { return }

        let text = textView.string
        let selectedText = (text as NSString).substring(with: selectedRange)
        let formattedText = "\(prefix)\(selectedText)\(suffix)"

        textView.replaceCharacters(in: selectedRange, with: formattedText)
        let newRange = NSRange(location: selectedRange.location, length: formattedText.count)
        textView.setSelectedRange(newRange)
    }

    private static func getCurrentTextView() -> NSTextView? {
        // Try to get the text view from the current document
        if let document = NSDocumentController.shared.currentDocument {
            // Use reflection to get textView property to avoid circular dependency
            let mirror = Mirror(reflecting: document)
            for child in mirror.children {
                if child.label == "textView", let textView = child.value as? NSTextView {
                    return textView
                }
            }
        }
        return nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let toggleSidebarFromMenu = Notification.Name("ToggleSidebarFromMenu")
    static let toggleFocusModeFromMenu = Notification.Name("ToggleFocusModeFromMenu")
}
