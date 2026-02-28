import SwiftData
import SwiftUI

struct DiaryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiaryEntry.createdAt, order: .reverse) private var entries: [DiaryEntry]
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    NavigationLink {
                        DiaryEditorView(entry: entry)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.title)
                                    .font(.headline)
                                if let mood = entry.mood, !mood.isEmpty {
                                    Text(mood)
                                }
                            }
                            Text(entry.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries",
                        systemImage: "book",
                        description: Text("Tap + to write your first diary entry.")
                    )
                }
            }
            .navigationTitle("Diary")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                NavigationStack {
                    DiaryEditorView(entry: nil)
                }
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}
