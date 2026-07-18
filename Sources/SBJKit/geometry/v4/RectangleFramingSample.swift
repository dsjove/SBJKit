import SwiftUI

struct ImageZoomReset: AccessibleImage {
	var image: ImageName { .system("inset.filled.square.dashed") }
	var label: String { "Reset Zoom" }
}

struct ImageRotate: AccessibleImage {
	let clockwise: Bool
	var image: ImageName { .system(clockwise ? "rotate.right" :"rotate.left") }
	var label: String { clockwise ? "Rotate Clockwise" : "Rotate Counterclockwise" }
}

struct ImageMirror: AccessibleImage {
	let mirror: GeometricMirror
	var image: ImageName {
		let name = {
			if mirror.horizontalOnly {
				return "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right"
			}
			if !mirror.horizontal {
				if !mirror.vertical {
					return "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right"
				}
				return "arrow.trianglehead.up.and.down.righttriangle.up.righttriangle.down.fill"
			}
			if mirror.vertical {
				return "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right.fill"
			}
			return "arrow.trianglehead.up.and.down.righttriangle.up.righttriangle.down"
		}()
		return .system(name)
	}
	var label: String {
		if mirror.horizontalOnly {
			return "Flip"
		}
		if !mirror.horizontal {
			if !mirror.vertical {
				return "Flip Horizontal"
			}
			return "Reset Flip"
		}
		if mirror.vertical {
			return "Flip Vertical"
		}
		return "Flip Horizontal and Vertical"
	}
}

public struct RectangleFramingSample<Content: View>: View {
	let content: () -> Content

	@State var model: RectangleFraming
	@State var step: Int = 0
	let inc = 5
	let ns: UInt64 = 500_000_000

	let zoomEnabled: Bool = false
	let cropEnabled: Bool = false

	init(sourceSize: CGSize, content: @escaping () -> Content) {
		self.content = content
		let m = RectangleFraming(sourceSize: sourceSize)
//		m.magnify = 1.25
//		m.offset = .init(width: 0.25, height: 0.1)
		self._model = .init(initialValue: m)
	}

	public var body: some View {
		NavigationStack {
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
//				let degrees = Double(newValue * inc)
//				model.rotation = .degrees(degrees.truncatingRemainder(dividingBy: 360))
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItemGroup(placement: .topBarLeading) {
					ActionButton(ImageZoomReset()) {
						model.reset()
					}
					ActionButton(ImageMirror(mirror: model.mirror)) {
						model.flip()
					}
					ActionButton(ImageRotate(clockwise: true)) {
						model.rotate()
					}
					Text("\(step)")
				}
			}
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
