import Foundation
import Cocoa

class BookmarkManager {
    static let shared = BookmarkManager()
    private var bookmarks = [URL: Data]()
    
    private init() {
        loadBookmarks()
    }
    
    func requestFolderAccess(for url: URL) -> Bool {
        // Prüfe, ob wir bereits Zugriff haben
        if let bookmarkData = bookmarks[url] {
            if restoreBookmark((url, bookmarkData)) {
                return true
            }
        }
        
        // Wenn nicht, frage nach Zugriff
        let openPanel = NSOpenPanel()
        openPanel.message = "Bitte wählen Sie den Ordner aus, um Schreibzugriff zu gewähren"
        openPanel.prompt = "Zugriff gewähren"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.directoryURL = url
        openPanel.level = .modalPanel
        
        let response = openPanel.runModal()
        if response == .OK, let selectedURL = openPanel.url {
            storeFolderInBookmark(url: selectedURL)
            saveBookmarksData()
            return restoreBookmark((selectedURL, bookmarks[selectedURL]!))
        }
        return false
    }
    
    private func storeFolderInBookmark(url: URL) {
        do {
            let data = try url.bookmarkData(options: .withSecurityScope,
                                          includingResourceValuesForKeys: nil,
                                          relativeTo: nil)
            bookmarks[url] = data
        } catch {
            print("❌ Fehler beim Speichern des Bookmarks: \(error)")
        }
    }
    
    private func getBookmarkPath() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let bookmarksDir = appSupport.appendingPathComponent("cpdf", isDirectory: true)
        let bookmarksFile = bookmarksDir.appendingPathComponent("Bookmarks.data")
        
        // Erstelle den Ordner, falls er nicht existiert
        try? FileManager.default.createDirectory(at: bookmarksDir,
                                               withIntermediateDirectories: true)
        
        return bookmarksFile
    }
    
    private func saveBookmarksData() {
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: bookmarks,
                requiringSecureCoding: true
            )
            try data.write(to: getBookmarkPath())
        } catch {
            print("❌ Fehler beim Speichern der Bookmarks: \(error)")
        }
    }
    
    private func loadBookmarks() {
        do {
            let bookmarksData = try Data(contentsOf: getBookmarkPath())
            if let loadedBookmarks = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSDictionary.self,
                from: bookmarksData
            ) as? [URL: Data] {
                bookmarks = loadedBookmarks
                for bookmark in bookmarks {
                    _ = restoreBookmark(bookmark)
                }
            }
        } catch {
            print("⚠️ Keine gespeicherten Bookmarks gefunden oder Fehler beim Laden: \(error)")
        }
    }
    
    private func restoreBookmark(_ bookmark: (key: URL, value: Data)) -> Bool {
        var isStale = false
        
        do {
            let restoredUrl = try URL(resolvingBookmarkData: bookmark.value,
                                    options: .withSecurityScope,
                                    relativeTo: nil,
                                    bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("⚠️ Bookmark ist veraltet")
                return false
            }
            
            return restoredUrl.startAccessingSecurityScopedResource()
        } catch {
            print("❌ Fehler beim Wiederherstellen des Bookmarks: \(error)")
            return false
        }
    }
} 