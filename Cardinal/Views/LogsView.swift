import SwiftUI

struct LogsView: View {
    let ownerId: String

    @State private var events: [AnalyticsEvent] = []
    @State private var nextCursor: String? = nil
    @State private var isLoading: Bool = false
    @State private var isInitialLoaded: Bool = false
    @State private var refreshTask: Task<Void, Never>?
    @State private var stats: AnalyticsStats? = nil
    @State private var isLoadingStats: Bool = false
    
    // Loading states for the loading screen
    @State private var isLoadingAnalytics = true
    @State private var isLoadingEvents = true
    
    private var isDataLoading: Bool {
        isLoadingAnalytics || isLoadingEvents
    }

    private let pageSize: Int = 30
    private let loadMoreThreshold: Int = 5

    private var uniqueVisitorsCount: Int {
        stats?.uniqueVisitors ?? 0
    }
    
    private var totalActionsCount: Int {
        stats?.totalActions ?? 0
    }

    // Cached date formatters
    static let isoWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    static let isoBasic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    static let displayDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "MMM d, yyyy - HH:mm"
        return df
    }()

    var body: some View {
        Group {
            if isDataLoading {
                VStack(spacing: 8) {
                    Spacer()
                    
                    Image("CardinalLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .scaleEffect(isDataLoading ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isDataLoading)
                    
                    Text("Loading...")
                        .font(.custom("MabryPro-BlackItalic", size: 20))
                        .foregroundColor(Color("TextPrimary"))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BackgroundPrimary"))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("ACTIVITY LOG")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(Color("TextPrimary"))
                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(uniqueVisitorsCount)")
                            .font(.custom("MabryPro-Black", size: 28))
                            .foregroundColor(Color("TextPrimary"))
                        Text("UNIQUE VISITORS")
                            .font(.custom("MabryPro-Medium", size: 16))
                            .foregroundColor(Color("TextPrimary"))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(totalActionsCount)")
                            .font(.custom("MabryPro-Black", size: 28))
                            .foregroundColor(Color("TextPrimary"))
                        Text("TOTAL INTERACTIONS")
                            .font(.custom("MabryPro-Medium", size: 16))
                            .foregroundColor(Color("TextPrimary"))
                            .fixedSize(horizontal: true, vertical: false)
                        }
                }
            Rectangle()
                .fill(Color.black)
                .frame(height: 2)
            }
            ScrollView {
                if events.isEmpty && isInitialLoaded {
                    VStack {
                        Text("No interactions yet.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer(minLength: 200)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
                } else {
                    LazyVStack(alignment: .leading, spacing: 16, pinnedViews: []) {
                        ForEach(events) { event in
                            ReusableLogRowView(
                                actionType: event.action,
                                formattedTime: formattedTimestamp(for: event),
                                userName: event.visitorName,
                                link: event.meta?["url"],
                                shouldTruncate: false
                            )
                            Rectangle()
                                .fill(Color.black.opacity(0.3))
                                .frame(height: 1)
                            .onAppear {
                                loadMoreIfNeeded(currentItem: event)
                            }
                        }
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 24)
                }
            }
            .background(Color("BackgroundPrimary"))
            .refreshable {
                await refresh()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
                .background(Color("BackgroundPrimary"))
            }
        }
        .task {
            if !isInitialLoaded {
                await initialLoad()
            }
        }
    }

    private func initialLoad() async {
        // Fetch stats and initial events concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchStats()
                self.isLoadingAnalytics = false
            }
            group.addTask {
                await self.fetchNext(reset: true)
                self.isLoadingEvents = false
            }
        }
        isInitialLoaded = true
    }

    private func loadMoreIfNeeded(currentItem item: AnalyticsEvent) {
        guard !isLoading else { return }
        guard nextCursor != nil else { return }
        
        // Load more when we're within threshold of the end
        let thresholdIndex = events.count - loadMoreThreshold
        guard let itemIndex = events.firstIndex(where: { $0.id == item.id }),
              itemIndex >= thresholdIndex else { return }
        
        Task { await fetchNext(reset: false) }
    }

    private func fetchStats() async {
        if isLoadingStats { return }
        isLoadingStats = true
        defer { isLoadingStats = false }
        
        do {
            // Use the existing fetchAnalytics method to get stats
            let url = URL(string: "https://us-central1-cardinalapp-4279c.cloudfunctions.net/getAnalytics")!
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comps?.queryItems = [URLQueryItem(name: "ownerId", value: ownerId)]
            guard let finalUrl = comps?.url else { return }
            
            let (data, response) = try await URLSession.shared.data(from: finalUrl)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
            let decoded = try JSONDecoder().decode(GetAnalyticsResponse.self, from: data)
            
            await MainActor.run {
                self.stats = decoded.stats
            }
        } catch {
            // Silently fail for now
            print("Failed to fetch stats: \(error)")
        }
    }
    
    private func refresh() async {
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        refreshTask = Task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await self.fetchStats()
                    }
                    group.addTask {
                        try? await self.refreshEvents()
                    }
                }
        }
        
        await refreshTask?.value
    }
    
    private func refreshEvents() async throws {
        // Always start from beginning for refresh
        let page = try await AnalyticsManager.shared.fetchAnalyticsPage(ownerId: ownerId, pageSize: pageSize, startAfterId: nil)
        
        guard !Task.isCancelled else { return }
        
        await MainActor.run {
            events = page.events
            nextCursor = page.nextCursor
        }
    }

    private func fetchNext(reset: Bool) async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let cursor = reset ? nil : nextCursor
            let page = try await AnalyticsManager.shared.fetchAnalyticsPage(ownerId: ownerId, pageSize: pageSize, startAfterId: cursor)
            await MainActor.run {
                if reset {
                    events = page.events
                } else {
                    // Avoid duplicates if refresh races
                    let existingIds = Set(events.map { $0.id })
                    let newOnes = page.events.filter { !existingIds.contains($0.id) }
                    events.append(contentsOf: newOnes)
                }
                nextCursor = page.nextCursor
            }
        } catch {
            // Silently fail for now
        }
    }
    
    private func formattedTimestamp(for event: AnalyticsEvent) -> String {
        var parsedDate = LogsView.isoWithFractionalSeconds.date(from: event.timestamp)
            ?? LogsView.isoBasic.date(from: event.timestamp)
        if parsedDate == nil, let numeric = Double(event.timestamp) {
            parsedDate = event.timestamp.count > 11
                ? Date(timeIntervalSince1970: numeric / 1000.0)
                : Date(timeIntervalSince1970: numeric)
        }
        return LogsView.displayDateFormatter.string(from: parsedDate ?? Date())
    }
}
