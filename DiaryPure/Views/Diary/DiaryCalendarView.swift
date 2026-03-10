import SwiftData
import SwiftUI
import UIKit

struct DiaryCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiaryEntry.createdAt) private var allEntries: [DiaryEntry]

    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showingMoodPicker = false
    @State private var entryToEdit: DiaryEntry?
    @State private var showingExport = false
    @State private var showingInsights = false

    private let calendar = Calendar.current
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                weekdayHeader
                calendarGrid
                Divider()
                dayDetailSection
            }
            .navigationTitle("Diary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingInsights = true
                        } label: {
                            Label("Insights", systemImage: "chart.bar.fill")
                        }
                        Button {
                            showingExport = true
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .disabled(allEntries.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingMoodPicker) {
                NavigationStack {
                    DiaryMoodPickerView(date: selectedDate ?? Date()) { mood, attrText, photoData in
                        let entry = DiaryEntry(mood: mood)
                        entry.attributedContent = attrText
                        entry.photoData = photoData
                        if let date = selectedDate {
                            entry.createdAt = calendar.date(bySettingHour: calendar.component(.hour, from: Date()),
                                                            minute: calendar.component(.minute, from: Date()),
                                                            second: 0, of: date) ?? date
                        }
                        modelContext.insert(entry)
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $entryToEdit) { entry in
                NavigationStack {
                    DiaryEditorView(entry: entry)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingExport) {
                DiaryExportView(entries: allEntries)
            }
            .sheet(isPresented: $showingInsights) {
                DiaryInsightsView()
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation { changeMonth(by: -1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            Spacer()
            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.title2.weight(.bold))
            Spacer()
            Button {
                withAnimation { changeMonth(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .frame(height: 52)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let dayEntries = entries(for: date)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.callout.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : isToday ? .accentColor : .primary)
                    .frame(width: 28, height: 28)
                    .background {
                        if isSelected {
                            Circle().fill(Color.accentColor)
                        } else if isToday {
                            Circle().strokeBorder(Color.accentColor, lineWidth: 1.5)
                        }
                    }

                // Emoji dots
                if !dayEntries.isEmpty {
                    HStack(spacing: 1) {
                        ForEach(dayEntries.prefix(3)) { entry in
                            Text(entry.mood)
                                .font(.system(size: 8))
                        }
                        if dayEntries.count > 3 {
                            Text("+")
                                .font(.system(size: 7))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 12)
                } else {
                    Spacer().frame(height: 12)
                }
            }
            .frame(height: 52)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day Detail Section

    @ViewBuilder
    private var dayDetailSection: some View {
        if let selectedDate {
            let dayEntries = entries(for: selectedDate)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(selectedDate, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                        .font(.headline)
                    Spacer()
                    if calendar.compare(selectedDate, to: Date(), toGranularity: .day) != .orderedDescending {
                        Button {
                            showingMoodPicker = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                if dayEntries.isEmpty {
                    Text(calendar.isDateInToday(selectedDate) ? "No entries yet. Tap + to add one!" : "No entries for this day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    List {
                        ForEach(dayEntries) { entry in
                            entryRow(entry)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(dayEntries[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxHeight: .infinity)
        } else {
            VStack(spacing: 8) {
                Text("Select a day to view entries")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }

    private func entryRow(_ entry: DiaryEntry) -> some View {
        Button {
            entryToEdit = entry
        } label: {
            HStack(spacing: 12) {
                Text(entry.mood)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    if !entry.contentPlain.isEmpty {
                        Text(entry.contentPlain)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    Text(entry.createdAt, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
            selectedDate = nil
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let weekdayOfFirst = calendar.component(.weekday, from: firstDay) - 1 // 0-indexed, Sun=0

        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    private func entries(for date: Date) -> [DiaryEntry] {
        allEntries.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }
}
