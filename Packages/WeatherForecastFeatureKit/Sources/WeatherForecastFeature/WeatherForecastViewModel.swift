import Observation
import WeatherDomain

@MainActor
@Observable
public final class WeatherForecastViewModel {
    public let forecast: WeatherForecast
    public private(set) var isFavorite = false

    public var onDailyForecastSelected: ((DailyForecast) -> Void)?
    public var onFavoritesUpdated: (() -> Void)?
    public var onError: ((String) -> Void)?

    private let favoritesRepository: any FavoritesRepository

    public init(
        forecast: WeatherForecast,
        favoritesRepository: any FavoritesRepository
    ) {
        self.forecast = forecast
        self.favoritesRepository = favoritesRepository
    }

    public func saveCurrentLocationToFavorites() {
        do {
            try favoritesRepository.save(forecast.location)
            isFavorite = true
            onFavoritesUpdated?()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    public func openDailyForecast(_ day: DailyForecast) {
        onDailyForecastSelected?(day)
    }

    public func refreshFavoriteState() {
        do {
            isFavorite = try favoritesRepository.isFavorite(forecast.location)
        } catch {
            onError?(error.localizedDescription)
        }
    }
}
