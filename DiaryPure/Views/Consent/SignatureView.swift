import SwiftUI

struct SignatureView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (Data) -> Void

    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []

    var body: some View {
        NavigationStack {
            VStack {
                Text("Sign below")
                    .font(.headline)
                    .padding(.top)

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

                HStack {
                    Button("Clear") {
                        lines = []
                        currentLine = []
                    }
                    .foregroundStyle(.red)

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
                        if let data = renderSignature() {
                            onSave(data)
                        }
                        dismiss()
                    }
                    .disabled(lines.isEmpty)
                }
            }
        }
    }

    private func renderSignature() -> Data? {
        let renderer = ImageRenderer(content:
            Canvas { context, size in
                for line in lines {
                    guard line.count > 1 else { continue }
                    var path = Path()
                    path.addLines(line)
                    context.stroke(path, with: .color(.black), lineWidth: 2.5)
                }
            }
            .frame(width: 400, height: 200)
            .background(.white)
        )
        renderer.scale = 2.0
        return renderer.uiImage?.pngData()
    }
}
