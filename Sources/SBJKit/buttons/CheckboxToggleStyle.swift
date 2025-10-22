import SwiftUI

#if !os(macOS)

struct CheckboxToggleStyle: ToggleStyle {
	func makeBody(configuration: Configuration) -> some View {
		HStack {
			configuration.label
			Spacer()
			Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
				.foregroundColor(configuration.isOn ? .accentColor : .secondary)
				.onTapGesture {
					configuration.isOn.toggle()
				}
		}
	}
}

extension ToggleStyle where Self == CheckboxToggleStyle {
	static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}

#endif
