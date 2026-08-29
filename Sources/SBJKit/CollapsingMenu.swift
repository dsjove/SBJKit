import SwiftUI

@available(iOS 18.0, *)
public struct CollapsingMenu<Content: View>: View {
	let title: LocalizedStringKey
	let systemImage: String
	@ViewBuilder let content: () -> Content

	public init(
		_ title: LocalizedStringKey,
		systemImage: String,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.title = title
		self.systemImage = systemImage
		self.content = content
	}

	public var body: some View {
		Group(subviews: content()) { subviews in
			if subviews.count == 1 {
				subviews[0]
			} else if !subviews.isEmpty {
				Menu(title, systemImage: systemImage) {
					ForEach(subviews) { subview in
						subview
					}
				}
				.menuOrder(.fixed)
			}
		}
	}
}
