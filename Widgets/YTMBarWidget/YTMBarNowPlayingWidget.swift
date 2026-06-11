import SwiftUI
import WidgetKit
import YTMBarShared

#if os(macOS)
import AppKit
#endif

struct YTMBarNowPlayingEntry: TimelineEntry {
    let date: Date
    let snapshot: NowPlayingSnapshot
}

struct YTMBarNowPlayingProvider: TimelineProvider {
    func placeholder(in context: Context) -> YTMBarNowPlayingEntry {
        YTMBarNowPlayingEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (YTMBarNowPlayingEntry) -> Void) {
        completion(YTMBarNowPlayingEntry(date: Date(), snapshot: NowPlayingSnapshotStore.shared.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<YTMBarNowPlayingEntry>) -> Void) {
        let snapshot = NowPlayingSnapshotStore.shared.load()
        let entry = YTMBarNowPlayingEntry(date: Date(), snapshot: snapshot)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)

        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct YTMBarNowPlayingWidget: Widget {
    let kind = "YTMBarNowPlayingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YTMBarNowPlayingProvider()) { entry in
            YTMBarNowPlayingWidgetView(entry: entry)
                .widgetURL(URL(string: "ytmbar://open"))
        }
        .configurationDisplayName("YTMBar")
        .description("Shows the current YouTube Music track.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct YTMBarNowPlayingWidgetView: View {
    let entry: YTMBarNowPlayingEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
                .containerBackground(.background, for: .widget)
        default:
            smallView
                .containerBackground(.background, for: .widget)
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 10) {
            artwork
                .frame(width: 54, height: 54)

            Spacer(minLength: 2)

            textBlock(titleLineLimit: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
    }

    private var mediumView: some View {
        HStack(spacing: 14) {
            artwork
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 7) {
                statusLabel
                textBlock(titleLineLimit: 2)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
    }

    private var textBlock: some View {
        textBlock(titleLineLimit: 1)
    }

    private func textBlock(titleLineLimit: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.snapshot.title)
                .font(.headline.weight(.semibold))
                .lineLimit(titleLineLimit)
                .multilineTextAlignment(.leading)

            Text(entry.snapshot.artist)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var statusLabel: some View {
        Text(entry.snapshot.isPlaying ? "PLAYING" : "PAUSED")
            .font(.caption2.weight(.bold))
            .foregroundStyle(entry.snapshot.isPlaying ? .green : .secondary)
    }

    private var artwork: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.16, blue: 0.22),
                            Color(red: 0.09, green: 0.10, blue: 0.13),
                            Color(red: 0.06, green: 0.42, blue: 0.52)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            artworkImage
                .clipShape(Circle())

            Circle()
                .stroke(.white.opacity(0.24), lineWidth: 1)
                .padding(16)

            Circle()
                .fill(.background)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(.primary.opacity(0.22), lineWidth: 1))
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(.primary.opacity(0.12), lineWidth: 1))
    }

    @ViewBuilder
    private var artworkImage: some View {
        if let image = loadArtworkImage() {
            image
                .resizable()
                .scaledToFill()
        } else {
            EmptyView()
        }
    }

    private func loadArtworkImage() -> Image? {
        guard let fileName = entry.snapshot.artworkFileName else {
            return nil
        }

        let url = SharedStorage.containerURL.appendingPathComponent(fileName, isDirectory: false)

        #if os(macOS)
        guard let nsImage = NSImage(contentsOf: url) else {
            return nil
        }

        return Image(nsImage: nsImage)
        #else
        return nil
        #endif
    }
}
