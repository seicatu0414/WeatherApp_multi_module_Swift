//
//  wether_multi_module_AppApp.swift
//  wether_multi_module_App
//
//  Created by kohei yamaguchi on 2026/04/13.
//

import SwiftData
import SwiftUI
import WeatherDomain

@main
struct wether_multi_module_AppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FavoriteLocation.self,
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
