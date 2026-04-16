import Foundation
import SwiftData
import Testing
import WeatherDomain
@testable import WeatherFeature

@MainActor
struct WeatherFeatureTests {
    @Test
    func dismissErrorClearsErrorMessage() throws {
        let viewModel = try makeRootViewModel()

        viewModel.homeViewModel.onError?("failed")
        viewModel.dismissError()

        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func homeForecastCallbackPushesForecastRoute() throws {
        let viewModel = try makeRootViewModel()
        let forecast = makeForecast()

        viewModel.homeViewModel.onForecastLoaded?(forecast)

        #expect(viewModel.navigationPath == [.forecast(forecast)])
    }

    @Test
    func forecastViewModelAppendsDailyDetailRoute() throws {
        let viewModel = try makeRootViewModel()
        let forecast = makeForecast()
        let day = try #require(forecast.daily.first)
        let forecastViewModel = viewModel.makeForecastViewModel(for: forecast)

        forecastViewModel.openDailyForecast(day)

        #expect(viewModel.navigationPath == [.dailyDetail(forecast, day)])
    }

    @Test
    func forecastViewModelSaveReloadsHomeFavorites() throws {
        let viewModel = try makeRootViewModel()
        let forecast = makeForecast()
        let forecastViewModel = viewModel.makeForecastViewModel(for: forecast)

        forecastViewModel.saveCurrentLocationToFavorites()

        #expect(viewModel.homeViewModel.favorites == [forecast.location])
    }

    @Test
    func makeDailyForecastDetailViewModelKeepsSelectedDay() throws {
        let viewModel = try makeRootViewModel()
        let day = try #require(makeForecast().daily.first)

        let detailViewModel = viewModel.makeDailyForecastDetailViewModel(for: day)

        #expect(detailViewModel.day == day)
    }
}

@MainActor
private func makeRootViewModel() throws -> WeatherAppRootViewModel {
    let schema = Schema([FavoriteLocation.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return WeatherAppRootViewModel(modelContext: container.mainContext)
}

private func makeForecast() -> WeatherForecast {
    let location = LocationSearchResult(
        id: "tokyo",
        name: "Tokyo",
        admin1: "Tokyo",
        country: "Japan",
        coordinate: Coordinate(latitude: 35.0, longitude: 139.0)
    )
    let day = DailyForecast(
        date: Date(timeIntervalSince1970: 1_234_567),
        weatherCode: 61,
        maxTemperature: 24,
        minTemperature: 18,
        precipitationProbabilityMax: 60
    )

    return WeatherForecast(
        location: location,
        timezone: "Asia/Tokyo",
        current: CurrentWeather(temperature: 20, weatherCode: 3, windSpeed: 2, apparentTemperature: 19),
        daily: [day]
    )
}
