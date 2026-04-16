import SwiftUI
import WeatherDomainMVVM

struct WeatherHomeView: View {
    @ObservedObject var viewModel: WeatherViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                favoritesSection
                searchSection
            }
            .padding(20)
        }
        .navigationTitle("Weather")
    }

    private var header: some View {
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

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("お気に入り")
                .font(.headline)

            if viewModel.favorites.isEmpty {
                Text("まだ保存された地点はありません。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.favorites, id: \.id) { favorite in
                    favoriteRow(for: favorite)
                }
            }
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("地名検索")
                .font(.headline)

            TextField("Tokyo, Osaka, Sapporo ...", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)

            if viewModel.isSearching {
                ProgressView("検索中…")
            }

            ForEach(viewModel.searchResults, id: \.id) { location in
                searchResultRow(for: location)
            }
        }
    }

    private func favoriteRow(for favorite: LocationSearchResult) -> some View {
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

    private func searchResultRow(for location: LocationSearchResult) -> some View {
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
