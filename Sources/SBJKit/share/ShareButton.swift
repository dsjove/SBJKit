#if !os(watchOS)
import SwiftUI

public struct ShareButton: View {
	let items: ()->(activityItems: [Any], applicationActivities: [UIActivity]?)
	let appear: (()->())?
	let dismissed: (()->())?

	@State private var showingShareSheet = false

	public init(
		items: @escaping () -> (activityItems: [Any], applicationActivities: [UIActivity]?),
		appear: (()->())? = nil,
		dismissed: (()->())? = nil) {
		self.items = items
		self.appear = appear
		self.dismissed = dismissed
	}

	public var body: some View {
		ActionButton("Share", image: .system("square.and.arrow.up")) {
			appear?()
			self.showingShareSheet.toggle()
		}
		//TODO: if button is transitory this will never show
		.sheet(isPresented: $showingShareSheet) {
			let p = items()
			ShareSheet(activityItems: p.activityItems, applicationActivities: p.applicationActivities, dismissed: dismissed)
		}
	}
}
#endif
