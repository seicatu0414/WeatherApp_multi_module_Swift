import Foundation
import Testing
import WeatherDomain
@testable import WeatherForecastFeature

@MainActor
struct WeatherForecastFeatureTests {
    @Test
    func saveCurrentLocationStoresFavoriteAndNotifies() {
        let repository = FavoritesRepositorySpy()
        let viewModel = WeatherForecastViewModel(
            forecast: makeForecast(),
            favoritesRepository: repository
        )
        var didUpdateFavorites = false

        viewModel.onFavoritesUpdated = { didUpdateFavorites = true }
        viewModel.saveCurrentLocationToFavorites()

        #expect(repository.savedLocations == [viewModel.forecast.location])
        #expect(viewModel.isFavorite == true)
        #expect(didUpdateFavorites)
    }

    @Test
    func saveCurrentLocationReportsRepositoryError() {
        let repository = FavoritesRepositorySpy()
        repository.saveError = WeatherError.missingCurrentForecast
        let viewModel = WeatherForecastViewModel(
            forecast: makeForecast(),
            favoritesRepository: repository
        )
        var errorMessage: String?

        viewModel.onError = { errorMessage = $0 }
        viewModel.saveCurrentLocationToFavorites()

        #expect(errorMessage == WeatherError.missingCurrentForecast.localizedDescription)
        #expect(viewModel.isFavorite == false)
    }

    @Test
    func openDailyForecastPassesSelectedDay() {
        let day = makeDay()
        let viewModel = WeatherForecastViewModel(
            forecast: makeForecast(daily: [day]),
            favoritesRepository: FavoritesRepositorySpy()
        )
        var selectedDay: DailyForecast?

        viewModel.onDailyForecastSelected = { selectedDay = $0 }
        viewModel.openDailyForecast(day)

        #expect(selectedDay == day)
    }

    @Test
    func refreshFavoriteStateReadsRepository() {
        let repository = FavoritesRepositorySpy()
        repository.favoriteState = true
        let viewModel = WeatherForecastViewModel(
            forecast: makeForecast(),
            favoritesRepository: repository
        )

        viewModel.refreshFavoriteState()

        #expect(viewModel.isFavorite == true)
    }
}

private func makeForecast(daily: [DailyForecast] = []) -> WeatherForecast {
    WeatherForecast(
        location: LocationSearchResult(
            id: "tokyo",
            name: "Tokyo",
            admin1: "Tokyo",
            country: "Japan",
            coordinate: Coordinate(latitude: 35.0, longitude: 139.0)
        ),
        timezone: "Asia/Tokyo",
        current: CurrentWeather(temperature: 20, weatherCode: 0, windSpeed: 2, apparentTemperature: 19),
        daily: daily
    )
}

private func makeDay() -> DailyForecast {
    DailyForecast(
        date: Date(timeIntervalSince1970: 1_234_567),
        weatherCode: 61,
        maxTemperature: 24,
        minTemperature: 18,
        precipitationProbabilityMax: 70
    )
}

@MainActor
private final class FavoritesRepositorySpy: FavoritesRepository {
    var savedLocations: [LocationSearchResult] = []
    var favoriteState = false
    var saveError: Error?

    func fetchFavorites() throws -> [LocationSearchResult] {
        []
    }

    func save(_ location: LocationSearchResult) throws {
        if let saveError {
            throw saveError
        }
        savedLocations.append(location)
    }

    func isFavorite(_ location: LocationSearchResult) throws -> Bool {
        favoriteState
    }
}
