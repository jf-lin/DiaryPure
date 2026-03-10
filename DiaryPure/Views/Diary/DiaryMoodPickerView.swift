import SwiftUI
import UIKit

struct DiaryMoodPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let onSave: (String, NSAttributedString, Data?) -> Void

    @State private var selectedMood: String?
    @State private var noteAttributedText: NSAttributedString = NSAttributedString()
    @State private var photoData: Data?

    private let moods = ["😊", "😢", "😡", "😴", "🥰", "😰", "🤔", "🎉",
                         "😌", "🥺", "💪", "🌸", "☀️", "🌧️", "❤️", "💔"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(spacing: 20) {
            Text("How are you feeling?")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(moods, id: \.self) { mood in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedMood = mood
                        }
                    } label: {
                        Text(mood)
                            .font(.largeTitle)
                            .frame(width: 56, height: 56)
                            .background {
                                if selectedMood == mood {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentColor.opacity(0.2))
                                }
                            }
                            .overlay {
                                if selectedMood == mood {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.accentColor, lineWidth: 2)
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
        .padding(.top, 20)
        .navigationTitle(date.formatted(.dateTime.month(.abbreviated).day()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let mood = selectedMood {
                        onSave(mood, noteAttributedText, photoData)
                        dismiss()
                    }
                }
                .disabled(selectedMood == nil)
                .fontWeight(.semibold)
            }
        }
    }
}
