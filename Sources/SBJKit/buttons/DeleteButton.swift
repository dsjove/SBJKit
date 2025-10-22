import SwiftUI

public struct DeleteButton : View {
	let noun: String
	let extra: String
	let systemImage: String
	let action: () -> Void
	@State private var showingDeleteAlert = false

	public init(_ noun: String, _ extra: String = "", systemImage: String? = nil, action: @escaping () -> Void, showingDeleteAlert: Bool = false) {
		self.noun = noun
		self.extra = extra
		self.systemImage = systemImage ?? "trash"
		self.action = action
		self.showingDeleteAlert = showingDeleteAlert
	}

	public var body: some View {
		Button(role: .destructive) {
			showingDeleteAlert = true
		} label: {
			Label("Delete \(noun)", systemImage: systemImage)
		}
		.labelStyle(.iconOnly)
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
