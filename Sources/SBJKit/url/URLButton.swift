import SwiftUI

public struct URLButton: View {
	public let url: URL?

	public init(url: URL?) {
		self.url = url
	}

	public var body: some View {
		Button(action: {
			if let url = url, url.isValidURL {
				UIApplication.shared.open(url)
			}
		}) {
			if url?.absoluteString.isEmpty ?? true {
				Image(systemName: "xmark.circle.fill")
					.resizable()
					.foregroundStyle(.gray)
					.aspectRatio(1.0, contentMode: .fit)
					.frame(width: 24, height: 24)
			} else {
				Label("Link", systemImage: "link.circle")
					.imageScale(.large)
					.foregroundStyle(url?.isValidURL ?? false ? .blue : .red)
			}
		}
		.labelStyle(.iconOnly)
		.buttonStyle(.plain)
	}
}
