import SwiftUI

public struct PhotoEditSheet: View {
	let image: UIImage?
	let edited: ((UIImage?) -> Void)?
	let dismiss: (() -> Void)?
	let inset: Double
	let opacity: Double

	private var isEditing: Bool { edited != nil }

	@State private var transform: CroppingState
	@State private var showMarkup: Bool = false
	@StateObject private var markup = MarkupModel()

	public init(
			image: UIImage?,
			edited: ((UIImage?) -> Void)?,
			dismiss: (() -> Void)? = nil,
			maxScale: Double = 8.0,
			inset: Double = 16.0,
			opacity: Double = 0.4) {
		self.image = image
		self.edited = edited
		self.dismiss = dismiss
		self.inset = inset
		self.opacity = opacity
		self._transform = State(initialValue: .init(editing: edited != nil, maxScale: maxScale))
	}

	public init(viewing image: UIImage?, inset: Double = 0.0, dismiss: (()->())? = nil) {
		self = .init(
			image: image,
			edited: nil,
			dismiss: dismiss,
			inset: inset)
	}

	func calcCropRect(_ size: CGSize) -> CGRect {
		if isEditing {
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

	public var body: some View {
		NavigationStack {
			GeometryReader { geometry in
				ZStack {
					ImageTransformPreview(
						image: image,
						transform: transform,
						opacity: isEditing ? opacity : 0.0)
						.gesture(enabled: !showMarkup, transformGestures())
					markup.overlay(frame: transform.crop, hitTest: showMarkup)
				}
				.onChange(of: geometry.size) { _, newSize in
					transform.onChange(imgSize: image?.size, cropping: calcCropRect(newSize))
				}
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItemGroup(placement: .topBarLeading) {
						DismissButton {
							if let edited {
								let finalImage = renderWithMarkup(image)
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
						if isEditing {
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
										transform.flip(imgSize: image.size)
									}
									ActionButton("Rotate", image: "rotate.left") {
										transform.rotate(imgSize: image.size)
									}
								}
								ActionButton("Reset", image: "inset.filled.square.dashed") {
									reset()
								}
							}
							ActionButton(showMarkup ? "Hide Markup" : "Markup", image: showMarkup ? "pencil.slash" : "pencil.tip"
							) {
								showMarkup.toggle()
							}
						} else {
							ActionButton("Reset", image: "inset.filled.square.dashed") {
								reset()
							}
							ShareButton {
								([image].compactMap { $0 }, nil)
							}
						}
						//HelpButton(asset: .init(title: isEditing ? "Edit Photo" : "View Photo", folder: "help", mainBundle: false))
					}
				}
			}
		}
	}

	private func transformGestures() -> some Gesture {
		let drag = DragGesture()
			.onChanged { value in
				if let image {
					transform.onDrag(imgSize: image.size, value.translation)
				}
			}
			.onEnded { _ in
				transform.endDrag()
			}

		let pinch = MagnificationGesture()
			.onChanged { value in
				if let image {
					transform.onScale(imgSize: image.size, value)
				}
			}
			.onEnded { _ in
				transform.endScale()
			}

		let doubleTap = TapGesture(count: 2)
			.onEnded {
				reset()
			}
		return SimultaneousGesture(
			SimultaneousGesture(drag, pinch),
			doubleTap
		)
	}

	private func reset() {
		withAnimation() {
			if let image {
				transform.reset(imgSize: image.size)
			}
		}
	}

	private func renderWithMarkup(_ base: UIImage?) -> UIImage? {
		guard let base = base else { return nil }
		let cropped = transform.render(base)
		guard let cropped else { return nil }
		return markup.render(on: cropped, in: transform.crop.size)
	}
}
