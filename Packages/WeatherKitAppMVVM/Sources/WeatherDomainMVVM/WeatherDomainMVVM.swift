import Foundation
import SwiftData

public struct Coordinate: Codable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct LocationSearchResult: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let admin1: String?
    public let country: String
    public let coordinate: Coordinate

    public init(
        id: String,
        name: String,
        admin1: String?,
        country: String,
        coordinate: Coordinate
    ) {
        self.id = id
        self.name = name
        self.admin1 = admin1
        self.country = country
        self.coordinate = coordinate
    }

    public var subtitle: String {
        [admin1, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

public struct CurrentWeather: Codable, Hashable, Sendable {
    public let temperature: Double
    public let weatherCode: Int
    public let windSpeed: Double
    public let apparentTemperature: Double

    public init(
        temperature: Double,
        weatherCode: Int,
        windSpeed: Double,
        apparentTemperature: Double
    ) {
        self.temperature = temperature
        self.weatherCode = weatherCode
        self.windSpeed = windSpeed
        self.apparentTemperature = apparentTemperature
    }
}

public struct DailyForecast: Identifiable, Codable, Hashable, Sendable {
    public var id: Date { date }
    public let date: Date
    public let weatherCode: Int
    public let maxTemperature: Double
    public let minTemperature: Double
    public let precipitationProbabilityMax: Int

    public init(
        date: Date,
        weatherCode: Int,
        maxTemperature: Double,
        minTemperature: Double,
        precipitationProbabilityMax: Int
    ) {
        self.date = date
        self.weatherCode = weatherCode
        self.maxTemperature = maxTemperature
        self.minTemperature = minTemperature
        self.precipitationProbabilityMax = precipitationProbabilityMax
    }
}

public struct WeatherForecast: Identifiable, Codable, Hashable, Sendable {
    public var id: String { location.id }
    public let location: LocationSearchResult
    public let timezone: String
    public let current: CurrentWeather
    public let daily: [DailyForecast]

    public init(
        location: LocationSearchResult,
        timezone: String,
        current: CurrentWeather,
        daily: [DailyForecast]
    ) {
        self.location = location
        self.timezone = timezone
        self.current = current
        self.daily = daily
    }
}

public enum WeatherRoute: Hashable {
    case forecast(WeatherForecast)
    case dailyDetail(WeatherForecast, DailyForecast)
}

@Model
public final class FavoriteLocation {
    @Attribute(.unique) public var key: String
    public var name: String
    public var admin1: String?
    public var country: String
    public var latitude: Double
    public var longitude: Double
    public var createdAt: Date

    public init(location: LocationSearchResult) {
        self.key = location.id
        self.name = location.name
        self.admin1 = location.admin1
        self.country = location.country
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.createdAt = .now
    }

    public var searchResult: LocationSearchResult {
        LocationSearchResult(
            id: key,
            name: name,
            admin1: admin1,
            country: country,
            coordinate: Coordinate(latitude: latitude, longitude: longitude)
        )
    }
}

public protocol WeatherService: Sendable {
    func searchLocations(query: String) async throws -> [LocationSearchResult]
    func forecast(for location: LocationSearchResult) async throws -> WeatherForecast
}

public protocol UserLocationService: Sendable {
    func requestCurrentLocation() async throws -> LocationSearchResult
}

@MainActor
public protocol FavoritesRepository: AnyObject {
    func fetchFavorites() throws -> [LocationSearchResult]
    func save(_ location: LocationSearchResult) throws
    func isFavorite(_ location: LocationSearchResult) throws -> Bool
}

public enum WeatherError: LocalizedError {
    case invalidLocation
    case missingCurrentForecast
    case emptyResponse
    case locationPermissionDenied

    public var errorDescription: String? {
        switch self {
        case .invalidLocation:
            "位置情報の取得に失敗しました。"
        case .missingCurrentForecast:
            "保存対象の天気情報がありません。"
        case .emptyResponse:
            "天気データが取得できませんでした。"
        case .locationPermissionDenied:
            "位置情報の利用が許可されていません。"
        }
    }
}

public enum WeatherCodeMapper {
    public static func description(for code: Int) -> String {
        switch code {
        case 0:
            return "快晴"
        case 1, 2:
            return "晴れ"
        case 3:
            return "くもり"
        case 45, 48:
            return "霧"
        case 51, 53, 55, 56, 57:
            return "霧雨"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "雨"
        case 71, 73, 75, 77, 85, 86:
            return "雪"
        case 95, 96, 99:
            return "雷雨"
        default:
            return "不明"
        }
    }

    public static func systemImage(for code: Int) -> String {
        switch code {
        case 0:
            return "sun.max.fill"
        case 1, 2:
            return "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82:
            return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}
