import Charts
import SwiftData
import SwiftUI

struct DiaryInsightsView: View {
    @Query(sort: \DiaryEntry.createdAt, order: .reverse) private var allEntries: [DiaryEntry]

    private var moodCounts: [(mood: String, count: Int)] {
        let grouped = Dictionary(grouping: allEntries, by: { $0.mood })
        return grouped.map { (mood: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var last30Days: [DiaryEntry] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return allEntries.filter { $0.createdAt >= thirtyDaysAgo }
    }

    private var entriesPerWeek: [(week: String, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: last30Days) { entry in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.createdAt)
        }
        return grouped.map { components, entries in
            let weekStart = calendar.date(from: components) ?? Date()
            return (week: weekStart.formatted(.dateTime.month().day()), count: entries.count)
        }.sorted { $0.week < $1.week }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Entries")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(allEntries.count)")
                            .font(.system(size: 48, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }

                if !moodCounts.isEmpty {
                    Section("Most Used Moods") {
                        ForEach(moodCounts.prefix(5), id: \.mood) { item in
                            HStack {
                                Text(item.mood)
                                    .font(.title2)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !last30Days.isEmpty {
                    Section("Last 30 Days") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(last30Days.count) entries")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if #available(iOS 16.0, *), !entriesPerWeek.isEmpty {
                                Chart(entriesPerWeek, id: \.week) { item in
                                    BarMark(
                                        x: .value("Week", item.week),
                                        y: .value("Count", item.count)
                                    )
                                    .foregroundStyle(.tint)
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section("Streaks") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Current Streak")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(currentStreak) days")
                                .font(.title3.weight(.semibold))
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Longest Streak")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(longestStreak) days")
                                .font(.title3.weight(.semibold))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var currentStreak: Int {
        guard !allEntries.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for entry in allEntries {
            let entryDate = calendar.startOfDay(for: entry.createdAt)
            if calendar.isDate(entryDate, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if entryDate < checkDate {
                break
            }
        }
        return streak
    }

    private var longestStreak: Int {
        guard !allEntries.isEmpty else { return 0 }
        let calendar = Calendar.current
        var maxStreak = 0
        var currentStreak = 1

        for i in 0..<(allEntries.count - 1) {
            let current = calendar.startOfDay(for: allEntries[i].createdAt)
            let next = calendar.startOfDay(for: allEntries[i + 1].createdAt)

            if let daysBetween = calendar.dateComponents([.day], from: next, to: current).day,
               daysBetween == 1 {
                currentStreak += 1
            } else {
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 1
            }
        }
        return max(maxStreak, currentStreak)
    }
}
