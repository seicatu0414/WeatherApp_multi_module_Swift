import Foundation
import Testing
import WeatherDomain
@testable import WeatherHomeFeature

@MainActor
struct WeatherHomeFeatureTests {
    @Test
    func onAppearLoadsFavorites() {
        let repository = FavoritesRepositorySpy()
        repository.favoritesToReturn = [makeLocation(id: "tokyo")]
        let viewModel = makeViewModel(favoritesRepository: repository)

        viewModel.onAppear()

        #expect(viewModel.favorites == repository.favoritesToReturn)
    }

    @Test
    func shortQueryClearsResultsWithoutSearching() {
        let weatherService = WeatherServiceSpy()
        let viewModel = makeViewModel(weatherService: weatherService)
        viewModel.query = "a"

        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.isSearching == false)
        #expect(weatherService.searchQueries.isEmpty)
    }

    @Test
    func searchQueryLoadsResultsAfterDebounce() async {
        let weatherService = WeatherServiceSpy()
        let expected = [makeLocation(id: "tokyo")]
        weatherService.searchResults = expected
        let viewModel = makeViewModel(weatherService: weatherService)

        viewModel.query = "to"
        try? await Task.sleep(for: .milliseconds(700))

        #expect(weatherService.searchQueries == ["to"])
        #expect(viewModel.searchResults == expected)
        #expect(viewModel.isSearching == false)
    }

    @Test
    func loadCurrentLocationEmitsForecast() async {
        let location = makeLocation(id: "current")
        let forecast = makeForecast(location: location)
        let weatherService = WeatherServiceSpy()
        let locationService = UserLocationServiceSpy()
        weatherService.forecastToReturn = forecast
        locationService.locationToReturn = location
        let viewModel = makeViewModel(weatherService: weatherService, locationService: locationService)
        var loadedForecast: WeatherForecast?

        viewModel.onForecastLoaded = { loadedForecast = $0 }
        viewModel.loadCurrentLocation()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(locationService.requestCount == 1)
        #expect(weatherService.forecastLocations == [location])
        #expect(loadedForecast == forecast)
        #expect(viewModel.isLoadingForecast == false)
    }

    @Test
    func loadCurrentLocationReportsError() async {
        let locationService = UserLocationServiceSpy()
        locationService.error = WeatherError.locationPermissionDenied
        let viewModel = makeViewModel(locationService: locationService)
        var errorMessage: String?

        viewModel.onError = { errorMessage = $0 }
        viewModel.loadCurrentLocation()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(errorMessage == WeatherError.locationPermissionDenied.localizedDescription)
        #expect(viewModel.isLoadingForecast == false)
    }

    @Test
    func selectLocationLoadsForecast() async {
        let weatherService = WeatherServiceSpy()
        let location = makeLocation(id: "tokyo")
        let forecast = makeForecast(location: location)
        weatherService.forecastToReturn = forecast
        let viewModel = makeViewModel(weatherService: weatherService)
        var loadedForecast: WeatherForecast?

        viewModel.onForecastLoaded = { loadedForecast = $0 }
        viewModel.selectLocation(location)
        try? await Task.sleep(for: .milliseconds(50))

        #expect(weatherService.forecastLocations == [location])
        #expect(loadedForecast == forecast)
    }
}

@MainActor
private func makeViewModel(
    weatherService: WeatherServiceSpy = WeatherServiceSpy(),
    locationService: UserLocationServiceSpy = UserLocationServiceSpy(),
    favoritesRepository: FavoritesRepositorySpy = FavoritesRepositorySpy()
) -> WeatherHomeViewModel {
    WeatherHomeViewModel(
        weatherService: weatherService,
        locationService: locationService,
        favoritesRepository: favoritesRepository
    )
}

private func makeLocation(id: String) -> LocationSearchResult {
    LocationSearchResult(
        id: id,
        name: id,
        admin1: "Tokyo",
        country: "Japan",
        coordinate: Coordinate(latitude: 35.0, longitude: 139.0)
    )
}

private func makeForecast(location: LocationSearchResult) -> WeatherForecast {
    WeatherForecast(
        location: location,
        timezone: "Asia/Tokyo",
        current: CurrentWeather(temperature: 20, weatherCode: 0, windSpeed: 2, apparentTemperature: 19),
        daily: []
    )
}

private final class WeatherServiceSpy: WeatherService, @unchecked Sendable {
    var searchResults: [LocationSearchResult] = []
    var forecastToReturn = makeForecast(location: makeLocation(id: "default"))
    var searchQueries: [String] = []
    var forecastLocations: [LocationSearchResult] = []

    func searchLocations(query: String) async throws -> [LocationSearchResult] {
        searchQueries.append(query)
        return searchResults
    }

    func forecast(for location: LocationSearchResult) async throws -> WeatherForecast {
        forecastLocations.append(location)
        return forecastToReturn
    }
}

private final class UserLocationServiceSpy: UserLocationService, @unchecked Sendable {
    var locationToReturn = makeLocation(id: "current")
    var error: Error?
    var requestCount = 0

    func requestCurrentLocation() async throws -> LocationSearchResult {
        requestCount += 1
        if let error {
            throw error
        }
        return locationToReturn
    }
}

@MainActor
private final class FavoritesRepositorySpy: FavoritesRepository {
    var favoritesToReturn: [LocationSearchResult] = []

    func fetchFavorites() throws -> [LocationSearchResult] {
        favoritesToReturn
    }

    func save(_ location: LocationSearchResult) throws {}

    func isFavorite(_ location: LocationSearchResult) throws -> Bool {
        favoritesToReturn.contains(location)
    }
}
