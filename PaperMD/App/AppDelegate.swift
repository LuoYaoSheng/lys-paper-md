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
