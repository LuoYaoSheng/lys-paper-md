# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PaperMD is a **native macOS Markdown editor** focused on ultimate input experience for long-form writing, documentation, and technical writing. The project is currently in early documentation/planning phase - no implementation code exists yet.

**Core Philosophy**: "输入零卡顿、光标行为 100% 可预测" (Zero input lag, 100% predictable cursor behavior). This is the non-negotiable P0 priority that trumps all other considerations.

## Technology Stack (Fixed)

- **Language**: Swift
- **UI Framework**: AppKit (primary) + SwiftUI (settings pages only, not editor)
- **Document Architecture**: NSDocument / Document-based App
- **Editing Engine**: TextKit 2 (NSTextContentManager/NSTextLayoutManager/NSTextViewportLayoutController) + NSTextView
- **Undo System**: NSUndoManager (all structural operations must be undoable)
- **Image Handling**: Local `.assets/` folder + relative paths + NSTextAttachment
- **Export**: HTML generation + NSPrintOperation for PDF

## Architecture Principles

### Source of Truth
The Markdown plain text is always the source of truth. Internal parsed structure (parseTree) is for rendering only and must never pollute the saved file.

**Implementation pattern**:
- `rawText`: Real text content (for saving)
- `parseTree`: Incrementally parsed structure (for rendering)
- Rendering: Use `NSAttributedString` attributes for WYSIWYG styling without altering source text semantics

### Incremental Parsing
- Parsing must never block input thread
- Line-level incremental parsing: only recalculate affected paragraphs/blocks
- Heavy parsing work goes to background, then gently update styles without cursor jump

### Input Experience Requirements (P0 - Non-negotiable)
1. **Cursor rules**: Cursor position must match user expectation, never jump due to rendering
2. **Auto-formatting**: Must never move cursor position
3. **Chinese IME**: During composition state, no layout rebuild or structural transformation
4. **Undo/Redo**: Every structural change must be undoable (typing, deletion, paste, auto-format)

### Image Handling
- Images automatically save to local files (no base64, no implicit cloud upload)
- Storage: `{document_name}.assets/`
- Naming: timestamp + hash
- Insert: `![](xxx.assets/...)` with NSTextAttachment display

## Feature Scope (v1)

**Included**:
- H1-H6, paragraphs, ordered/unordered lists, quotes, code blocks, inline code, images, horizontal rules
- Single-column WYSIWYG editing
- Outline view (auto-generated from headers)
- Export to HTML and PDF

**Explicitly excluded (v2+)**:
- Tables, footnotes, math formulas
- Cloud sync, collaboration, plugins, AI writing, accounts

## Non-negotiable Product Constraints

From the product manifesto: "我们宁愿慢一点，也不允许一次输入体验上的妥协" (Rather be slower, never compromise input experience).

When making implementation decisions:
- Input responsiveness > advanced features
- Stability > feature completeness
- Data safety > fancy UI tricks
- Native AppKit editing > WebView shortcuts

## Planned Development Phases

1. **Project skeleton**: Document-based App + single window + Toolbar + EditorTextView
2. **Input correctness**: IME/cursor/undo test cases
3. **Minimal rendering**: Only headers/code blocks/quotes styling
4. **Gradual feature addition**: Images, export, outline view

## Documentation Reference

- `docs/产品说明.md`: Product requirements document (PRD) with detailed feature specs
- `docs/UI.md`: Technical architecture decisions and implementation guidelines
