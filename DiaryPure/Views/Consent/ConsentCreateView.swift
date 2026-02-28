import SwiftData
import SwiftUI

struct ConsentCreateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var partnerName = ""
    @State private var agreementText = ""

    var body: some View {
        Form {
            Section("Partner") {
                TextField("Partner's name", text: $partnerName)
            }
            Section("Agreement") {
                TextEditor(text: $agreementText)
                    .frame(minHeight: 200)
            }
        }
        .navigationTitle("New Agreement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    let agreement = ConsentAgreement(
                        partnerName: partnerName,
                        agreementText: agreementText
                    )
                    modelContext.insert(agreement)
                    dismiss()
                }
                .disabled(partnerName.isEmpty || agreementText.isEmpty)
            }
        }
    }
}
