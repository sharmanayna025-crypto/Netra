//
//  ActivityEventModel.swift
//  Netra
//
//  Persistent security activity (previously an in-memory singleton that was
//  lost every time the app closed).
//

import Foundation
import SwiftData

@Model
final class ActivityEventModel {

    var id: UUID
    var icon: String
    var title: String
    var detail: String
    var date: Date

    init(icon: String, title: String, detail: String, date: Date = Date()) {
        self.id = UUID()
        self.icon = icon
        self.title = title
        self.detail = detail
        self.date = date
    }
}

enum ActivityLog {

    @MainActor
    static func record(
        in context: ModelContext,
        icon: String,
        title: String,
        detail: String
    ) {
        context.insert(ActivityEventModel(icon: icon, title: title, detail: detail))
    }
}
