import MessageUI
import SwiftUI

/// SwiftUI-Wrapper fuer den UIKit-Mailcomposer.
struct MailComposerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let recipient: String
    let subject: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        // MessageUI ist UIKit-basiert und wird ueber UIViewControllerRepresentable eingebunden.
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        // Der Coordinator uebernimmt Delegate-Callbacks aus UIKit.
        Coordinator(dismiss: dismiss)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismissAction: @MainActor @Sendable () -> Void

        init(dismiss: DismissAction) {
            self.dismissAction = { dismiss() }
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: (any Error)?
        ) {
            let dismissAction = dismissAction
            // Delegate-Callbacks koennen ausserhalb des SwiftUI-Kontexts eintreffen; Dismiss laeuft auf MainActor.
            Task { @MainActor in
                dismissAction()
            }
        }
    }
}
