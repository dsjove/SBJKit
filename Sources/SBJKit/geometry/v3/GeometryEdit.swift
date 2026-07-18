import SwiftUI
import Observation

// MARK: - GeometryEdit
@Observable
public final class GeometryEdit {
	public var sourceSize: CGSize
	public private(set) var frame: GeometryFrame = .init()
	public var orientation: GeometryOrientation = .init()

	public private(set) var orientedSize: CGSize = .zero
	public private(set) var frameSize: CGSize = .zero
	public private(set) var points: [CGPoint] = [.zero, .zero, .zero, .zero]
	private var orientedRectPoints: [CGPoint] = []

	init(sourceSize: CGSize) {
		self.sourceSize = sourceSize
	}

	var containerSize: CGSize {
		get {
			frame.containerSize
		}
		set {
			frame.containerSize = newValue
			recompute()
		}
	}

    public func rotate(clockwise: Bool = false) {
        orientation.rotation += .degrees(clockwise ? 90 : -90)
		recompute()
    }

    public func flip() {
        orientation.mirror = orientation.mirror.next
		recompute()
    }
/*
    public func setScale(_ value: CGFloat) {
        orientation.scale = value
    }
*/
    // MARK: - Magnification Gesture
    private var lastScale: CGFloat = 1.0

    public func magnify(_ value: MagnificationGesture.Value) {
        // Update scale relative to the last committed scale
//        let proposed = lastScale * value
//        orientation.scale = proposed
    }

    public func endMagnify() {
        // Commit the current scale as the new baseline
//        lastScale = orientation.scale
    }

    public func recompute() {
		orientedSize = orientation.size(for: sourceSize)
		let scale = frame.scale(for: orientedSize)
		frameSize = frame.frameSize(for: orientedSize)
		points = orientation.points(for: sourceSize).map {
			.init(x: $0.x * scale, y: $0.y * scale)
		}
    }
}

// A ViewModifier that attaches gestures to drive a GeometryEdit instance.
struct GeometryEditGesturesModifier: ViewModifier {
    let model: GeometryEdit
    let enabled: Bool

    func body(content: Content) -> some View {
        // Currently only magnification; drag/offset will be added later
		if enabled {
			let pinch = MagnificationGesture()
				.onChanged { value in model.magnify(value) }
				.onEnded { _ in model.endMagnify() }
			content
				.gesture(pinch)
				.contentShape(Rectangle())
		} else {
			content
		}
    }
}

public extension View {
    // Attach geometry edit gestures with an enable switch
    func geometryEditGestures(_ model: GeometryEdit, enabled: Bool = true) -> some View {
        modifier(GeometryEditGesturesModifier(model: model, enabled: enabled))
    }
}
// MARK: - View Modifier to Apply Geometry
private struct GeometryApplyModifier: ViewModifier {
    let model: GeometryEdit

    func body(content: Content) -> some View {
        content
            // Lay out the content first
//            .aspectRatio(contentMode: .fit)
//            .frame(width: model.frameSize.width, height: model.frameSize.height)
//            // Then apply transforms around the center
//            .scaleEffect(model.orientation.scale, anchor: .center)
//            .rotationEffect(model.orientation.rotation, anchor: .center)
//            .scaleEffect(x: model.orientation.mirror.horizontal ? -1 : 1,
//                         y: model.orientation.mirror.vertical ? -1 : 1,
//                         anchor: .center)
    }
}

public extension View {
	func applyGeometry(_ model: GeometryEdit) -> some View {
		modifier(GeometryApplyModifier(model: model))
	}
}

// MARK: - GeometryEditView
private struct ContainerSizeKey: PreferenceKey {
	static var defaultValue: CGSize = .zero
	static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
		value = nextValue()
	}
}

public struct GeometryEditView<Content: View>: View {
	@Bindable var model: GeometryEdit
	let content: () -> Content

    public var body: some View {
		GeometryReader { proxy in
			let size = proxy.size
			ZStack {
				Color.gray.opacity(0.25).ignoresSafeArea()
//				content()
//					.aspectRatio(contentMode: .fit)
//					.rotationEffect(model.orientation.rotation, anchor: .center)
//					.frame(width: model.frameSize.width, height: model.frameSize.height)
				//GeometryEditSchemeView(model: model)
			Rectangle()
				.stroke(Color.blue.opacity(1.0), lineWidth: 3)
				.frame(width: model.containerSize.width, height: model.containerSize.height)
			Rectangle()
				.stroke(Color.red.opacity(1.0), lineWidth: 3)
				.frame(width: model.frameSize.width, height: model.frameSize.height)
            Path { path in
                let pts = model.points
                guard pts.count > 1 else { return }
                // Build the path at its original coordinates
                path.move(to: pts[0])
                for p in pts.dropFirst() {
                    path.addLine(to: p)
                }
                path.closeSubpath()
                // Center the path within the container
                let bounds = path.boundingRect
                let polygonCenter = CGPoint(x: bounds.midX, y: bounds.midY)
                let containerCenter = CGPoint(x: model.containerSize.width / 2, y: model.containerSize.height / 2)
                let dx = containerCenter.x - polygonCenter.x
                let dy = containerCenter.y - polygonCenter.y
                path = path.applying(CGAffineTransform(translationX: dx, y: dy))
            }
            .stroke(Color.green.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
			}
			VStack {
				Text("\(Int(model.sourceSize.width)) x \(Int(model.sourceSize.height))")
				Text("\(Int(model.orientation.rotation.degrees))")
				Text("\(model.orientation.scaleMode)")
				Text("\(Int(model.orientedSize.width)) x \(Int(model.orientedSize.height))")
			}
			.font(.title)
			.background(.white)
			.background(
				Color.clear.preference(key: ContainerSizeKey.self, value: size)
			)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
		.onPreferenceChange(ContainerSizeKey.self) { newSize in
			model.containerSize = newSize
		}
	}
}

struct Test: View {
	let img: UIImage
	let model: GeometryEdit
	@State var step: Int = 0

	var body: some View {
		GeometryEditView(model: model) {
			Image(uiImage: img).resizable()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
		.padding(10)
		.task {
			while true {
				try? await Task.sleep(nanoseconds: 1_000_000_000)
				step = (step + 1) % 24
			}
		}
		.onChange(of: step) { _, newValue in
			// 15 degrees per step; set exact angle
			let degrees = Double(newValue * 15)
			if degrees == 0.0 {
				model.orientation.scaleMode = model.orientation.scaleMode == .fill ? .fit : .fill
			}
			model.orientation.rotation = .degrees(degrees)
			// If you also want to test mirroring or scale over time:
			// model.orientation.mirror = model.orientation.mirror.next
			// model.orientation.scale = 1.0 + 0.25 * sin(Double(newValue) / 24.0 * 2 * .pi)
			model.recompute()
		}
	}
}

// MARK: - Preview
#Preview("GeometryEditView Preview") {
	let url = Bundle.main.url(forResource: "jpmpl_720x855", withExtension: "png")
	let img = (url.flatMap { try? Data(contentsOf: $0) }).flatMap { UIImage(data: $0) } ?? UIImage()
	let model = {
		let model = GeometryEdit(sourceSize: img.size)
		model.orientation.rotation = .degrees(45)
		return model
	}()
	Test(img: img, model: model)
}
