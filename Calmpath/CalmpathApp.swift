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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
