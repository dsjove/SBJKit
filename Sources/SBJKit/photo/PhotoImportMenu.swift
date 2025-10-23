import SwiftUI

fileprivate class PhotoMenuState: ObservableObject {
	@Published var isPickerPresented = false
	@Published var isCameraPresented = false
	@Published var isFileImporterPresented = false
	@Published var isPhotoClearPresented = false
	@Published var canPasteImage = false
	@Published var importedImage: UIImage? = nil
}

public struct PhotoImportMenu: View {
	public struct MenuOptions: OptionSet, Sendable {
		public let rawValue: Int

		// Importing
		public static let photos = MenuOptions(rawValue: 1 << 0)
		public static let camera = MenuOptions(rawValue: 1 << 1)
		public static let files = MenuOptions(rawValue: 1 << 2)
		public static let paste = MenuOptions(rawValue: 1 << 3)
		// Editing
		public static let edit = MenuOptions(rawValue: 1 << 4)
		public static let clear = MenuOptions(rawValue: 1 << 5)
		// Viewing
		// TODO: 'Share': ShareButton currently cannot work from a menu
		// TODO: 'View': needs more context in callbacks

		public static let all: MenuOptions = [.photos, .camera, .files, .paste, .edit, .clear]

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		static var canShowPhotos: Bool {
#if os(iOS) || os(tvOS) || os(visionOS)
			if #available(iOS 14, tvOS 14, visionOS 1, *) {
				return true
			}
			return false
#elseif os(macOS)
			if #available(macOS 12, *) {
				return true
			}
			return false
#else
			return false
#endif
		}

		@MainActor
		static var canShowCamera: Bool {
#if os(iOS) || os(visionOS)
			return UIImagePickerController.isSourceTypeAvailable(.camera)
#else
			return false
#endif
		}

		static var canShowFiles: Bool {
#if os(iOS) || os(macOS) || os(visionOS)
			if #available(iOS 14, macOS 11, visionOS 1, *) {
				return true
			}
			return false
#else
			return false
#endif
		}
	}

	@Binding private var image: UIImage?
	@StateObject private var state = PhotoMenuState()
	
	private let options: MenuOptions

	public init(image: Binding<UIImage?>, options: MenuOptions = .all) {
		self._image = image
		self.options = options
	}

	public var body: some View {
		Menu {
			if options.contains(.photos) && MenuOptions.canShowPhotos {
				Button(action: { state.isPickerPresented = true }) {
					Label("Photos", systemImage: "photo.on.rectangle")
				}
			}
			if options.contains(.camera) && MenuOptions.canShowCamera {
				Button(action: { state.isCameraPresented = true }) {
					Label("Camera", systemImage: "camera")
				}
			}
			if options.contains(.files) && MenuOptions.canShowFiles {
				Button(action: { state.isFileImporterPresented = true }) {
					Label("Files", systemImage: "folder")
				}
			}
			if options.contains(.paste) {
				Button(action: {
					if let pasted = UIPasteboard.general.image {
						DispatchQueue.main.async {
							state.importedImage = pasted
						}
					}
				}) {
					Label("Paste", systemImage: "doc.on.clipboard")
				}
				.disabled(!state.canPasteImage)
			}
			if options.contains(.edit) && image != nil {
				Button(action: {
					if let currentImage = image {
						DispatchQueue.main.async {
							state.importedImage = currentImage
						}
					}
				}) {
					Label("Edit", systemImage: "pencil")
				}
			}
			if options.contains(.clear) && image != nil {
				Button(role: .destructive) {
					state.isPhotoClearPresented = true
				} label: {
					Label("Clear", systemImage: "trash")
				}
			}
		} label: {
			Image(systemName: image != nil ? "photo.fill" : "photo")
				.buttonStyle(.bordered)
				.controlSize(.large)
				.accessibilityAddTraits(.isButton)
		}
		.menuStyle(.button)
		.onChange(of: state.importedImage) { _, newValue in
			if let newValue {
				state.importedImage = nil
				image = newValue
			}
		}
		.sheet(isPresented: $state.isPickerPresented) {
			PhotoPickerView(image: $state.importedImage)
		}
		.fullScreenCover(isPresented: $state.isCameraPresented) {
			CameraPickerView(image: $state.importedImage)
		}
		.fileImporter(
			isPresented: $state.isFileImporterPresented,
			allowedContentTypes: [.image],
			allowsMultipleSelection: false
		) { result in
			switch result {
			case .success(let urls):
				if let url = urls.first {
					if let data = try? Data(contentsOf: url),
					   let uiImage = UIImage(data: data) {
						DispatchQueue.main.async {
							state.importedImage = uiImage
						}
					}
				}
			case .failure:
				break
			}
		}
		.onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
			state.canPasteImage = UIPasteboard.general.hasImages
		}
		.alert("Clear Photo", isPresented: $state.isPhotoClearPresented) {
			Button("Clear", role: .destructive) {
				DispatchQueue.main.async {
					self.image = nil
				}
			}
			Button("Cancel", role: .cancel) { }
		}
	}
}
