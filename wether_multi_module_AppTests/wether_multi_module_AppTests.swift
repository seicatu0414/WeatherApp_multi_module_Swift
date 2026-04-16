import Foundation
import SwiftData
import Testing
@testable import wether_multi_module_App

struct wether_multi_module_AppTests {
    @Test
    func itemStoresTimestampPassedToInitializer() {
        let timestamp = Date(timeIntervalSince1970: 1_234_567_890)

        let item = Item(timestamp: timestamp)

        #expect(item.timestamp == timestamp)
    }

    @Test
    func itemAllowsTimestampMutation() {
        let original = Date(timeIntervalSince1970: 100)
        let updated = Date(timeIntervalSince1970: 200)
        let item = Item(timestamp: original)

        item.timestamp = updated

        #expect(item.timestamp == updated)
    }

    @Test
    @MainActor
    func contentViewBodyBuildsWeatherRootView() {
        let bodyType = String(reflecting: type(of: ContentView().body))

        #expect(bodyType.contains("WeatherAppRootView"))
    }

    @Test
    @MainActor
    func appCreatesSharedModelContainer() {
        let app = wether_multi_module_AppApp()
        let context = app.sharedModelContainer.mainContext

        #expect(String(reflecting: type(of: context)).contains("ModelContext"))
        #expect(context.hasChanges == false)
    }
}
