import Foundation
import SwiftData

enum AgreementStatus: String, Codable {
    case draft
    case signed
}

@Model
final class ConsentAgreement {
    var id: UUID
    var partnerName: String
    var agreementText: String
    var creatorSignature: Data?
    var partnerSignature: Data?
    var status: AgreementStatus
    var signedAt: Date?
    var createdAt: Date

    init(partnerName: String, agreementText: String) {
        self.id = UUID()
        self.partnerName = partnerName
        self.agreementText = agreementText
        self.status = .draft
        self.createdAt = Date()
    }

    var isSigned: Bool {
        status == .signed
    }
}
