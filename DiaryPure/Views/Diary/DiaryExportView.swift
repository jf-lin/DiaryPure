import PDFKit
import SwiftUI

struct DiaryExportView: View {
    let entries: [DiaryEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        exportAsPDF()
                    } label: {
                        Label("Export as PDF", systemImage: "doc.fill")
                    }

                    Button {
                        exportAsText()
                    } label: {
                        Label("Export as Text", systemImage: "doc.text.fill")
                    }
                } header: {
                    Text("Export \(entries.count) \(entries.count == 1 ? "entry" : "entries")")
                }
            }
            .navigationTitle("Export Diary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportAsPDF() {
        let pdfData = generatePDF()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("DiaryExport.pdf")
        try? pdfData.write(to: tempURL)
        exportURL = tempURL
        showShareSheet = true
    }

    private func exportAsText() {
        let text = entries.map { entry in
            """
            \(entry.createdAt.formatted(date: .long, time: .shortened))
            Mood: \(entry.mood)

            \(entry.contentPlain)

            ---
            """
        }.joined(separator: "\n\n")

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("DiaryExport.txt")
        try? text.write(to: tempURL, atomically: true, encoding: .utf8)
        exportURL = tempURL
        showShareSheet = true
    }

    private func generatePDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "DiaryPure",
            kCGPDFContextTitle: "Diary Export"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            for (index, entry) in entries.enumerated() {
                context.beginPage()

                var yPosition: CGFloat = 50
                let margin: CGFloat = 50
                let contentWidth = pageRect.width - 2 * margin

                // Date
                let dateText = entry.createdAt.formatted(date: .long, time: .shortened)
                let dateAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor.gray
                ]
                dateText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttrs)
                yPosition += 30

                // Mood
                let moodAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 48)
                ]
                entry.mood.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: moodAttrs)
                yPosition += 70

                // Content
                let contentAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
                let contentRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: pageRect.height - yPosition - margin)
                entry.contentPlain.draw(in: contentRect, withAttributes: contentAttrs)
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
