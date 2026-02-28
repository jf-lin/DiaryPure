import Foundation
import SwiftData

enum AgreementStatus: String, Codable {
    case draft
    case pendingPartner
    case signed
    case cancelled
}

enum AgreementLanguage: String, Codable, CaseIterable {
    case en
    case zh

    var displayName: String {
        switch self {
        case .en: "English"
        case .zh: "中文"
        }
    }
}

enum AgreementRole: String, Codable {
    case creator
    case partner
}

@Model
final class ConsentAgreement {
    var id: UUID
    var creatorName: String
    var partnerName: String
    var agreementText: String
    var language: AgreementLanguage
    var role: AgreementRole
    var creatorSignature: Data?
    var partnerSignature: Data?
    var status: AgreementStatus
    var signedAt: Date?
    var createdAt: Date

    init(
        creatorName: String,
        partnerName: String,
        agreementText: String,
        language: AgreementLanguage = .en,
        role: AgreementRole = .creator
    ) {
        self.id = UUID()
        self.creatorName = creatorName
        self.partnerName = partnerName
        self.agreementText = agreementText
        self.language = language
        self.role = role
        self.status = .draft
        self.createdAt = Date()
    }

    var isSigned: Bool {
        status == .signed
    }
}
