//
//  AppDelegate.swift
//  PaperMD
//
//  A native macOS Markdown editor focused on ultimate input experience.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("PaperMD: Application did finish launching")

        // Fix menu structure - storyboard menus aren't properly connected
        fixMenuStructure()

        // Check if there are already any documents (e.g., from window restoration)
        let documentController = NSDocumentController.shared
        if documentController.documents.isEmpty {
            // Only create a new document if none exist
            NSLog("PaperMD: Creating new document...")
            documentController.newDocument(nil)
        } else {
            NSLog("PaperMD: \(documentController.documents.count) document(s) already exist")
        }
    }

    private func fixMenuStructure() {
        // The storyboard menus have structure issues. We need to rebuild
        // the entire menu structure programmatically.

        // Create a fresh main menu
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu

        // MARK: - App Menu
        let appMenuItem = NSMenuItem()
        appMenuItem.title = "PaperMD"
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "About PaperMD", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        // Preferences menu item - action to be implemented
        let prefsItem = appMenu.addItem(withTitle: "Preferences…", action: nil, keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide PaperMD", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthersItem = appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit PaperMD", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        mainMenu.addItem(appMenuItem)

        // MARK: - File Menu
        let fileMenuItem = NSMenuItem()
        fileMenuItem.title = "File"
        let fileMenu = NSMenu()
        fileMenuItem.submenu = fileMenu

        fileMenu.addItem(withTitle: "New", action: #selector(NSDocumentController.newDocument(_:)), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open…", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        let saveItem = fileMenu.addItem(withTitle: "Save", action: #selector(WindowController.saveDocument(_:)), keyEquivalent: "s")
        saveItem.target = nil  // Let responder chain handle it
        let saveAsItem = fileMenu.addItem(withTitle: "Save As…", action: #selector(WindowController.saveDocumentAs(_:)), keyEquivalent: "S")
        saveAsItem.target = nil

        mainMenu.addItem(fileMenuItem)

        // MARK: - Edit Menu
        let editMenuItem = NSMenuItem()
        editMenuItem.title = "Edit"
        let editMenu = NSMenu()
        editMenuItem.submenu = editMenu

        // Undo/Redo - use responder chain actions
        // NSTextView responds to undo:/redo: via its undoManager
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSTextView.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSTextView.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSTextView.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSTextView.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(NSMenuItem.separator())

        // Find and Replace
        editMenu.addItem(withTitle: "Find…", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "f")
        editMenu.addItem(withTitle: "Find Next", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "g")
        editMenu.addItem(withTitle: "Find Previous", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "G")
        editMenu.addItem(withTitle: "Replace", action: #selector(NSTextView.performFindPanelAction(_:)), keyEquivalent: "")
        let replaceItem = editMenu.item(withTitle: "Replace")
        replaceItem?.keyEquivalent = "f"
        replaceItem?.keyEquivalentModifierMask = [.command, .option]
        editMenu.addItem(NSMenuItem.separator())

        // Spelling
        editMenu.addItem(withTitle: "Show Spelling and Grammar", action: #selector(NSTextView.showGuessPanel(_:)), keyEquivalent: ":")
        editMenu.addItem(withTitle: "Check Document Now", action: #selector(NSTextView.checkSpelling(_:)), keyEquivalent: ";")
        editMenu.addItem(NSMenuItem.separator())

        // Transformations submenu
        let transformationsItem = NSMenuItem()
        transformationsItem.title = "Transformations"
        let transformationsMenu = NSMenu()
        transformationsItem.submenu = transformationsMenu

        transformationsMenu.addItem(withTitle: "Make Upper Case", action: #selector(NSTextView.uppercaseWord(_:)), keyEquivalent: "")
        let upperItem = transformationsMenu.item(withTitle: "Make Upper Case")
        upperItem?.keyEquivalent = "u"
        upperItem?.keyEquivalentModifierMask = [.command, .control]

        transformationsMenu.addItem(withTitle: "Make Lower Case", action: #selector(NSTextView.lowercaseWord(_:)), keyEquivalent: "")
        let lowerItem = transformationsMenu.item(withTitle: "Make Lower Case")
        lowerItem?.keyEquivalent = "l"
        lowerItem?.keyEquivalentModifierMask = [.command, .control]

        transformationsMenu.addItem(withTitle: "Capitalize", action: #selector(NSTextView.capitalizeWord(_:)), keyEquivalent: "")
        let capItem = transformationsMenu.item(withTitle: "Capitalize")
        capItem?.keyEquivalent = "c"
        capItem?.keyEquivalentModifierMask = [.command, .option]

        editMenu.addItem(transformationsItem)
        editMenu.addItem(NSMenuItem.separator())

        // Navigation
        editMenu.addItem(withTitle: "Jump to Selection", action: #selector(NSTextView.centerSelectionInVisibleArea(_:)), keyEquivalent: "j")

        mainMenu.addItem(editMenuItem)

        // MARK: - View Menu
        let viewMenuItem = NSMenuItem()
        viewMenuItem.title = "View"
        let viewMenu = NSMenu()
        viewMenuItem.submenu = viewMenu

        viewMenu.addItem(withTitle: "Toggle Sidebar", action: #selector(WindowController.toggleSidebar(_:)), keyEquivalent: "o")
        let sidebarItem = viewMenu.item(withTitle: "Toggle Sidebar")
        sidebarItem?.keyEquivalentModifierMask = [.control, .command]  // Ctrl+⌘+O
        viewMenu.addItem(withTitle: "Toggle Focus Mode", action: #selector(WindowController.toggleFocusMode(_:)), keyEquivalent: "f")
        viewMenu.addItem(NSMenuItem.separator())
        // Center selection in visible area - useful for navigation
        viewMenu.addItem(withTitle: "Center Selection", action: #selector(NSTextView.centerSelectionInVisibleArea(_:)), keyEquivalent: "j")

        mainMenu.addItem(viewMenuItem)

        // MARK: - Format Menu
        let formatMenuItem = NSMenuItem()
        formatMenuItem.title = "Format"
        let formatMenu = NSMenu()
        formatMenuItem.submenu = formatMenu

        // Inline formatting
        let boldItem = formatMenu.addItem(withTitle: "Bold", action: #selector(WindowController.applyBold(_:)), keyEquivalent: "b")
        boldItem.target = nil
        let italicItem = formatMenu.addItem(withTitle: "Italic", action: #selector(WindowController.applyItalic(_:)), keyEquivalent: "i")
        italicItem.target = nil
        let codeItem = formatMenu.addItem(withTitle: "Code", action: #selector(WindowController.applyCode(_:)), keyEquivalent: "k")
        codeItem.target = nil

        // Strikethrough
        let strikeItem = formatMenu.addItem(withTitle: "Strikethrough", action: #selector(WindowController.applyStrikethrough(_:)), keyEquivalent: "")
        strikeItem.keyEquivalent = "s"
        strikeItem.keyEquivalentModifierMask = [.command, .option]
        strikeItem.target = nil

        formatMenu.addItem(NSMenuItem.separator())

        // Headings
        let h1Item = formatMenu.addItem(withTitle: "Heading 1", action: #selector(WindowController.applyHeading1(_:)), keyEquivalent: "1")
        h1Item.keyEquivalentModifierMask = [.command, .shift]
        h1Item.target = nil
        let h2Item = formatMenu.addItem(withTitle: "Heading 2", action: #selector(WindowController.applyHeading2(_:)), keyEquivalent: "2")
        h2Item.keyEquivalentModifierMask = [.command, .shift]
        h2Item.target = nil
        let h3Item = formatMenu.addItem(withTitle: "Heading 3", action: #selector(WindowController.applyHeading3(_:)), keyEquivalent: "3")
        h3Item.keyEquivalentModifierMask = [.command, .shift]
        h3Item.target = nil

        formatMenu.addItem(NSMenuItem.separator())

        // Block formatting
        let quoteItem = formatMenu.addItem(withTitle: "Blockquote", action: #selector(WindowController.applyBlockquote(_:)), keyEquivalent: "")
        quoteItem.keyEquivalent = ">"
        quoteItem.keyEquivalentModifierMask = [.command, .option]
        quoteItem.target = nil

        let codeBlockItem = formatMenu.addItem(withTitle: "Code Block", action: #selector(WindowController.applyCodeBlock(_:)), keyEquivalent: "")
        codeBlockItem.keyEquivalent = "c"
        codeBlockItem.keyEquivalentModifierMask = [.command, .option]
        codeBlockItem.target = nil

        let linkItem = formatMenu.addItem(withTitle: "Insert Link", action: #selector(WindowController.applyLink(_:)), keyEquivalent: "l")
        linkItem.keyEquivalentModifierMask = [.command, .shift]
        linkItem.target = nil

        mainMenu.addItem(formatMenuItem)

        // MARK: - Window Menu
        let windowMenuItem = NSMenuItem()
        windowMenuItem.title = "Window"
        let windowMenu = NSMenu()
        windowMenuItem.submenu = windowMenu

        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")

        mainMenu.addItem(windowMenuItem)
        NSApp.windowsMenu = windowMenu

        // MARK: - Help Menu
        let helpMenuItem = NSMenuItem()
        helpMenuItem.title = "Help"
        let helpMenu = NSMenu()
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(withTitle: "PaperMD Help", action: #selector(NSApplication.showHelp(_:)), keyEquivalent: "?")

        mainMenu.addItem(helpMenuItem)
        NSApp.helpMenu = helpMenu

        NSLog("PaperMD: Menu structure rebuilt programmatically")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // For a document-based app, this should typically be false
        // so users can create new documents after closing the last one.
        return false
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        // Let NSDocumentController handle file opening
        return true
    }
}
