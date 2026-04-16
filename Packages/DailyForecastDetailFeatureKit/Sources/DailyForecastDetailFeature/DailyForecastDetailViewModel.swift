import Observation
import WeatherDomain

@MainActor
@Observable
public final class DailyForecastDetailViewModel {
    public let day: DailyForecast

    public init(day: DailyForecast) {
        self.day = day
    }
}
