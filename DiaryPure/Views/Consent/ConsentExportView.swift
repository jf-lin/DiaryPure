import PDFKit
import SwiftUI

struct ConsentExportView: View {
    let agreement: ConsentAgreement
    @Environment(\.dismiss) private var dismiss
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
                    .disabled(!agreement.isSigned)
                } footer: {
                    if !agreement.isSigned {
                        Text("Agreement must be signed before exporting")
                    }
                }
            }
            .navigationTitle("Export Agreement")
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
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ConsentAgreement.pdf")
        try? pdfData.write(to: tempURL)
        exportURL = tempURL
        showShareSheet = true
    }

    private func generatePDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "DiaryPure",
            kCGPDFContextTitle: "Consent Agreement"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50
            let margin: CGFloat = 50
            let contentWidth = pageRect.width - 2 * margin

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            "Consent Agreement".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
            yPosition += 50

            // Date
            let dateText = "Created: \(agreement.createdAt.formatted(date: .long, time: .omitted))"
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            dateText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttrs)
            yPosition += 30

            if let signedAt = agreement.signedAt {
                let signedText = "Signed: \(signedAt.formatted(date: .long, time: .shortened))"
                signedText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttrs)
                yPosition += 30
            }

            if let expiresAt = agreement.expiresAt {
                let expiresText = "Expires: \(expiresAt.formatted(date: .long, time: .omitted))"
                expiresText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttrs)
                yPosition += 40
            } else {
                yPosition += 20
            }

            // Agreement text
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            let textRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 400)
            agreement.agreementText.draw(in: textRect, withAttributes: textAttrs)
            yPosition += 420

            // Signatures
            if let creatorSig = agreement.creatorSignature, let creatorImage = UIImage(data: creatorSig) {
                let sigLabel = "\(agreement.creatorName) (Creator)"
                sigLabel.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttrs)
                yPosition += 20
                creatorImage.draw(in: CGRect(x: margin, y: yPosition, width: 200, height: 80))
                yPosition += 100
            }

            if let partnerSig = agreement.partnerSignature, let partnerImage = UIImage(data: partnerSig) {
                let sigLabel = "\(agreement.partnerName) (Partner)"
                sigLabel.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttrs)
                yPosition += 20
                partnerImage.draw(in: CGRect(x: margin, y: yPosition, width: 200, height: 80))
            }
        }
    }
}
