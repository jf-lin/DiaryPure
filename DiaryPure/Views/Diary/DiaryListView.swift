import SwiftData
import SwiftUI

struct DiaryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiaryEntry.createdAt, order: .reverse) private var entries: [DiaryEntry]

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.mood)
                            if !entry.contentPlain.isEmpty {
                                Text(entry.contentPlain)
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                        }
                        Text(entry.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries",
                        systemImage: "book",
                        description: Text("No diary entries yet.")
                    )
                }
            }
            .navigationTitle("Diary")
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}
