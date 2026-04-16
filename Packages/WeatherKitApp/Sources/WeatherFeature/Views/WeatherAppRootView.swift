import SwiftData
import SwiftUI
import DailyForecastDetailFeature
import WeatherDomain
import WeatherForecastFeature
import WeatherHomeFeature

public struct WeatherAppRootView: View {
    @State private var viewModel: WeatherAppRootViewModel

    public init(modelContext: ModelContext) {
        _viewModel = State(initialValue: WeatherAppRootViewModel(modelContext: modelContext))
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $viewModel.navigationPath) {
            WeatherHomeView(viewModel: viewModel.homeViewModel)
                .navigationDestination(for: WeatherRoute.self) { route in
                    switch route {
                    case .forecast(let forecast):
                        WeatherForecastView(viewModel: viewModel.makeForecastViewModel(for: forecast))
                    case .dailyDetail(_, let day):
                        DailyForecastDetailView(viewModel: viewModel.makeDailyForecastDetailViewModel(for: day))
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
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("閉じる", role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
