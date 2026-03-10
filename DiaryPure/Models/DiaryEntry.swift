import Foundation
import SwiftData
import UIKit

@Model
final class DiaryEntry {
    var id: UUID
    @Attribute(originalName: "content") var contentPlain: String
    var contentRTF: Data?
    var mood: String
    var photoData: Data?
    var createdAt: Date
    var updatedAt: Date

    var attributedContent: NSAttributedString {
        get {
            guard let data = contentRTF else {
                return NSAttributedString(string: contentPlain)
            }
            return (try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )) ?? NSAttributedString(string: contentPlain)
        }
        set {
            contentPlain = newValue.string
            contentRTF = try? newValue.data(
                from: NSRange(location: 0, length: newValue.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
        }
    }

    init(mood: String, content: String = "") {
        self.id = UUID()
        self.mood = mood
        self.contentPlain = content
        self.contentRTF = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
