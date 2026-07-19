import SwiftUI
import PencilKit
import ImageIO
import Observation

let ImageDeleteNoun = "Photo"
let ImageDeleteHint = "Cancel this captured photo."

struct ImageEditContinue: AccessibleImage {
	var image: ImageName { .system("hand.thumbsup") }
	var label: String { "Done Editing" }
}

struct MarkupToolsToggle: AccessibleImage {
	let enabled: Bool
	var image: ImageName { .system(enabled ? "pencil.slash" : "pencil.tip") }
	var label: String { enabled ? "Hide Markup Tools" : "Show Markup Tools" }
}

struct MarkupClear: AccessibleImage {
	var image: ImageName { .system("eraser") }
	var label: String { "Clear Markup" }
}

struct MarkupUndo: AccessibleImage {
	let redo: Bool
	var image: ImageName { .system(redo ? "arrow.uturn.forward" : "arrow.uturn.backward") }
	var label: String { redo ? "Markup Redo" : "Markup Undo" }
}
