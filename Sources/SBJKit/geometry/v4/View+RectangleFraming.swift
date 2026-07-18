import SwiftUI

public struct RectangleFramingModifier: ViewModifier {
    let model: RectangleFraming

    public func body(content: Content) -> some View {
		content
			.frame(width: model.positionedSize.width, height: model.positionedSize.height)
			.scaleEffect(x: model.mirror.horizontal ? -1 : 1, y: model.mirror.vertical ? -1 : 1)
			.scaleEffect(model.magnify)
			.rotationEffect(model.rotation)
			.offset(model.containedOffset)
    }
}

// Helper to center a known content size within the given container
private struct _CenterInContainer: ViewModifier {
    let containerSize: CGSize
    let contentSize: CGSize

    func body(content: Content) -> some View {
        let dx = (containerSize.width - contentSize.width) / 2
        let dy = (containerSize.height - contentSize.height) / 2
        return content
            .offset(x: dx, y: dy)
    }
}

public extension View {
	func rectangleFraming(_ model: RectangleFraming) -> some View {
		modifier(RectangleFramingModifier(model: model))
	}
}

public struct RectangleFramingView<Content: View>: View {
	let model: RectangleFraming
	let content: () -> Content

	public var body: some View {
		GeometryReader { proxy in
			Color.clear
				.overlay {
					content()
					.frame(
						width: proxy.size.width,
						height: proxy.size.height
					)
				}
				.onAppear {
					model.containerSize = proxy.size
				}
				.onChange(of: proxy.size) { _, newSize in
					model.containerSize = proxy.size
				}
		}
	}
}

public struct RectangleFramingDiagram: View {
	let model: RectangleFraming
	public var body: some View {
		ZStack {
			Color.gray.opacity(0.25).ignoresSafeArea()
			Rectangle()
				.stroke(Color.blue.opacity(1.0), lineWidth: 5)
				.frame(width: model.containerSize.width, height: model.containerSize.height)
			Rectangle()
				.stroke(Color.red.opacity(1.0), lineWidth: 3)
				.frame(width: model.frameSize.width, height: model.frameSize.height)
			Path { path in
				let pts = model.framePoints
				path.move(to: pts[0])
				for p in pts.dropFirst() {
					path.addLine(to: p)
				}
				path.closeSubpath()
				let bounds = path.boundingRect
				let point = pts[model.mirror.idx]
				let size = (model.frameSize.width + model.frameSize.height) / 20
				path.addEllipse(in: CGRect(
					origin: CGPoint(x: point.x - size/2, y: point.y - size/2),
					size: CGSize(width: size, height: size)))
				let offsetX = model.containerSize.width / 2 - bounds.midX
				let offsetY = model.containerSize.height / 2 - bounds.midY
				path = path.offsetBy(dx: offsetX, dy: offsetY)
			}
			.stroke(Color.green.opacity(0.9), style: StrokeStyle(lineWidth: 2))
			Path { path in
				let pts = model.positionedPoints
				guard pts.count == 4 else { return }

				path.move(to: pts[0])
				for p in pts.dropFirst() {
					path.addLine(to: p)
				}
				path.closeSubpath()
				let bounds = path.boundingRect
				let dragged = model.containedOffset
				let offsetX = model.containerSize.width / 2 - bounds.midX + dragged.width
				let offsetY = model.containerSize.height / 2 - bounds.midY + dragged.height
				path = path.offsetBy(dx: offsetX, dy: offsetY)
			}
			.fill(Color.green.opacity(0.15))
			VStack {
				Text("Source").italic()
				Text("\(Int(model.sourceSize.width))x\(Int(model.sourceSize.height))")
				Text("\(Int(model.rotation.degrees.rounded()))° \(model.sourceMode.description)")
				Text("\(Int(model.sourceRect.minX))  \(Int(model.sourceRect.minY))  \(Int(model.sourceRect.width))  \(Int(model.sourceRect.height))")
			}
		}
	}
}


public struct RectangleFramingPreview<Content: View>: View {
	let content: () -> Content

	@State var model: RectangleFraming
	@State var step: Int = 0
	let inc = 5

	init(sourceSize: CGSize, content: @escaping () -> Content) {
		self.content = content
		let m = RectangleFraming(sourceSize: sourceSize)
//		m.magnify = 1.25
//		m.offset = .init(width: 0.25, height: 0.1)
		m.mirror = m.mirror.next
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
				try? await Task.sleep(nanoseconds: 1_000_000_000)
				step = step + 1
			}
		}
		.onChange(of: step) { _, newValue in
			let degrees = Double(newValue * inc)
			model.rotation = .degrees(degrees.truncatingRemainder(dividingBy: 360))
		}
	}
}


#Preview("RectangleFramingView Preview") {
	let configuration = UIImage.SymbolConfiguration(
		pointSize: 718,
		weight: .regular,
		scale: .large
	)

	let previewImage = UIImage(
		systemName: "photo.fill",
		withConfiguration: configuration
	)!
	RectangleFramingPreview(sourceSize: previewImage.size) {
		Image(uiImage: previewImage).resizable().opacity(0.25)
	}
}
