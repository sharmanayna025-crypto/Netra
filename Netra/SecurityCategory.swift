import Foundation

struct SecurityCategory: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let score: Int
    let detail: String
}
