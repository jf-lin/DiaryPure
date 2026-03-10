import SwiftData
import SwiftUI
import UIKit

struct DiaryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: DiaryEntry

    @State private var mood: String = ""
    @State private var noteAttributedText: NSAttributedString = NSAttributedString()
    @State private var photoData: Data?

    private let moods = ["😊", "😢", "😡", "😴", "🥰", "😰", "🤔", "🎉",
                         "😌", "🥺", "💪", "🌸", "☀️", "🌧️", "❤️", "💔"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)

    var body: some View {
        VStack(spacing: 16) {
            // Large mood display
            Text(mood)
                .font(.system(size: 64))
                .padding(.top, 8)

            // Timestamp
            Text(entry.createdAt, format: .dateTime.weekday(.wide).month(.abbreviated).day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)

            // Mood picker grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(moods, id: \.self) { m in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { mood = m }
                    } label: {
                        Text(m)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background {
                                if mood == m {
                                    Circle().fill(Color.accentColor.opacity(0.2))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // Note navigation link
            NavigationLink {
                DiaryNoteView(attributedText: $noteAttributedText)
            } label: {
                HStack {
                    if noteAttributedText.length == 0 {
                        Text("Add a note...")
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(noteAttributedText.string)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            DiaryPhotoPickerView(photoData: $photoData)
                .padding(.horizontal)

            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    entry.mood = mood
                    entry.attributedContent = noteAttributedText
                    entry.photoData = photoData
                    entry.updatedAt = Date()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .navigationTitle("Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            mood = entry.mood
            noteAttributedText = entry.attributedContent
            photoData = entry.photoData
        }
    }
}
