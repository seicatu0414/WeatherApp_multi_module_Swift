import CoreLocation
import Foundation
import SwiftData
import WeatherDomainMVVM

public actor OpenMeteoWeatherService: WeatherService {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func searchLocations(query: String) async throws -> [LocationSearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedQuery)&count=8&language=ja&format=json") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(GeocodingResponse.self, from: data)

        return (response.results ?? []).map {
            LocationSearchResult(
                id: "\($0.id)-\($0.latitude)-\($0.longitude)",
                name: $0.name,
                admin1: $0.admin1,
                country: $0.country,
                coordinate: Coordinate(latitude: $0.latitude, longitude: $0.longitude)
            )
        }
    }

    public func forecast(for location: LocationSearchResult) async throws -> WeatherForecast {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        guard let url = URL(
            string: """
            https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code,wind_speed_10m,apparent_temperature&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto
            """
        ) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(ForecastResponse.self, from: data)

        guard
            let current = response.current,
            let daily = response.daily
        else {
            throw WeatherError.emptyResponse
        }

        let forecasts = zip(
            daily.time,
            zip(
                daily.weatherCode,
                zip(
                    daily.temperatureMax,
                    zip(daily.temperatureMin, daily.precipitationProbabilityMax)
                )
            )
        ).compactMap { time, values -> DailyForecast? in
            guard let date = Self.dayFormatter.date(from: time) else {
                return nil
            }

            return DailyForecast(
                date: date,
                weatherCode: values.0,
                maxTemperature: values.1.0,
                minTemperature: values.1.1.0,
                precipitationProbabilityMax: values.1.1.1
            )
        }

        return WeatherForecast(
            location: location,
            timezone: response.timezone,
            current: CurrentWeather(
                temperature: current.temperature,
                weatherCode: current.weatherCode,
                windSpeed: current.windSpeed,
                apparentTemperature: current.apparentTemperature
            ),
            daily: forecasts
        )
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

@MainActor
public final class SwiftDataFavoritesRepository: FavoritesRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func fetchFavorites() throws -> [LocationSearchResult] {
        let descriptor = FetchDescriptor<FavoriteLocation>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.searchResult)
    }

    public func save(_ location: LocationSearchResult) throws {
        if try isFavorite(location) {
            return
        }

        context.insert(FavoriteLocation(location: location))
        try context.save()
    }

    public func isFavorite(_ location: LocationSearchResult) throws -> Bool {
        let key = location.id
        var descriptor = FetchDescriptor<FavoriteLocation>(
            predicate: #Predicate { favorite in
                favorite.key == key
            }
        )
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }
}

public final class LiveUserLocationService: NSObject, UserLocationService, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<LocationSearchResult, Error>?

    public override init() {
        self.manager = CLLocationManager()
        super.init()
        self.manager.delegate = self
    }

    public func requestCurrentLocation() async throws -> LocationSearchResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            switch self.manager.authorizationStatus {
            case .notDetermined:
                self.manager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                continuation.resume(throwing: WeatherError.locationPermissionDenied)
                self.continuation = nil
            default:
                self.manager.requestLocation()
            }
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            continuation?.resume(throwing: WeatherError.locationPermissionDenied)
            continuation = nil
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            continuation?.resume(throwing: WeatherError.invalidLocation)
            continuation = nil
            return
        }

        let result = LocationSearchResult(
            id: "current-\(location.coordinate.latitude)-\(location.coordinate.longitude)",
            name: "現在地",
            admin1: nil,
            country: "Current Location",
            coordinate: Coordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        )

        continuation?.resume(returning: result)
        continuation = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]?
}

private struct GeocodingResult: Decodable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let admin1: String?
    let country: String
}

private struct ForecastResponse: Decodable {
    let timezone: String
    let current: CurrentResponse?
    let daily: DailyResponse?
}

private struct CurrentResponse: Decodable {
    let temperature: Double
    let weatherCode: Int
    let windSpeed: Double
    let apparentTemperature: Double

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case apparentTemperature = "apparent_temperature"
    }
}

private struct DailyResponse: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    let precipitationProbabilityMax: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}
