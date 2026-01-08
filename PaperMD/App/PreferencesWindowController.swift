//
//  PreferencesWindowController.swift
//  PaperMD
//
//  Preferences/Settings window controller.
//

import Cocoa

class PreferencesWindowController: NSWindowController {

    private var preferencesView: PreferencesView!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)

        // Create and set preferences view
        let preferencesView = PreferencesView(frame: window.contentView!.bounds)
        window.contentView = preferencesView
        self.preferencesView = preferencesView
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Preferences View

class PreferencesView: NSView {

    private var fontSizePopUpButton: NSPopUpButton!
    private var themePopUpButton: NSPopUpButton!
    private var autosaveCheckbox: NSButton!

    private var preferences = Preferences.shared

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        loadPreferences()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        loadPreferences()
    }

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Create stack view for vertical layout
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 16
        stackView.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading

        // Font size section
        let fontSizeSection = createSection(
            title: "Editor Font Size",
            control: createFontSizeControl()
        )
        stackView.addArrangedSubview(fontSizeSection)

        // Theme section
        let themeSection = createSection(
            title: "Appearance",
            control: createThemeControl()
        )
        stackView.addArrangedSubview(themeSection)

        // General section with autosave
        let generalSection = createSection(
            title: "General",
            control: createAutosaveControl()
        )
        stackView.addArrangedSubview(generalSection)

        addSubview(stackView)

        // Constrain stack view
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }

    private func createSection(title: String, control: NSView) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.textColor = .labelColor
        container.addArrangedSubview(titleLabel)

        container.addArrangedSubview(control)

        return container
    }

    private func createFontSizeControl() -> NSView {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 12
        stackView.alignment = .firstBaseline

        let label = NSTextField(labelWithString: "Font size:")
        label.isEditable = false
        label.isSelectable = false
        stackView.addArrangedSubview(label)

        fontSizePopUpButton = NSPopUpButton()
        fontSizePopUpButton.target = self
        fontSizePopUpButton.action = #selector(fontSizeChanged(_:))

        let sizes = [12, 13, 14, 15, 16, 17, 18, 20, 22, 24]
        for size in sizes {
            fontSizePopUpButton.addItem(withTitle: "\(size) pt")
            fontSizePopUpButton.lastItem?.representedObject = size
        }

        stackView.addArrangedSubview(fontSizePopUpButton)

        return stackView
    }

    private func createThemeControl() -> NSView {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 12
        stackView.alignment = .firstBaseline

        let label = NSTextField(labelWithString: "Theme:")
        label.isEditable = false
        label.isSelectable = false
        stackView.addArrangedSubview(label)

        themePopUpButton = NSPopUpButton()
        themePopUpButton.target = self
        themePopUpButton.action = #selector(themeChanged(_:))

        themePopUpButton.addItem(withTitle: "Light")
        themePopUpButton.lastItem?.representedObject = Theme.light

        themePopUpButton.addItem(withTitle: "Dark")
        themePopUpButton.lastItem?.representedObject = Theme.dark

        themePopUpButton.addItem(withTitle: "System")
        themePopUpButton.lastItem?.representedObject = Theme.system

        stackView.addArrangedSubview(themePopUpButton)

        return stackView
    }

    private func createAutosaveControl() -> NSView {
        autosaveCheckbox = NSButton(checkboxWithTitle: "Automatically save documents", target: self, action: #selector(autosaveChanged(_:)))
        autosaveCheckbox.state = preferences.autosaveEnabled ? .on : .off
        return autosaveCheckbox
    }

    private func loadPreferences() {
        // Load font size
        let fontSize = preferences.fontSize
        for item in fontSizePopUpButton.menu!.items {
            if let size = item.representedObject as? Int, size == fontSize {
                fontSizePopUpButton.select(item)
                break
            }
        }

        // Load theme
        let theme = preferences.theme
        for item in themePopUpButton.menu!.items {
            if let itemTheme = item.representedObject as? Theme, itemTheme == theme {
                themePopUpButton.select(item)
                break
            }
        }

        // Load autosave
        autosaveCheckbox.state = preferences.autosaveEnabled ? .on : .off
    }

    @objc private func fontSizeChanged(_ sender: NSPopUpButton) {
        if let selectedItem = sender.selectedItem,
           let fontSize = selectedItem.representedObject as? Int {
            preferences.fontSize = fontSize
            preferences.apply()
        }
    }

    @objc private func themeChanged(_ sender: NSPopUpButton) {
        if let selectedItem = sender.selectedItem,
           let theme = selectedItem.representedObject as? Theme {
            preferences.theme = theme
            preferences.apply()
        }
    }

    @objc private func autosaveChanged(_ sender: NSButton) {
        preferences.autosaveEnabled = (sender.state == .on)
        preferences.apply()
    }
}

// MARK: - Preferences Model

enum Theme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

class Preferences {

    static let shared = Preferences()

    private let fontSizeKey = "editorFontSize"
    private let themeKey = "appTheme"
    private let autosaveEnabledKey = "autosaveEnabled"

    var fontSize: Int {
        get {
            UserDefaults.standard.integer(forKey: fontSizeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: fontSizeKey)
        }
    }

    var theme: Theme {
        get {
            let rawValue = UserDefaults.standard.string(forKey: themeKey) ?? Theme.system.rawValue
            return Theme(rawValue: rawValue) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: themeKey)
        }
    }

    var autosaveEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: autosaveEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autosaveEnabledKey)
        }
    }

    private init() {
        // Set defaults
        if UserDefaults.standard.object(forKey: fontSizeKey) == nil {
            fontSize = 16
        }
        // Set default for autosave (enabled by default)
        if UserDefaults.standard.object(forKey: autosaveEnabledKey) == nil {
            autosaveEnabled = true
        }
    }

    func apply() {
        // Apply theme
        applyTheme(theme)

        // Post notification for other parts of app to update
        NotificationCenter.default.post(name: .preferencesChanged, object: self)
    }

    private func applyTheme(_ theme: Theme) {
        let appearance: NSAppearance?

        switch theme {
        case .light:
            appearance = NSAppearance(named: .aqua)
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        case .system:
            // Reset to system default
            appearance = nil
        }

        NSApp.appearance = appearance
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let preferencesChanged = Notification.Name("PreferencesChanged")
}
