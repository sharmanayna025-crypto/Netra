//
//  SafariWebExtensionHandler.swift
//  NetraExtension
//
//  Receives scan reports from the extension's background script and stores
//  them in the shared App Group container for the Netra app.
//

import SafariServices
import os.log

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private let logger = Logger(
        subsystem: "com.nvs.Netra.SafariExtension",
        category: "native"
    )

    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey]

        var reply: [String: Any] = ["ok": false]

        if let body = message as? [String: Any],
           body["type"] as? String == "siteScan",
           let scanObject = body["scan"] as? [String: Any] {
            reply = handleSiteScan(scanObject)
        }

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: reply]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

    // MARK: - Site scan

    private func handleSiteScan(_ object: [String: Any]) -> [String: Any] {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object),
              let payload = try? JSONDecoder().decode(ScanPayload.self, from: data),
              let scan = payload.makeScan()
        else {
            logger.error("Rejected malformed scan payload")
            return ["ok": false, "error": "invalid_payload"]
        }

        do {
            try ScanStore.shared.record(scan)
            // Log counts only — never hostnames.
            logger.debug("Stored scan with \(scan.trackers.count) trackers")
            return ["ok": true]
        } catch {
            logger.error("Could not store scan: \(error.localizedDescription)")
            return ["ok": false, "error": "store_failed"]
        }
    }
}
