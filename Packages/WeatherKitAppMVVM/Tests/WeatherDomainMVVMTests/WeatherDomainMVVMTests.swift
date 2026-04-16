import Testing
@testable import WeatherDomainMVVM

struct WeatherDomainMVVMTests {
    @Test
    func weatherCodeMappingReturnsExpectedText() {
        #expect(WeatherCodeMapper.description(for: 0) == "快晴")
        #expect(WeatherCodeMapper.systemImage(for: 61) == "cloud.rain.fill")
    }
}
