import Combine
import WeatherDomainMVVM

@MainActor
public final class WeatherViewModel: ObservableObject {
    @Published public var query = ""
    @Published public private(set) var searchResults: [LocationSearchResult] = []
    @Published public private(set) var favorites: [LocationSearchResult] = []
    @Published public private(set) var currentForecast: WeatherForecast?
    @Published public var navigationPath: [WeatherRoute] = []
    @Published public private(set) var isSearching = false
    @Published public private(set) var isLoadingForecast = false
    @Published public var errorMessage: String?

    private let weatherService: any WeatherService
    private let locationService: any UserLocationService
    private let favoritesRepository: any FavoritesRepository
    private var cancellables = Set<AnyCancellable>()

    public init(
        weatherService: any WeatherService,
        locationService: any UserLocationService,
        favoritesRepository: any FavoritesRepository
    ) {
        self.weatherService = weatherService
        self.locationService = locationService
        self.favoritesRepository = favoritesRepository

        bindQuery()
    }

    public func onAppear() {
        loadFavorites()
    }

    public func loadCurrentLocation() {
        isLoadingForecast = true
        errorMessage = nil

        Task {
            do {
                let location = try await locationService.requestCurrentLocation()
                await loadForecast(for: location)
            } catch {
                await MainActor.run {
                    self.isLoadingForecast = false
                    self.errorMessage = error.localizedDescription
                }
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

    public func saveCurrentLocationToFavorites() {
        guard let forecast = currentForecast else {
            errorMessage = WeatherError.missingCurrentForecast.localizedDescription
            return
        }

        do {
            try favoritesRepository.save(forecast.location)
            loadFavorites()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func openDailyForecast(_ day: DailyForecast) {
        guard let forecast = currentForecast else {
            return
        }

        navigationPath.append(.dailyDetail(forecast, day))
    }

    public func isFavoriteCurrentLocation() -> Bool {
        guard let forecast = currentForecast else {
            return false
        }

        return favorites.contains(forecast.location)
    }

    private func bindQuery() {
        $query
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task { await self?.searchLocations(for: query) }
            }
            .store(in: &cancellables)
    }

    private func searchLocations(for query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            await MainActor.run {
                self.isSearching = false
                self.searchResults = []
            }
            return
        }

        await MainActor.run {
            self.isSearching = true
            self.errorMessage = nil
        }

        do {
            let results = try await weatherService.searchLocations(query: trimmedQuery)
            await MainActor.run {
                if self.query.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedQuery {
                    self.searchResults = results
                    self.isSearching = false
                }
            }
        } catch {
            await MainActor.run {
                self.isSearching = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func loadForecast(for location: LocationSearchResult) async {
        await MainActor.run {
            self.isLoadingForecast = true
            self.errorMessage = nil
        }

        do {
            let forecast = try await weatherService.forecast(for: location)
            await MainActor.run {
                self.currentForecast = forecast
                self.navigationPath = [.forecast(forecast)]
                self.isLoadingForecast = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingForecast = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func loadFavorites() {
        do {
            favorites = try favoritesRepository.fetchFavorites()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
