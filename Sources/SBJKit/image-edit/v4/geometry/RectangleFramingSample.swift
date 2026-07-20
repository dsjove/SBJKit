import SwiftUI
import UIKit

public struct RectangleFramingSample<Content: View>: View {
	let content: () -> Content
	let quickView: (()->())?

	@State var model: RectangleFraming
	@State var step: Int = 0
	let inc = 5
	let ns: UInt64 = 500_000_000

    @State private var quickLookImage: UIImage? = nil
    @State private var showQuickLook: Bool = false

    // Renders the framed content view into a UIImage at the model's current frame size
    private func renderFramedImage() -> UIImage? {
        let size = model.frameSize
        guard size.width > 0, size.height > 0 else { return nil }

        // Build a SwiftUI view matching the framed output size
        let view = ZStack {
            Color.clear
            content()
                .rectangleFraming(model)
        }
        .frame(width: size.width, height: size.height)

        // Prefer ImageRenderer on modern platforms; fallback to UIKit rendering
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = UIScreen.main.scale
            return renderer.uiImage
        } else {
            let controller = UIHostingController(rootView: view)
            controller.view.bounds = CGRect(origin: .zero, size: size)
            controller.view.backgroundColor = .clear

            let format = UIGraphicsImageRendererFormat.default()
            format.scale = UIScreen.main.scale
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            let image = renderer.image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            return image
        }
    }

	init(image: UIImage) where Content == Image {
		self.init(sourceSize: image.size, quickView: nil) {
			Image(uiImage: image).resizable()
		}
	}

	init(sourceSize: CGSize, quickView: (()->())?, content: @escaping () -> Content) {
		self.quickView = quickView
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
						.gesture(model, enabled: true)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.quickLookImage = renderFramedImage()
                        self.showQuickLook = (self.quickLookImage != nil)
                    } label: {
                        Label("Quick Look", systemImage: "eye")
                    }
                }
			}
            .sheet(isPresented: $showQuickLook) {
                PreviewSheet(image: quickLookImage)
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
	RectangleFramingSample(image: previewImage)
}

private struct PreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let image = image {
                    ScrollView([.vertical, .horizontal]) {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("Framed Image", image: Image(uiImage: image)))
                        .labelStyle(.titleAndIcon)
                } else {
                    Text("No preview available")
                        .font(.headline)
                }
            }
            .padding()
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
