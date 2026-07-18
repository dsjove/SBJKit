import SwiftUI
import UIKit

//MARK: UIImage

public extension UIImage {
	func render(_ model: RectangleFraming) -> UIImage {
		return self
	}
}

//MARK: View Modifier

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

public extension View {
	func rectangleFraming(_ model: RectangleFraming) -> some View {
		modifier(RectangleFramingModifier(model: model))
	}
}

//MARK: Diagram

public struct RectangleFramingDiagram: View {
	let model: RectangleFraming
	public var body: some View {
		ZStack {
		// Background
			Color.gray.opacity(0.25).ignoresSafeArea()
		// Guides
			Path { path in
				path.addRect(model.containerRect)
			}
			.stroke(Color.blue.opacity(1.0), lineWidth: 5)
			Path { path in
				path.addRect(model.frameRect)
			}
			.stroke(Color.red.opacity(1.0), lineWidth: 3)
		// Framed Structure
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
		// Positioned Shadow
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
			.fill(Color.green.opacity(0.2))
		// Source Info
			VStack {
				Text("Source").italic()
				Text("\(Int(model.sourceSize.width))x\(Int(model.sourceSize.height))")
				Text("\(Int(model.rotation.degrees.rounded()))° \(model.sourceMode.description)")
				Text("\(Int(model.sourceRect.minX))  \(Int(model.sourceRect.minY))  \(Int(model.sourceRect.width))  \(Int(model.sourceRect.height))")
			}
		}
	}
}
