import Observation
import SwiftData
import WeatherData
import DailyForecastDetailFeature
import WeatherDomain
import WeatherForecastFeature
import WeatherHomeFeature

@MainActor
@Observable
public final class WeatherAppRootViewModel {
    public var navigationPath: [WeatherRoute] = []
    public var errorMessage: String?
    public let homeViewModel: WeatherHomeViewModel

    public init(modelContext: ModelContext) {
        let weatherService = OpenMeteoWeatherService()
        let locationService = LiveUserLocationService()
        let favoritesRepository = SwiftDataFavoritesRepository(context: modelContext)

        let homeViewModel = WeatherHomeViewModel(
            weatherService: weatherService,
            locationService: locationService,
            favoritesRepository: favoritesRepository
        )

        self.homeViewModel = homeViewModel

        homeViewModel.onForecastLoaded = { [weak self] forecast in
            self?.navigationPath = [.forecast(forecast)]
        }
        homeViewModel.onError = { [weak self] message in
            self?.errorMessage = message
        }
    }

    public func onAppear() {
        homeViewModel.onAppear()
    }

    public func dismissError() {
        errorMessage = nil
    }

    public func makeForecastViewModel(for forecast: WeatherForecast) -> WeatherForecastViewModel {
        let viewModel = WeatherForecastViewModel(forecast: forecast, favoritesRepository: homeViewModel.favoritesRepository)

        viewModel.onDailyForecastSelected = { [weak self] selectedDay in
            self?.navigationPath.append(.dailyDetail(forecast, selectedDay))
        }
        viewModel.onFavoritesUpdated = { [weak self] in
            self?.homeViewModel.reloadFavorites()
        }
        viewModel.onError = { [weak self] message in
            self?.errorMessage = message
        }
        viewModel.refreshFavoriteState()

        return viewModel
    }

    public func makeDailyForecastDetailViewModel(for day: DailyForecast) -> DailyForecastDetailViewModel {
        DailyForecastDetailViewModel(day: day)
    }
}
