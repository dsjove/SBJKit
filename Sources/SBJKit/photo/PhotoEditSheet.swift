import SwiftUI

public struct PhotoEditSheet: View {
	let image: UIImage?
	let edited: ((UIImage?) -> Void)?
	let dismiss: (() -> Void)?
	let inset: Double
	let opacity: Double

	@State private var transform: CroppingState
	@State private var showMarkup: Bool = false
	@StateObject private var markup = MarkupModel()

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
							GeometryTransformPreview(image: image, transform: transform, cropRect: cropRect, opacity: opacity)
						} else {
							GeometryTransformPreview(image: image, transform: transform, cropRect: cropRect, opacity: opacity)
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
					markup.overlay(frame: cropRect, hitTest: showMarkup)
						.geometryEffect(transform)
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
									markup.clear()
								}
								ActionButton("Undo", image: "arrow.uturn.backward") {
									markup.undo()
								}
								ActionButton("Redo", image: "arrow.uturn.forward") {
									markup.redo()
								}
							} else {
								if let image {
									ActionButton("Flip", image: "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right") {
										transform.flip(imgSize: image.size, cropping: cropRect)
									}
									ActionButton("Rotate", image: "rotate.left") {
										transform.rotate(imgSize: image.size, cropping: cropRect)
									}
								}
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
						transform.onDrag(imgSize: image.size, value.translation, cropping: cropRect)
					}
				}
				.onEnded { _ in
					transform.endDrag()
				},
			MagnificationGesture()
				.onChanged { value in
					if let image {
						transform.onScale(imgSize: image.size, value, cropping: cropRect)
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
		let cropped = transform.render(base)
		guard let cropped else { return nil }
		return markup.render(on: cropped, transform: transform, in: cropRect)
	}
}
