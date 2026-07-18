import SwiftUI
import UIKit

//MARK: Gesture

public struct ImageZoomReset: AccessibleImage {
	public var image: ImageName { .system("inset.filled.square.dashed") }
	public var label: String { "Reset Zoom" }
}

public struct ImageRotate: AccessibleImage {
	let clockwise: Bool
	public var image: ImageName { .system(clockwise ? "rotate.right" :"rotate.left") }
	public var label: String { clockwise ? "Rotate Clockwise" : "Rotate Counterclockwise" }
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

public struct RectangleFramingGestureModifier: ViewModifier {
	private let model: RectangleFraming
	private let enabled: Bool
	private let minScale: CGFloat = 1.0
	private let maxScale: CGFloat = 8.0

	@State private var baseScale: CGFloat = 1.0
	@State private var pinchDelta: CGFloat = 1.0
	@State private var smoothedDelta: CGFloat = 1.0

	init(model: RectangleFraming, enabled: Bool) {
		self.model = model
		self.enabled = enabled
	}

	public func body(content: Content) -> some View {
		content
			.contentShape(Rectangle())
			.onAppear { baseScale = model.magnify; pinchDelta = 1.0; smoothedDelta = 1.0 }
			.onChange(of: model.magnify) { _, newValue in baseScale = newValue }
			.gesture(enabled: enabled, transformGestures(model))
	}

	private func transformGestures(_ model: RectangleFraming) -> some Gesture {
		let drag = DragGesture()
			.onChanged { self.onDrag($0) }
			.onEnded { _ in self.endDrag() }
		let pinch = MagnificationGesture()
			.onChanged { self.onMagnifyChanged($0) }
			.onEnded { _ in self.onMagnifyEnded() }
		let doubleTap = TapGesture(count: 2)
			.onEnded { model.resetPosition() }
		return SimultaneousGesture(
			SimultaneousGesture(drag, pinch),
			doubleTap
		)
	}

	private func reset() {
//		lastOffset = .zero
//		lastScale = 1.0
	}

	private func onDrag(_ value: DragGesture.Value) {
//		let value = value.translation
//		let test = CGSize(width: lastOffset.width + value.width, height: lastOffset.height + value.height)
	}

	private func endDrag() {
//		lastOffset = offset
	}

	private func clamp(_ x: CGFloat, min a: CGFloat, max b: CGFloat) -> CGFloat {
	    return max(a, min(b, x))
	}

	private func deadzone(_ raw: CGFloat, threshold: CGFloat = 0.02) -> CGFloat {
	    let d = raw - 1.0
	    return abs(d) < threshold ? 1.0 : raw
	}

	private func desensitize(_ raw: CGFloat, gain: CGFloat) -> CGFloat {
	    let d = raw - 1.0
	    // Map delta to a symmetric log-like curve with stronger compression
	    let sign: CGFloat = d >= 0 ? 1 : -1
	    let magnitude = abs(d)
	    // compress using log1p to reduce sensitivity for larger deltas
	    let compressed = log1p(magnitude) * 0.6 * gain
	    return 1.0 + sign * compressed
	}

	private func gainForScale(_ s: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
	    guard max > min else { return 0.25 }
	    let t = ((s - min) / (max - min)).clamped(to: 0...1)
	    // lower base gain and reduce at edges
	    let base: CGFloat = 0.25
	    let edgeDrop: CGFloat = 0.15
	    return base + (0.2 * sin(.pi * t)) - (edgeDrop * (abs(t - 0.5) * 2))
	}

	private func onMagnifyChanged(_ raw: CGFloat) {
	    // 1) Dead-zone near 1.0
	    let dz = deadzone(raw, threshold: 0.05)

	    // 2) Desensitize with dynamic gain
	    let gain = gainForScale(baseScale, min: minScale, max: maxScale)
	    let adjusted = desensitize(dz, gain: gain)

	    // 3) Clamp effective scale and convert back to delta
	    let desiredEffective = clamp(baseScale * adjusted, min: minScale, max: maxScale)
	    let desiredDelta = desiredEffective / baseScale

	    // 4) Optional smoothing
	    let smoothing: CGFloat = 0.5
	    smoothedDelta = smoothedDelta + (desiredDelta - smoothedDelta) * (1 - smoothing)

	    // 5) Publish effective scale to model
	    model.magnify = clamp(baseScale * smoothedDelta, min: minScale, max: maxScale)
	}

	private func onMagnifyEnded() {
	    // Commit the new base
	    baseScale = clamp(baseScale * smoothedDelta, min: minScale, max: maxScale)
	    pinchDelta = 1.0
	    smoothedDelta = 1.0
	    model.magnify = baseScale
	}
}

public extension View {
	func gesture(_ model: RectangleFraming, enabled: Bool) -> some View {
		modifier(RectangleFramingGestureModifier(model: model, enabled: enabled))
	}
}

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
		.allowsHitTesting(false)
	}
}

private extension Comparable {
	func clamped(to r: ClosedRange<Self>) -> Self { min(max(self, r.lowerBound), r.upperBound) }
}
