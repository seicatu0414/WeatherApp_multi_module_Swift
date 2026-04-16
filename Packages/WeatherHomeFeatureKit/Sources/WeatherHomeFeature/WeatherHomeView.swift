import SwiftUI
import WeatherDomain

public struct WeatherHomeView: View {
    @State private var viewModel: WeatherHomeViewModel

    public init(viewModel: WeatherHomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(viewModel: viewModel)
                favoritesSection(viewModel: viewModel)
                searchSection(viewModel: viewModel)
            }
            .padding(20)
        }
        .navigationTitle("Weather")
    }

    private func header(viewModel: WeatherHomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("現在地または地名検索")
                .font(.title2.bold())

            Text("Open-Meteo で今日と週間天気を取得し、お気に入り地点を SwiftData に保存します。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                viewModel.loadCurrentLocation()
            } label: {
                Label("現在地の天気を見る", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoadingForecast)
        }
    }

    private func favoritesSection(viewModel: WeatherHomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("お気に入り")
                .font(.headline)

            if viewModel.favorites.isEmpty {
                Text("まだ保存された地点はありません。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.favorites, id: \.id) { favorite in
                    Button {
                        viewModel.selectFavorite(favorite)
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(favorite.name)
                                    .font(.body.bold())
                                Text(favorite.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func searchSection(viewModel: WeatherHomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("地名検索")
                .font(.headline)

            TextField("Tokyo, Osaka, Sapporo ...", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)

            if viewModel.isSearching {
                ProgressView("検索中…")
            }

            ForEach(viewModel.searchResults, id: \.id) { location in
                Button {
                    viewModel.selectLocation(location)
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name)
                                .font(.body.bold())
                            Text(location.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
