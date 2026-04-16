import Foundation
import SwiftData
import Testing
import WeatherDomain
@testable import WeatherData

struct WeatherDataTests {
    @Test
    func searchLocationsDecodesResponse() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString.contains("name=Tokyo") == true)

            return HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        }
        URLProtocolStub.data = {
            """
            {
              "results": [
                {
                  "id": 1850147,
                  "name": "Tokyo",
                  "latitude": 35.6895,
                  "longitude": 139.69171,
                  "admin1": "Tokyo",
                  "country": "Japan"
                }
              ]
            }
            """.data(using: .utf8)!
        }

        let service = OpenMeteoWeatherService(session: makeSession())
        let results = try await service.searchLocations(query: "Tokyo")

        #expect(results.count == 1)
        #expect(results[0].id == "1850147-35.6895-139.69171")
        #expect(results[0].subtitle == "Tokyo, Japan")
    }

    @Test
    func forecastDecodesCurrentAndDailyData() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.url?.absoluteString.contains("forecast?latitude=35.0&longitude=139.0") == true)

            return HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        }
        URLProtocolStub.data = {
            """
            {
              "timezone": "Asia/Tokyo",
              "current": {
                "temperature_2m": 21.5,
                "weather_code": 3,
                "wind_speed_10m": 4.2,
                "apparent_temperature": 22.0
              },
              "daily": {
                "time": ["2026-04-13"],
                "weather_code": [61],
                "temperature_2m_max": [24.0],
                "temperature_2m_min": [16.0],
                "precipitation_probability_max": [70]
              }
            }
            """.data(using: .utf8)!
        }

        let service = OpenMeteoWeatherService(session: makeSession())
        let location = LocationSearchResult(
            id: "tokyo",
            name: "Tokyo",
            admin1: "Tokyo",
            country: "Japan",
            coordinate: Coordinate(latitude: 35.0, longitude: 139.0)
        )

        let forecast = try await service.forecast(for: location)

        #expect(forecast.location == location)
        #expect(forecast.timezone == "Asia/Tokyo")
        #expect(forecast.current.weatherCode == 3)
        #expect(forecast.daily.count == 1)
        #expect(forecast.daily[0].precipitationProbabilityMax == 70)
    }

    @Test
    func forecastThrowsEmptyResponseWhenCurrentOrDailyIsMissing() async throws {
        URLProtocolStub.handler = { request in
            HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        }
        URLProtocolStub.data = {
            """
            {
              "timezone": "Asia/Tokyo",
              "current": null,
              "daily": null
            }
            """.data(using: .utf8)!
        }

        let service = OpenMeteoWeatherService(session: makeSession())
        let location = LocationSearchResult(
            id: "tokyo",
            name: "Tokyo",
            admin1: "Tokyo",
            country: "Japan",
            coordinate: Coordinate(latitude: 35.0, longitude: 139.0)
        )

        await #expect(throws: WeatherError.emptyResponse) {
            try await service.forecast(for: location)
        }
    }

    @Test
    @MainActor
    func favoritesRepositorySavesFetchesAndDeduplicatesFavorites() throws {
        let repository = try makeRepository()
        let first = makeLocation(id: "tokyo", createdAtOffset: 0)
        let second = makeLocation(id: "osaka", createdAtOffset: 1)

        try repository.save(first)
        try repository.save(first)
        try repository.save(second)

        let favorites = try repository.fetchFavorites()

        #expect(favorites.count == 2)
        #expect(favorites[0].id == second.id)
        #expect(favorites[1].id == first.id)
        #expect(try repository.isFavorite(first))
    }
}

private func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
}

@MainActor
private func makeRepository() throws -> SwiftDataFavoritesRepository {
    let schema = Schema([FavoriteLocation.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return SwiftDataFavoritesRepository(context: container.mainContext)
}

private func makeLocation(id: String, createdAtOffset: TimeInterval) -> LocationSearchResult {
    LocationSearchResult(
        id: id,
        name: id,
        admin1: "JP",
        country: "Japan",
        coordinate: Coordinate(latitude: 35 + createdAtOffset, longitude: 139 + createdAtOffset)
    )
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    static var handler: ((URLRequest) throws -> HTTPURLResponse)?
    static var data: (() -> Data)?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            let response = try Self.handler?(request)
            if let response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = Self.data?() {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
