import SwiftUI

public struct RectangleFramingSample<Content: View>: View {
	let content: () -> Content

	@State var model: RectangleFraming
	@State var step: Int = 0
	let inc = 5
	let ns: UInt64 = 500_000_000

	init(sourceSize: CGSize, content: @escaping () -> Content) {
		self.content = content
		let m = RectangleFraming(sourceSize: sourceSize)
//		m.magnify = 1.25
//		m.offset = .init(width: 0.25, height: 0.1)
		m.mirror = m.mirror.next.next.next
		self._model = .init(initialValue: m)
	}

	public var body: some View {
		RectangleFramingView(model: model) {
			ZStack {
				content()
					.rectangleFraming(model)
				RectangleFramingDiagram(model: model)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.task {
			while true {
				try? await Task.sleep(nanoseconds: ns)
				step = step + 1
			}
		}
		.onChange(of: step) { _, newValue in
			let degrees = Double(newValue * inc)
			model.rotation = .degrees(degrees.truncatingRemainder(dividingBy: 360))
		}
	}
}

#Preview("RectangleFramingSample Preview") {
	let configuration = UIImage.SymbolConfiguration(
		pointSize: 718,
		weight: .regular,
		scale: .large
	)

	let previewImage = UIImage(
		systemName: "photo.fill",
		withConfiguration: configuration
	)!
	RectangleFramingSample(sourceSize: previewImage.size) {
		Image(uiImage: previewImage).resizable().opacity(0.25)
	}
}
