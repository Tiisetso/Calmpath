//
//  CalmpathApp.swift
//  Calmpath
//
//  Created by Tiisetso Daniel Murray on 2025/11/15.
//

import SwiftUI
import SwiftData

@main
struct CalmpathApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MigraineLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, try to create a fresh container by deleting the old store
            print("⚠️ Failed to load existing model container: \(error)")
            print("⚠️ Attempting to create fresh container...")
            
            // Try to delete the old store files
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after cleanup: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
