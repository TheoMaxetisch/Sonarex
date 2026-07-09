import XCTest

final class SonarexAccessibilityTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launch()

        if #available(iOS 17.0, *) {
            var reportedIssues: [String] = []

            try app.performAccessibilityAudit { issue in
                let elementDescription = issue.element?.debugDescription ?? "Kein Element"
                reportedIssues.append(
                    """
                    Typ \(issue.auditType.rawValue): \(issue.compactDescription)
                    \(issue.detailedDescription)
                    \(elementDescription)
                    """
                )
                return true
            }

            if reportedIssues.isEmpty {
                let attachment = XCTAttachment(string: "Keine Accessibility-Probleme gefunden.")
                attachment.name = "Accessibility Audit"
                attachment.lifetime = .keepAlways
                add(attachment)
            } else {
                let attachment = XCTAttachment(string: reportedIssues.joined(separator: "\n\n"))
                attachment.name = "Accessibility Audit Findings"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        } else {
            throw XCTSkip("performAccessibilityAudit() ist erst ab iOS 17 verfuegbar.")
        }
    }
}
