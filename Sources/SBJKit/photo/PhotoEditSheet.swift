import SwiftUI
import PencilKit

public struct PhotoEditSheet: View {
	let image: UIImage?
	let edited: ((UIImage?) -> Void)?
	let dismiss: (() -> Void)?
	let inset: Double
	let opacity: Double

	@State private var transform: CroppingState
	@State private var showMarkup: Bool = false
	@State private var canvasView = PKCanvasView()
	@State private var toolPicker = PKToolPicker()
	@State private var drawing = PKDrawing()

	public init(
			image: UIImage?,
			edited: ((UIImage?) -> Void)?,
			dismiss: (() -> Void)? = nil,
			fill: Bool = true,
			maxScale: Double = 8.0,
			inset: Double = 16,
			opacity: Double = 0.4) {
		self.image = image
		self.edited = edited
		self.dismiss = dismiss
		self.inset = inset
		self.opacity = opacity
		self._transform = State(initialValue: .init(fill: fill, maxScale: maxScale))
	}

	public init(viewing image: UIImage?, dismiss: (()->())? = nil) {
		self = .init(
			image: image,
			edited: nil,
			dismiss: dismiss,
			fill: false,
			maxScale: 8.0,
			inset: 0.0,
			opacity: 0.0)
	}

	public var body: some View {
		NavigationStack {
			GeometryReader { geometry in
				let cropRect = calcCropRect(geometry.size)
				ZStack {
					Group {
						if showMarkup {
							CroppedImagePreview(image: image, transform: transform, cropRect: cropRect, opacity: opacity)
						} else {
							CroppedImagePreview(image: image, transform: transform, cropRect: cropRect, opacity: opacity)
								.gesture(zoomAndPanGesture(cropRect: cropRect))
								.simultaneousGesture(TapGesture(count: 2)
									.onEnded {
										reset(cropRect)
									})
						}
					}
					.onChange(of: geometry.size) { oldSize, newSize in
						if !transform.userGestured {
							reset(cropRect)
						}
					}
					if showMarkup {
						PencilCanvasOverlay(canvasView: $canvasView, drawing: $drawing)
							.allowsHitTesting(showMarkup)
							.frame(width: cropRect.width, height: cropRect.height)
							.position(x: cropRect.midX, y: cropRect.midY)
							.onAppear {
								canvasView.drawing = drawing
								canvasView.isOpaque = false
								canvasView.backgroundColor = .clear
								canvasView.setNeedsDisplay()
								toolPicker.setVisible(true, forFirstResponder: canvasView)
								toolPicker.addObserver(canvasView)
								canvasView.becomeFirstResponder()
							}
							.onDisappear {
								toolPicker.setVisible(false, forFirstResponder: canvasView)
							}
					}
				}
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItemGroup(placement: .topBarLeading) {
						DismissButton {
							if let edited {
								let finalImage = renderWithMarkup(image, cropRect: cropRect)
								edited(finalImage)
							}
							dismiss?()
						}
						if let edited {
							CancelButton {
								edited(nil)
								dismiss?()
							}
						}
					}
					ToolbarItemGroup(placement: .topBarTrailing) {
						if edited != nil {
							if showMarkup {
								ActionButton("Clear", image: "eraser") {
									canvasView.drawing = PKDrawing()
									drawing = PKDrawing()
								}
								ActionButton("Undo", image: "arrow.uturn.backward") {
									canvasView.undoManager?.undo()
									drawing = canvasView.drawing
								}
								ActionButton("Redo", image: "arrow.uturn.forward") {
									canvasView.undoManager?.redo()
									drawing = canvasView.drawing
								}
							} else {
								ActionButton("Reset", image: "inset.filled.square.dashed") {
									reset(cropRect)
								}
							}
							ActionButton(showMarkup ? "Hide Markup" : "Markup", image: showMarkup ? "pencil.slash" : "pencil.tip"
							) {
								showMarkup.toggle()
							}
						} else {
							ActionButton("Reset", image: "inset.filled.square.dashed") {
								reset(cropRect)
							}
							ShareButton {
								([image].compactMap { $0 }, nil)
							}
						}
						//HelpButton(asset: .init(title: edited != nil ? "Edit Photo" : "View Photo", folder: "help", mainBundle: false))
					}
				}
			}
		}
	}

	private func zoomAndPanGesture(cropRect: CGRect) -> some Gesture {
		SimultaneousGesture(
			DragGesture()
				.onChanged { value in
					if let image {
						transform.userGestured = true
						transform.applyOffset(imgSize: image.size, value.translation, cropping: cropRect)
					}
				}
				.onEnded { _ in
					transform.endDrag()
				},
			MagnificationGesture()
				.onChanged { value in
					if let image {
						transform.userGestured = true
						transform.applyScale(imgSize: image.size, value, cropping: cropRect)
					}
				}
				.onEnded { _ in
					transform.endScale()
				}
		)
	}

	func calcCropRect(_ size: CGSize) -> CGRect {
		if edited != nil {
			let minLength = min(size.width, size.height)
			return CGRect(
				x: (size.width - minLength) / 2 + inset,
				y: (size.height - minLength) / 2 + inset,
				width: minLength - 2 * inset,
				height: minLength - 2 * inset)
		}
		return CGRect(
			x: inset,
			y: inset,
			width: size.width - (2 * inset),
			height: size.height - (2 * inset))
	}

	private func reset(_ cropRect: CGRect) {
		withAnimation() {
			if let image {
				transform.reset(imgSize: image.size, cropping: cropRect)
			}
		}
	}

	private func renderWithMarkup(_ base: UIImage?, cropRect: CGRect) -> UIImage? {
		guard let base = base else { return nil }
		// Render the current transform crop
		let cropped = transform.render(base)
		guard let cropped else { return nil }

		// If no markup, return the cropped image
		guard !drawing.strokes.isEmpty else { return cropped }

		// Create an image context matching the crop area size in points
		let size = CGSize(width: cropRect.width, height: cropRect.height)
		let format = UIGraphicsImageRendererFormat()
		format.scale = UIScreen.main.scale
		let renderer = UIGraphicsImageRenderer(size: size, format: format)

		let composed = renderer.image { ctx in
			// Draw the cropped image to fill
			cropped.draw(in: CGRect(origin: .zero, size: size))

			// Render the PencilKit drawing, scaled to the crop rect size
			let drawingImage = drawing.image(from: CGRect(origin: .zero, size: size), scale: UIScreen.main.scale)
			drawingImage.draw(in: CGRect(origin: .zero, size: size))
		}
		return composed
	}
}

fileprivate struct PencilCanvasOverlay: UIViewRepresentable {
	@Binding var canvasView: PKCanvasView
	@Binding var drawing: PKDrawing

	func makeCoordinator() -> Coordinator {
		Coordinator(drawing: $drawing)
	}

	func makeUIView(context: Context) -> PKCanvasView {
		canvasView.drawing = drawing
		canvasView.isOpaque = false
		canvasView.backgroundColor = .clear
		canvasView.setNeedsDisplay()
		canvasView.drawingPolicy = .anyInput
		canvasView.delegate = context.coordinator
		return canvasView
	}

	func updateUIView(_ uiView: PKCanvasView, context: Context) {
		if uiView.drawing != drawing {
			uiView.drawing = drawing
			uiView.setNeedsDisplay()
		}
	}

	class Coordinator: NSObject, PKCanvasViewDelegate {
		@Binding var drawing: PKDrawing

		init(drawing: Binding<PKDrawing>) {
			_drawing = drawing
		}

		func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
			drawing = canvasView.drawing
		}
	}
}

/*
fileprivate enum RotateFunction: Int, Identifiable {
	case none, rotate, rotateLeft, rotateRight, flipH, flipV, skewX, skewY
	var id: Int { rawValue }
	var requiresSlider: Bool {
		switch self {
		case .rotate, .skewX, .skewY:
			return true
		default:
			return false
		}
	}

	var systemName: String {
		switch self {
		case .rotate:
			return "dial"
		case .rotateLeft:
			return "rotate.left"
		case .rotateRight:
			return "rotate.right"
		case .flipH:
			return "arrow.left.arrow.right.square"
		case .flipV:
			return "arrow.up.arrow.down.square"
		case .skewX:
			return "trapezoid.and.line.horizontal"
		case .skewY:
			return "trapezoid.and.line.vertical"
		case .none:
			return ""
		}
	}
}

fileprivate struct RotateActionCapsule: View {
	@Binding var state: CroppingState

	@State private var activeFunction: RotateFunction = .none

	private let sliderRange = -1.0...1.0
	private let sliderTickCount = 9

	var body: some View {
		VStack(spacing: 8) {
			if activeFunction.requiresSlider {
				Slider(
					value: bindingForActiveSlider(),
					in: sliderRange,
					step: 0.01
				)
				.padding([.top, .horizontal])
			}
			HStack(spacing: 20) {
				RotateActionButton(.rotate, $activeFunction)
				RotateActionButton(.rotateLeft, $activeFunction) {
					state.rotation -= .degrees(90)
				}
				RotateActionButton(.rotateRight, $activeFunction) {
					state.rotation += .degrees(90)
				}
				RotateActionButton(.flipH, $activeFunction) {
					state.flipHorizontally()
				}
				RotateActionButton(.flipV, $activeFunction) {
					state.flipVertically()
				}
				RotateActionButton(.skewX, $activeFunction)
				RotateActionButton(.skewY, $activeFunction)
			}
			.padding()
		}
		.background(
			Capsule()
				.fill(.ultraThinMaterial)
				.shadow(radius: 6)
		)
		.animation(.default, value: activeFunction)
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
	}

	private func bindingForActiveSlider() -> Binding<Double> {
		switch activeFunction {
		case .rotate:
			return Binding<Double>(
				get: {
					let degrees = state.rotation.degrees
					let clamped = min(max(degrees, -90), 90)
					return clamped / 90.0
				},
				set: { newVal in
					state.rotation = .degrees(newVal * 90.0)
				}
			)
		//case .skewX: return $state.horizontalSkew
		//case .skewY: return $state.verticalSkew
		case .none: return .constant(0)
		default: return .constant(0)
		}
	}
}

fileprivate struct RotateActionButton: View {
	let function: RotateFunction
	@Binding var activeFunction: RotateFunction
	let action: () -> Void

	init(_ function: RotateFunction, _ activeFunction: Binding<RotateFunction>, _ action: (() -> Void)? = nil) {
		self.function = function
		self._activeFunction = activeFunction
		let alreadyActive = function == activeFunction.wrappedValue
		self.action = {
			activeFunction.wrappedValue = function
			withAnimation {
				action?()
			}
			if !function.requiresSlider {
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
					withAnimation {
						activeFunction.wrappedValue = .none
					}
				}
			}
			else if alreadyActive {
				activeFunction.wrappedValue = .none
			}
		}
	}

	var body: some View {
		Button {
			action()
		} label: {
			Image(systemName: function.systemName)
				.font(.system(size: 20, weight: .semibold))
				.frame(width: 36, height: 36)
				.background(
					Circle()
						.fill(function ==  activeFunction ? Color.accentColor.opacity(0.5) : Color.clear)
				)
		}
		.buttonStyle(.plain)
		.contentShape(Circle())
	}
}
*/

