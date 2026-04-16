import SwiftData
import SwiftUI
import WeatherDataMVVM
import WeatherDomainMVVM

public struct WeatherAppRootView: View {
    @StateObject private var viewModel: WeatherViewModel

    public init(modelContext: ModelContext) {
        _viewModel = StateObject(
            wrappedValue: WeatherViewModel(
                weatherService: OpenMeteoWeatherService(),
                locationService: LiveUserLocationService(),
                favoritesRepository: SwiftDataFavoritesRepository(context: modelContext)
            )
        )
    }

    public var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            WeatherHomeView(viewModel: viewModel)
                .navigationDestination(for: WeatherRoute.self) { route in
                    switch route {
                    case .forecast(let forecast):
                        WeatherForecastView(viewModel: viewModel, forecast: forecast)
                    case .dailyDetail(_, let day):
                        DailyForecastDetailView(day: day)
                    }
                }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("閉じる", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
