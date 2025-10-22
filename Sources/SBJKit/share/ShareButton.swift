import SwiftUI

public struct ShareButton: View {
	let items: ()->(activityItems: [Any], applicationActivities: [UIActivity]?)

	@State private var showingShareSheet = false

	public init(items: @escaping () -> (activityItems: [Any], applicationActivities: [UIActivity]?)) {
		self.items = items
	}

	public var body: some View {
		ActionButton("Share", image: "square.and.arrow.up") {
			self.showingShareSheet.toggle()
		}
		.sheet(isPresented: $showingShareSheet) {
			let p = items()
			ShareSheet(activityItems: p.activityItems, applicationActivities: p.applicationActivities)
		}
	}
}
