import Foundation

enum SignatureStore {
    private static let key = "savedSignature"

    static func save(data: Data) {
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> Data? {
        UserDefaults.standard.data(forKey: key)
    }

    static func delete() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
