import SwiftUI

#if !os(macOS)

public struct CheckboxToggleStyle: ToggleStyle {
	public func makeBody(configuration: Configuration) -> some View {
		HStack {
			configuration.label
			Spacer()
			Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
				.foregroundColor(configuration.isOn ? .accentColor : .secondary)
				.imageScale(.large)
				.onTapGesture {
					configuration.isOn.toggle()
				}
		}
	}
}

public extension ToggleStyle where Self == CheckboxToggleStyle {
	static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}

#endif
