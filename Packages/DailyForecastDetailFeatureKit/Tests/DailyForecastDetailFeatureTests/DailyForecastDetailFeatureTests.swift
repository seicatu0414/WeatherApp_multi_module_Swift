import Foundation
import Testing
import WeatherDomain
@testable import DailyForecastDetailFeature

@MainActor
struct DailyForecastDetailFeatureTests {
    @Test
    func initializerStoresDailyForecast() {
        let day = DailyForecast(
            date: Date(timeIntervalSince1970: 1_234_567),
            weatherCode: 3,
            maxTemperature: 22,
            minTemperature: 14,
            precipitationProbabilityMax: 30
        )

        let viewModel = DailyForecastDetailViewModel(day: day)

        #expect(viewModel.day == day)
    }
}
