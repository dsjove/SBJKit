import SwiftUI
import SBJFoundation

#if !os(macOS)

public struct CheckboxToggleStyle: ToggleStyle {
	public func makeBody(configuration: Configuration) -> some View {
		HStack {
			configuration.label
			Spacer()
			Image(.system(configuration.isOn ? "checkmark.square.fill" : "square"))
				.foregroundStyle(configuration.isOn ? SBJUIAppearance.activeControlColor : SBJUIAppearance.inactiveControlColor)
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
