# PaperMD

A native macOS Markdown editor focused on ultimate input experience for long-form writing, documentation, and technical writing.

## Features

- **Native macOS App**: Built with AppKit for the best performance and native feel
- **Live Preview**: Real-time Markdown syntax highlighting as you type
- **Smart Editing**: Auto list continuation, tab indentation, and smart list item termination
- **Outline View**: Auto-generated table of contents from headers for easy navigation
- **Focus Mode**: Hide distractions and focus on your writing
- **Full Keyboard Support**: Comprehensive keyboard shortcuts for all operations
- **Paste as Plain Text**: Automatically strips formatting when pasting from external sources

## Keyboard Shortcuts

### File Operations
| Shortcut | Action |
|----------|--------|
| `⌘N` | New Document |
| `⌘O` | Open… |
| `⌘W` | Close Window |
| `⌘S` | Save |
| `⌘⇧S` | Save As… |
| `⌘Q` | Quit |

### Edit Operations
| Shortcut | Action |
|----------|--------|
| `⌘Z` | Undo |
| `⌘⇧Z` | Redo |
| `⌘X` | Cut |
| `⌘C` | Copy |
| `⌘V` | Paste (as plain text) |
| `⌘A` | Select All |

### Find & Replace
| Shortcut | Action |
|----------|--------|
| `⌘F` | Find… |
| `⌘G` | Find Next |
| `⌘⇧G` | Find Previous |
| `⌘⌥F` | Replace |

### Spelling
| Shortcut | Action |
|----------|--------|
| `⌘:` | Show Spelling and Grammar |
| `⌘;` | Check Document Now |

### Text Transformations
| Shortcut | Action |
|----------|--------|
| `⌃⌘U` | Make Upper Case |
| `⌃⌘L` | Make Lower Case |
| `⌥⌘C` | Capitalize |

### Navigation
| Shortcut | Action |
|----------|--------|
| `⌘J` | Jump to Selection / Center in View |

### Format Menu
| Shortcut | Action |
|----------|--------|
| `⌘B` | Bold |
| `⌘I` | Italic |
| `⌘K` | Inline Code |
| `⌥⌘S` | Strikethrough |
| `⇧⌘1` | Heading 1 |
| `⇧⌘2` | Heading 2 |
| `⇧⌘3` | Heading 3 |
| `⌥⌘>` | Blockquote |
| `⌥⌘C` | Code Block |
| `⇧⌘L` | Insert Link |

### View
| Shortcut | Action |
|----------|--------|
| `⌃⌘O` | Toggle Sidebar |
| `⌘F` | Toggle Focus Mode |

### Window
| Shortcut | Action |
|----------|--------|
| `⌘M` | Minimize |
| `⌘H` | Hide |
| `⌥⌘H` | Hide Others |

## Smart Editing Features

### List Continuation
When you press Enter at the end of a list item, a new list item is automatically created:
- Unordered lists (`- `, `* `, `+ `) continue with the same marker
- Ordered lists (`1. `, `2. `, etc.) continue with incremented numbers
- Task lists (`- [ ] `) continue with unchecked items
- Press Enter on an empty list item to terminate the list

### Tab Indentation
- Press `Tab` to indent list items (adds 2 spaces)
- Press `⇧Tab` to unindent list items (removes 2 spaces)

### Smart Paste
Pasting content from external sources automatically strips rich formatting, inserting only plain text.

## Requirements

- macOS 12.0 or later
- Xcode 14.0 or later to build from source

## Building from Source

```bash
git clone https://gitee.com/luoyaosheng/PaperMD.git
cd PaperMD
open PaperMD.xcodeproj
```

Then build and run in Xcode.

## Architecture

- **Language**: Swift
- **UI Framework**: AppKit
- **Document Architecture**: NSDocument-based
- **Editing Engine**: NSTextView with NSTextStorage
- **Undo System**: NSUndoManager

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
