import SwiftUI
import PencilKit

@MainActor
final class MarkupModel: ObservableObject {
	@Published var drawing: PKDrawing
	@Published var canvasView: PKCanvasView
	let toolPicker: PKToolPicker

	init() {
		self.drawing = PKDrawing()
		self.canvasView = PKCanvasView()
		self.toolPicker = PKToolPicker()
	}

	func overlay(frame: CGRect, hitTest: Bool = true) -> some View {
		PencilCanvasOverlay(
			canvasView: Binding<PKCanvasView>(
				get: { self.canvasView },
				set: { self.canvasView = $0 }
			),
			drawing: Binding<PKDrawing>(
				get: { self.drawing },
				set: { self.drawing = $0 }
			)
		)
			.allowsHitTesting(hitTest)
			.frame(width: frame.width, height: frame.height)
			.position(x: frame.midX, y: frame.midY)
			.onAppear {
				self.canvasView.drawing = self.drawing
				self.canvasView.isOpaque = false
				self.canvasView.backgroundColor = .clear
				self.canvasView.setNeedsDisplay()
				self.toolPicker.setVisible(true, forFirstResponder: self.canvasView)
				self.toolPicker.addObserver(self.canvasView)
				self.canvasView.becomeFirstResponder()
			}
			.onDisappear {
				self.toolPicker.setVisible(false, forFirstResponder: self.canvasView)
			}
	}

    func clear() {
        canvasView.drawing = PKDrawing()
        drawing = PKDrawing()
    }

    func undo() {
        canvasView.undoManager?.undo()
        drawing = canvasView.drawing
    }

    func redo() {
        canvasView.undoManager?.redo()
        drawing = canvasView.drawing
    }

    /// Renders the current PencilKit drawing on top of a base image within the given crop rect.
    /// - Parameters:
    ///   - base: The base UIImage to draw beneath the markup.
    ///   - cropRect: The rect (in points) representing the visible crop area size.
    /// - Returns: A new UIImage with the markup rendered on top.
    func render(on base: UIImage, transform: any GeometryTransform, in cropRect: CGRect) -> UIImage {
		// If no markup, return the cropped image
		guard !drawing.strokes.isEmpty else { return base }

        let size = CGSize(width: cropRect.width, height: cropRect.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let composed = renderer.image { ctx in
            // Draw the base image to fill
            base.draw(in: CGRect(origin: .zero, size: size))

            // Render the PencilKit drawing, scaled to the crop rect size
            let drawingImage = drawing.image(from: CGRect(origin: .zero, size: size), scale: UIScreen.main.scale)
            drawingImage.draw(in: CGRect(origin: .zero, size: size))
        }
        return composed
    }
}
