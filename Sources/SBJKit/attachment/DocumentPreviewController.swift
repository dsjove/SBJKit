import SwiftUI
import QuickLook

final class PreviewItem: NSObject, QLPreviewItem {
    let url: URL
    init(url: URL) { self.url = url }
    
    var previewItemURL: URL? { url }
    var previewItemTitle: String? { url.lastPathComponent }
}

struct DocumentPreviewController: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let item: PreviewItem
        
        init(url: URL) {
            self.item = PreviewItem(url: url)
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            item
        }
    }
}
