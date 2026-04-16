import Testing
@testable import WeatherDomain

struct WeatherDomainTests {
    @Test
    func weatherCodeMappingReturnsExpectedText() {
        #expect(WeatherCodeMapper.description(for: 0) == "快晴")
        #expect(WeatherCodeMapper.systemImage(for: 61) == "cloud.rain.fill")
    }

    @Test
    func locationSubtitleJoinsAvailableParts() {
        let withAdmin = LocationSearchResult(
            id: "tokyo",
            name: "Tokyo",
            admin1: "Tokyo",
            country: "Japan",
            coordinate: Coordinate(latitude: 35.68, longitude: 139.76)
        )
        let withoutAdmin = LocationSearchResult(
            id: "naha",
            name: "Naha",
            admin1: nil,
            country: "Japan",
            coordinate: Coordinate(latitude: 26.21, longitude: 127.68)
        )

        #expect(withAdmin.subtitle == "Tokyo, Japan")
        #expect(withoutAdmin.subtitle == "Japan")
    }

    @Test
    func favoriteLocationRoundTripsToSearchResult() {
        let location = LocationSearchResult(
            id: "sapporo",
            name: "Sapporo",
            admin1: "Hokkaido",
            country: "Japan",
            coordinate: Coordinate(latitude: 43.06, longitude: 141.35)
        )

        let favorite = FavoriteLocation(location: location)

        #expect(favorite.key == location.id)
        #expect(favorite.searchResult == location)
    }

    @Test
    func weatherErrorDescriptionsMatchExpectedMessages() {
        #expect(WeatherError.invalidLocation.errorDescription == "位置情報の取得に失敗しました。")
        #expect(WeatherError.missingCurrentForecast.errorDescription == "保存対象の天気情報がありません。")
        #expect(WeatherError.emptyResponse.errorDescription == "天気データが取得できませんでした。")
        #expect(WeatherError.locationPermissionDenied.errorDescription == "位置情報の利用が許可されていません。")
    }

    @Test
    func weatherForecastUsesLocationIdentifierAsId() {
        let location = LocationSearchResult(
            id: "kyoto",
            name: "Kyoto",
            admin1: "Kyoto",
            country: "Japan",
            coordinate: Coordinate(latitude: 35.01, longitude: 135.76)
        )
        let forecast = WeatherForecast(
            location: location,
            timezone: "Asia/Tokyo",
            current: CurrentWeather(temperature: 20, weatherCode: 0, windSpeed: 1, apparentTemperature: 19),
            daily: []
        )

        #expect(forecast.id == location.id)
    }
}
