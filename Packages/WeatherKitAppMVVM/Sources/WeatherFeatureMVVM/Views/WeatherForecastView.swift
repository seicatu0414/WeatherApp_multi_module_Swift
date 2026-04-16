import SwiftUI
import WeatherDomainMVVM

struct WeatherForecastView: View {
    @ObservedObject var viewModel: WeatherViewModel
    let forecast: WeatherForecast

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                currentWeatherCard
                weeklySection
            }
            .padding(20)
        }
        .navigationTitle(forecast.location.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.saveCurrentLocationToFavorites()
                } label: {
                    Image(systemName: viewModel.isFavoriteCurrentLocation() ? "star.fill" : "star")
                }
            }
        }
    }

    private var currentWeatherCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日の天気")
                        .font(.headline)
                    Text(forecast.location.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: WeatherCodeMapper.systemImage(for: forecast.current.weatherCode))
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
            }

            Text("\(forecast.current.temperature.formatted(.number.precision(.fractionLength(0))))°")
                .font(.system(size: 52, weight: .bold, design: .rounded))

            Text(WeatherCodeMapper.description(for: forecast.current.weatherCode))
                .font(.title3.weight(.semibold))

            HStack {
                Label("体感 \(forecast.current.apparentTemperature.formatted(.number.precision(.fractionLength(0))))°", systemImage: "thermometer.medium")
                Spacer()
                Label("風速 \(forecast.current.windSpeed.formatted(.number.precision(.fractionLength(1)))) m/s", systemImage: "wind")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.85), Color.cyan.opacity(0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .foregroundStyle(.white)
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間天気")
                .font(.headline)

            ForEach(forecast.daily) { day in
                Button {
                    viewModel.openDailyForecast(day)
                } label: {
                    HStack(spacing: 14) {
                        Text(day.date.formatted(.dateTime.weekday(.abbreviated).day()))
                            .frame(width: 72, alignment: .leading)
                        Image(systemName: WeatherCodeMapper.systemImage(for: day.weatherCode))
                            .frame(width: 28)
                        Text(WeatherCodeMapper.description(for: day.weatherCode))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(day.maxTemperature.formatted(.number.precision(.fractionLength(0))))°")
                            .fontWeight(.semibold)
                        Text("\(day.minTemperature.formatted(.number.precision(.fractionLength(0))))°")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
