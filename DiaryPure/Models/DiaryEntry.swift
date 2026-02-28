import Foundation
import SwiftData

@Model
final class DiaryEntry {
    var id: UUID
    var title: String
    var content: String
    var mood: String?
    var createdAt: Date
    var updatedAt: Date

    init(title: String, content: String, mood: String? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.mood = mood
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
