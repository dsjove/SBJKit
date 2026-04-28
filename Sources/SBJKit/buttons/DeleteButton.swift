import SwiftUI

public struct DeleteButton : View {
	let noun: String
	let accessibilityHint: String?
	let extra: String
	let image: ImageName
	let comfirm: Bool
	let action: () -> Void
	@State private var showingDeleteAlert = false

	public init(
			_ noun: String,
			_ extra: String = "",
			image: ImageName = .system("trash"),
			accessibilityHint: String? = nil,
			comfirm: Bool = true,
			action: @escaping () -> Void) {
		self.noun = noun
		self.accessibilityHint = accessibilityHint
		self.extra = extra
		self.image = image
		self.comfirm = comfirm
		self.action = action
	}

	public var body: some View {
		Button(role: .destructive) {
			if comfirm {
				showingDeleteAlert = true
			}
			else {
				action()
			}
		} label: {
			Label("Delete \(noun)", image: image)
		}
		.labelStyle(.iconOnly)
		.buttonStyle(.borderless)
		.accessibilityHint(accessibilityHint ?? "")
		.alert("Delete \(noun)", isPresented: $showingDeleteAlert, actions: {
			Button("Delete", role: .destructive) {
				action()
			}
			Button("Cancel", role: .cancel) {
			}
		}, message: {
			Text("Are you sure you want to delete this \(noun)? " + extra)
		})
	}
}
