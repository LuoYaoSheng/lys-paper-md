//
//  ImageHandler.swift
//  PaperMD
//
//  Handles image paste/drag operations with local file storage.
//

import Cocoa

class ImageHandler {

    // MARK: - Public Methods

    /// Handle pasted image from clipboard
    static func handlePastedImage(in textView: NSTextView, documentURL: URL?) -> Bool {
        let pasteboard = NSPasteboard.general
        return handleImageFromPasteboard(pasteboard, in: textView, documentURL: documentURL)
    }

    /// Handle dragged image
    static func handleDroppedImage(in textView: NSTextView, at location: Int, image: NSImage, documentURL: URL?) -> Bool {
        guard let assetsURL = getAssetsFolder(for: documentURL) else {
            NSLog("PaperMD: Failed to get assets folder")
            return false
        }

        guard let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            NSLog("PaperMD: Failed to convert image to PNG")
            return false
        }

        let filename = generateFilename(for: pngData)
        let fileURL = assetsURL.appendingPathComponent(filename)

        do {
            try pngData.write(to: fileURL)
            NSLog("PaperMD: Saved image to \(fileURL.path)")

            // Get relative path from document
            let relativePath = getRelativePath(to: fileURL, from: documentURL)

            // Insert markdown at the drop location
            insertMarkdownImage(in: textView, at: location, imagePath: relativePath)

            return true
        } catch {
            NSLog("PaperMD: Failed to save image: \(error)")
            return false
        }
    }

    // MARK: - Private Methods

    private static func handleImageFromPasteboard(_ pasteboard: NSPasteboard, in textView: NSTextView, documentURL: URL?) -> Bool {
        // Check for image data directly
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            return saveAndInsertImage(data: imageData, in: textView, documentURL: documentURL)
        }

        // Check for file URLs (dragged image files)
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in fileURLs {
                if let image = NSImage(contentsOf: url) {
                    // Save the image data, not just the reference
                    if let imageData = image.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: imageData),
                       let pngData = bitmap.representation(using: .png, properties: [:]) {
                        return saveAndInsertImage(data: pngData, in: textView, documentURL: documentURL)
                    }
                }
            }
        }

        return false
    }

    private static func saveAndInsertImage(data: Data, in textView: NSTextView, documentURL: URL?) -> Bool {
        guard let assetsURL = getAssetsFolder(for: documentURL) else {
            NSLog("PaperMD: Failed to get assets folder")
            return false
        }

        let filename = generateFilename(for: data)
        let fileURL = assetsURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            NSLog("PaperMD: Saved image to \(fileURL.path)")

            // Get relative path from document
            let relativePath = getRelativePath(to: fileURL, from: documentURL)

            // Insert markdown at current selection
            let selectedRange = textView.selectedRange
            insertMarkdownImage(in: textView, at: selectedRange.location, imagePath: relativePath)

            return true
        } catch {
            NSLog("PaperMD: Failed to save image: \(error)")
            return false
        }
    }

    private static func getAssetsFolder(for documentURL: URL?) -> URL? {
        let fileManager = FileManager.default

        // Get the document URL
        guard let docURL = documentURL else {
            // No document URL yet - use temp directory
            // This will be moved when document is saved
            let tempURL = fileManager.temporaryDirectory.appendingPathComponent("PaperMD.assets")
            try? fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)
            return tempURL
        }

        // Create {filename}.assets folder next to the document
        let fileNameWithoutExt = docURL.deletingPathExtension().lastPathComponent
        let assetsURL = docURL.deletingLastPathComponent().appendingPathComponent("\(fileNameWithoutExt).assets")

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: assetsURL.path) {
            try? fileManager.createDirectory(at: assetsURL, withIntermediateDirectories: true)
        }

        return assetsURL
    }

    private static func generateFilename(for data: Data) -> String {
        // Timestamp + hash for unique filename
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let hash = data.prefix(8).reduce(0) { ($0 << 8) + Int($1) }
        return "image-\(timestamp)-\(hash).png"
    }

    private static func getRelativePath(to fileURL: URL, from documentURL: URL?) -> String {
        guard let docURL = documentURL else {
            return fileURL.lastPathComponent
        }

        let docDir = docURL.deletingLastPathComponent()
        let relativePath = fileURL.path.replacingOccurrences(of: docDir.path, with: "")

        // Remove leading slash if present
        if relativePath.hasPrefix("/") {
            return String(relativePath.dropFirst())
        }

        return relativePath
    }

    private static func insertMarkdownImage(in textView: NSTextView, at location: Int, imagePath: String) {
        // Load the image for inline display
        var displayImage: NSImage?

        // Try to load from the path
        if imagePath.hasPrefix("/") {
            // Absolute path
            displayImage = NSImage(contentsOfFile: imagePath)
        } else {
            // Relative path - try to resolve from document
            if let docURL = (textView as? MarkdownTextView)?.documentURL {
                let docDir = docURL.deletingLastPathComponent()
                let fullPath = docDir.appendingPathComponent(imagePath)
                displayImage = NSImage(contentsOfFile: fullPath.path)
            }
        }

        // Create attributed string with image attachment
        let attrString: NSAttributedString
        if let image = displayImage {
            // Use text attachment for inline image display
            let attachment = createTextAttachment(with: image)
            attrString = NSAttributedString(attachment: attachment)
        } else {
            // Fallback to text if image can't be loaded
            let markdown = "![](\(imagePath))"
            attrString = NSAttributedString(string: markdown)
        }

        // Use textStorage directly for attributed string replacement
        textView.textStorage?.replaceCharacters(in: NSRange(location: location, length: 0), with: attrString)

        // Move cursor after the image
        let newLocation = location + attrString.length
        textView.setSelectedRange(NSRange(location: newLocation, length: 0))
    }

    // MARK: - Image Attachment

    /// Create an NSTextAttachment with the image for inline display
    static func createTextAttachment(with image: NSImage) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = image

        // Scale image if too large
        let maxSize: CGFloat = 500
        let originalSize = image.size
        var scaledSize = originalSize
        if originalSize.width > maxSize || originalSize.height > maxSize {
            let ratio = min(maxSize / originalSize.width, maxSize / originalSize.height)
            scaledSize = NSSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
        }
        attachment.bounds = NSRect(origin: .zero, size: scaledSize)

        return attachment
    }
}
