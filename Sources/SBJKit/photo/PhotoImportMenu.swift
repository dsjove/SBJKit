import SwiftUI

extension FixedWidthInteger {
	var singleBitValue: Self? {
		(self != 0 && (self & (self - 1)) == 0) ? self : nil
	}
}

public struct PhotoMenuOptions: OptionSet, Sendable {
	public let rawValue: Int

	// Importing
	public static let photos = PhotoMenuOptions(rawValue: 1 << 0)
	public static let camera = PhotoMenuOptions(rawValue: 1 << 1)
	public static let files = PhotoMenuOptions(rawValue: 1 << 2)
	public static let paste = PhotoMenuOptions(rawValue: 1 << 3)
	// Editing
	public static let edit = PhotoMenuOptions(rawValue: 1 << 4)
	public static let clear = PhotoMenuOptions(rawValue: 1 << 5)
	// Viewing
	public static let view = PhotoMenuOptions(rawValue: 1 << 6)
	public static let share = PhotoMenuOptions(rawValue: 1 << 7)

	public static let none: PhotoMenuOptions = []

	public static let imports: PhotoMenuOptions = [.photos, .camera, .files, .paste]
	public static let edits: PhotoMenuOptions = [.edit, .clear]
	public static let reading: PhotoMenuOptions = [.view, .share]
	public static let all: PhotoMenuOptions = [imports, edits, reading]
	public static let modify: PhotoMenuOptions = [imports, edits]

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

public struct _DefaultPhotoImportMenuLabel: View {
	let isFilled: Bool
	public var body: some View {
		Image(systemName: isFilled ? "photo.fill" : "photo")
			.controlSize(.regular)
			.buttonStyle(.borderedProminent)
			.accessibilityAddTraits(.isButton)
	}
}

fileprivate class PhotoMenuState: ObservableObject {
	@Published var isPickerPresented = false
	@Published var isCameraPresented = false
	@Published var isFileImporterPresented = false
	@Published var isPhotoClearPresented = false
	@Published var canPasteImage = false
	@Published var importedImage: UIImage? = nil

	@Published var viewingImage: IdentifiableImage?
	@Published var shareImage: IdentifiableImage?
	@Published var editingImage: IdentifiableImage?
}

public struct PhotoImportMenu<Content: View>: View {
	@Binding private var image: UIImage?
	@StateObject private var state = PhotoMenuState()
    private let label: () -> Content
	
	private let options: PhotoMenuOptions
	private let editImports: Bool

	public init(image: Binding<UIImage?>, options: PhotoMenuOptions = .all, editImports: Bool = true) where Content == _DefaultPhotoImportMenuLabel {
		self._image = image
		self.options = options
		self.editImports = editImports
		self.label = {
			_DefaultPhotoImportMenuLabel(isFilled: image.wrappedValue != nil)
		}
	}

	public init(image: Binding<UIImage?>, options: PhotoMenuOptions = .modify, editImports: Bool = false, @ViewBuilder label: @escaping () -> Content) {
		self._image = image
		self.options = options
		self.editImports = editImports
		self.label = label
	}

	public var body: some View {
		//TODO: if options is just 1 item, do a tap for that one item
		Menu {
			if options.contains(.view), let image {
				Button() {
					state.viewingImage = IdentifiableImage(image: image)
				} label: {
					Label("View", systemImage: "eye")
				}
			}
			if options.contains(.share), let image {
				Button() {
					state.shareImage = IdentifiableImage(image: image)
				} label: {
					Label("Share", systemImage: "square.and.arrow.up")
				}
			}
			if options.contains(.photos) && PhotoMenuOptions.canShowPhotos {
				Button(action: { state.isPickerPresented = true }) {
					Label("Photos", systemImage: "photo.on.rectangle")
				}
			}
			if options.contains(.camera) && PhotoMenuOptions.canShowCamera {
				Button(action: { state.isCameraPresented = true }) {
					Label("Camera", systemImage: "camera")
				}
			}
			if options.contains(.files) && PhotoMenuOptions.canShowFiles {
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
			label()
				.fullScreenCover(item: $state.viewingImage) { identifiable in
					PhotoEditSheet(viewing: identifiable.image) {
						state.viewingImage = nil
					}
				}
				.sheet(item: $state.shareImage) { identifiable in
					ShareSheet(activityItems: [identifiable.image], applicationActivities: nil)
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
				.alert("Clear Photo", isPresented: $state.isPhotoClearPresented) {
					Button("Clear", role: .destructive) {
						DispatchQueue.main.async {
							self.image = nil
						}
					}
					Button("Cancel", role: .cancel) { }
				}
				.onChange(of: state.importedImage) { _, newValue in
					state.importedImage = nil
					if let newValue {
						if editImports {
							DispatchQueue.main.async {
								state.editingImage = IdentifiableImage(image: newValue)
							}
						}
						else {
							image = newValue
						}
					} // else canceled
				}
				.fullScreenCover(item: $state.editingImage) { identifiable in
					PhotoEditSheet(image: identifiable.image) { result in
						if let result {
							image = result
						} // else canceled
					}
					dismiss: {
						state.editingImage = nil
					}
				}
		}
		.menuStyle(.button)
		.onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
			state.canPasteImage = UIPasteboard.general.hasImages
		}
	}
}

