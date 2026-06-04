#if !os(watchOS)
import SwiftUI

public typealias ShareItems = (activityItems: [Any], applicationActivities: [UIActivity]?)

public struct ShareButton: View {
	let noun: String
	let items: ()->ShareItems
	let appear: (()->())?
	let dismissed: (()->())?

	@State private var showingShareSheet = false

	public init(
		_ noun: String,
		items: @escaping ()->ShareItems,
		appear: (()->())? = nil,
		dismissed: (()->())? = nil) {
		self.noun = noun
		self.items = items
		self.appear = appear
		self.dismissed = dismissed
	}

	public var body: some View {
		ActionButton("Share \(noun)", image: .system("square.and.arrow.up")) {
			appear?()
			self.showingShareSheet.toggle()
		}
		//TODO: if button is transitory this will never show
		.sheet(isPresented: $showingShareSheet, onDismiss: {
			dismissed?()
		}) {
			let p = items()
			ShareSheet(activityItems: p.activityItems, applicationActivities: p.applicationActivities, dismissed: nil)
		}
	}
}
#endif
