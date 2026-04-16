import Foundation
import Observation
import WeatherDomain

@MainActor
@Observable
public final class WeatherHomeViewModel {
    public var query = "" {
        didSet {
            scheduleSearch()
        }
    }
    public private(set) var searchResults: [LocationSearchResult] = []
    public private(set) var favorites: [LocationSearchResult] = []
    public private(set) var isSearching = false
    public private(set) var isLoadingForecast = false

    public var onForecastLoaded: ((WeatherForecast) -> Void)?
    public var onError: ((String) -> Void)?

    public let favoritesRepository: any FavoritesRepository

    private let weatherService: any WeatherService
    private let locationService: any UserLocationService
    private var searchTask: Task<Void, Never>?

    public init(
        weatherService: any WeatherService,
        locationService: any UserLocationService,
        favoritesRepository: any FavoritesRepository
    ) {
        self.weatherService = weatherService
        self.locationService = locationService
        self.favoritesRepository = favoritesRepository
    }

    public func onAppear() {
        reloadFavorites()
    }

    public func loadCurrentLocation() {
        isLoadingForecast = true

        Task {
            do {
                let location = try await locationService.requestCurrentLocation()
                await loadForecast(for: location)
            } catch {
                isLoadingForecast = false
                onError?(error.localizedDescription)
            }
        }
    }

    public func selectLocation(_ location: LocationSearchResult) {
        Task {
            await loadForecast(for: location)
        }
    }

    public func selectFavorite(_ location: LocationSearchResult) {
        selectLocation(location)
    }

    public func reloadFavorites() {
        do {
            favorites = try favoritesRepository.fetchFavorites()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    private func scheduleSearch() {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            isSearching = false
            searchResults = []
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else {
                return
            }
            await self?.searchLocations(for: trimmedQuery)
        }
    }

    private func searchLocations(for query: String) async {
        isSearching = true

        do {
            let results = try await weatherService.searchLocations(query: query)
            guard self.query.trimmingCharacters(in: .whitespacesAndNewlines) == query else {
                return
            }
            searchResults = results
            isSearching = false
        } catch {
            isSearching = false
            onError?(error.localizedDescription)
        }
    }

    private func loadForecast(for location: LocationSearchResult) async {
        isLoadingForecast = true

        do {
            let forecast = try await weatherService.forecast(for: location)
            onForecastLoaded?(forecast)
            isLoadingForecast = false
        } catch {
            isLoadingForecast = false
            onError?(error.localizedDescription)
        }
    }
}
