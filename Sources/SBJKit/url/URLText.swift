import SwiftUI

public struct URLText: View {
	public let name: String
	public let url: URL?

	public init(name: String, url: URL?) {
		self.name = name
		self.url = url
	}

	public var body: some View {
		if let url = url {
			let simpleName = name.isEmpty ? (url.host ?? url.absoluteString) : name
			if url.isValidURL {
				Link(simpleName, destination: url)
					.foregroundColor(.blue)
			}
			else {
				Text(simpleName)
			}
		} else if !name.isEmpty {
			Text(name)
		}
		else {
			EmptyView()
		}
	}
}
