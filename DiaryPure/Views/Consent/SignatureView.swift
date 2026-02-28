import SwiftUI

struct SignatureView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (Data) -> Void

    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    @State private var savedImage: UIImage?
    @State private var showSavePrompt = false
    @State private var pendingData: Data?

    private var hasSavedSignature: Bool {
        SignatureStore.load() != nil
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text("Sign below")
                    .font(.headline)
                    .padding(.top)

                if let savedImage {
                    Image(uiImage: savedImage)
                        .resizable()
                        .scaledToFit()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                } else {
                    Canvas { context, size in
                        for line in lines + [currentLine] {
                            guard line.count > 1 else { continue }
                            var path = Path()
                            path.addLines(line)
                            context.stroke(path, with: .color(.primary), lineWidth: 2.5)
                        }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                currentLine.append(value.location)
                            }
                            .onEnded { _ in
                                lines.append(currentLine)
                                currentLine = []
                            }
                    )
                    .padding()
                }

                HStack(spacing: 16) {
                    Button("Clear") {
                        lines = []
                        currentLine = []
                        savedImage = nil
                    }
                    .foregroundStyle(.red)

                    if hasSavedSignature {
                        Button {
                            if let data = SignatureStore.load(),
                               let img = UIImage(data: data) {
                                savedImage = img
                                lines = []
                            }
                        } label: {
                            Label("Use Saved", systemImage: "signature")
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        guard let data = renderSignature() else { return }
                        if savedImage != nil {
                            // Used saved signature, skip save prompt
                            onSave(data)
                            dismiss()
                        } else {
                            pendingData = data
                            showSavePrompt = true
                        }
                    }
                    .disabled(lines.isEmpty && savedImage == nil)
                }
            }
            .alert("Save as your signature?", isPresented: $showSavePrompt) {
                Button("Save") {
                    if let pendingData {
                        SignatureStore.save(data: pendingData)
                        onSave(pendingData)
                    }
                    dismiss()
                }
                Button("Skip", role: .cancel) {
                    if let pendingData {
                        onSave(pendingData)
                    }
                    dismiss()
                }
            } message: {
                Text("You can reuse this signature for future agreements.")
            }
        }
    }

    private func renderSignature() -> Data? {
        if let savedImage {
            return savedImage.pngData()
        }

        let allPoints = lines.flatMap { $0 }
        guard !allPoints.isEmpty else { return nil }

        let minX = allPoints.map(\.x).min()!
        let maxX = allPoints.map(\.x).max()!
        let minY = allPoints.map(\.y).min()!
        let maxY = allPoints.map(\.y).max()!

        let padding: CGFloat = 16
        let width = (maxX - minX) + padding * 2
        let height = (maxY - minY) + padding * 2

        let offsetLines = lines.map { line in
            line.map { CGPoint(x: $0.x - minX + padding, y: $0.y - minY + padding) }
        }

        let renderer = ImageRenderer(content:
            Canvas { context, size in
                for line in offsetLines {
                    guard line.count > 1 else { continue }
                    var path = Path()
                    path.addLines(line)
                    context.stroke(path, with: .color(.black), lineWidth: 2.5)
                }
            }
            .frame(width: width, height: height)
            .background(.white)
        )
        renderer.scale = 2.0
        return renderer.uiImage?.pngData()
    }
}
