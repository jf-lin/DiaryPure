import SwiftData
import SwiftUI

struct DiaryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: DiaryEntry?

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var mood: String = ""

    private let moods = ["", "😊", "😢", "😡", "😴", "🥰", "😰", "🤔"]

    private var isNew: Bool { entry == nil }

    var body: some View {
        Form {
            Section("Title") {
                TextField("What happened today?", text: $title)
            }
            Section("Mood") {
                Picker("Mood", selection: $mood) {
                    ForEach(moods, id: \.self) { m in
                        Text(m.isEmpty ? "None" : m).tag(m)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Entry") {
                TextEditor(text: $content)
                    .frame(minHeight: 200)
            }
        }
        .navigationTitle(isNew ? "New Entry" : "Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if isNew {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
        .onAppear {
            if let entry {
                title = entry.title
                content = entry.content
                mood = entry.mood ?? ""
            }
        }
    }

    private func save() {
        if let entry {
            entry.title = title
            entry.content = content
            entry.mood = mood.isEmpty ? nil : mood
            entry.updatedAt = Date()
        } else {
            let newEntry = DiaryEntry(
                title: title,
                content: content,
                mood: mood.isEmpty ? nil : mood
            )
            modelContext.insert(newEntry)
        }
    }
}
