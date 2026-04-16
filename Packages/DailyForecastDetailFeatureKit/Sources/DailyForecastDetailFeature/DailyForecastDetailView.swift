import SwiftUI
import WeatherDomain

public struct DailyForecastDetailView: View {
    @State private var viewModel: DailyForecastDetailViewModel

    public init(viewModel: DailyForecastDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        let day = viewModel.day

        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: WeatherCodeMapper.systemImage(for: day.weatherCode))
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 8) {
                    Text(day.date.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(.title2.bold())
                    Text(WeatherCodeMapper.description(for: day.weatherCode))
                        .foregroundStyle(.secondary)
                }
            }

            DetailMetricView(title: "最高気温", value: "\(day.maxTemperature.formatted(.number.precision(.fractionLength(0))))°")
            DetailMetricView(title: "最低気温", value: "\(day.minTemperature.formatted(.number.precision(.fractionLength(0))))°")
            DetailMetricView(title: "降水確率", value: "\(day.precipitationProbabilityMax)%")

            Spacer()
        }
        .padding(24)
        .navigationTitle("詳細")
    }
}

private struct DetailMetricView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.title3.bold())
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}
