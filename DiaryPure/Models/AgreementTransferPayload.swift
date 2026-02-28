import Foundation

struct AgreementTransferPayload: Codable {
    var agreementID: UUID
    var creatorName: String
    var partnerName: String
    var agreementText: String
    var language: AgreementLanguage
    var creatorSignature: Data?
    var partnerSignature: Data?
    var status: AgreementStatus
    var createdAt: Date
    var signedAt: Date?

    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decoded(from data: Data) -> AgreementTransferPayload? {
        try? JSONDecoder().decode(AgreementTransferPayload.self, from: data)
    }
}
