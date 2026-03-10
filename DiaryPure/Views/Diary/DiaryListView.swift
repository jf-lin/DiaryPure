import SwiftData
import SwiftUI
import UIKit

struct DiaryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiaryEntry.createdAt, order: .reverse) private var entries: [DiaryEntry]

    @State private var searchText = ""
    @State private var entryToEdit: DiaryEntry?

    private var filteredEntries: [DiaryEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.mood.contains(searchText) ||
            $0.contentPlain.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredEntries) { entry in
                    Button {
                        entryToEdit = entry
                    } label: {
                        HStack(spacing: 12) {
                            if let photoData = entry.photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Text(entry.mood)
                                    .font(.title2)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                if !entry.contentPlain.isEmpty {
                                    Text(entry.contentPlain)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                                Text(entry.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteEntries)
            }
            .searchable(text: $searchText, prompt: "Search by mood or content")
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries",
                        systemImage: "book",
                        description: Text("No diary entries yet.")
                    )
                } else if filteredEntries.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("All Entries")
            .sheet(item: $entryToEdit) { entry in
                NavigationStack {
                    DiaryEditorView(entry: entry)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredEntries[index])
        }
    }
}
