//
//  ContentView.swift
//  wether_multi_module_App
//
//  Created by kohei yamaguchi on 2026/04/13.
//

import SwiftData
import SwiftUI
import WeatherDomain
import WeatherFeature

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        WeatherAppRootView(modelContext: modelContext)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FavoriteLocation.self, inMemory: true)
}
