import SwiftUI

public struct CroppedImagePreview: View {
	private let image: UIImage?
	private let transform: CroppingState
	private let cropRect: CGRect?
	private let opacity: Double

	public init(image: UIImage?, transform: CroppingState, cropRect: CGRect?, opacity: Double = 0.4) {
		self.image = image
		self.transform = transform
		self.cropRect = cropRect
		self.opacity = opacity
	}

	public var body: some View {
		ZStack {
			Color(.systemBackground).ignoresSafeArea()
			if let image {
				if transform.fill {
					if opacity > 0.0 {
						Image(uiImage: image)
							.croppingStyle(transform, cropRect)
							.opacity(opacity)
					}
					Image(uiImage: image)
						.croppingStyle(transform, cropRect)
						.clipped()
				} else {
					Image(uiImage: image)
						.croppingStyle(transform, cropRect)
				}
			} else {
				Image(systemName: "photo")
					.foregroundStyle(.primary)
					.font(.largeTitle)
			}
			if let cropRect, transform.fill {
				Rectangle()
					.path(in: cropRect)
					.stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
					.foregroundColor(.primary)
			}
		}
	}
}
