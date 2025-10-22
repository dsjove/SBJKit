import SwiftUI

fileprivate struct ImageGeometryRenderView: View {
	let inputImage: UIImage
	let geometry: ImageGeometry

	var body: some View {
		Image(uiImage: inputImage)
			.imageGeometry(geometry)
			.frame(width: geometry.cropRect?.width ?? inputImage.size.width,
				   height: geometry.cropRect?.height ?? inputImage.size.height)
			.background(Color.clear)
	}
}

public extension UIImage {
	@MainActor
	func applyingGeometry(_ geometry: ImageGeometry, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
		let renderView = ImageGeometryRenderView(inputImage: self, geometry: geometry)

		let controller = UIHostingController(rootView: renderView)
		let targetSize = CGSize(width: geometry.cropRect?.width ?? size.width,
								height: geometry.cropRect?.height ?? size.height)

		controller.view.bounds = CGRect(origin: .zero, size: targetSize)
		controller.view.backgroundColor = .clear

		let renderer = UIGraphicsImageRenderer(size: targetSize, format: UIGraphicsImageRendererFormat.default())
		return renderer.image { ctx in
			controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
		}
	}
}
