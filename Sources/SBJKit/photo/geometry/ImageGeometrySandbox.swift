import SwiftUI

public struct ImageGeometrySandbox: View {
	@State private var geometry = ImageGeometry()
	@State private var appeared: Bool = false

	public var body: some View {
		VStack {
			Image(systemName: "rectangle")
				.imageGeometry(geometry) // All layout handled here
				.onAppear() {
					if !appeared {
						appeared = true
						//geometry.prime(imageSize: T##CGSize, targetRect: T##CGRect)
					}
				}

			Form {
				Section(header: Text("Transform")) {
					Slider(value: $geometry.rotation, in: -180...180, step: 1) {
						Text("Rotation")
					}

					HStack {
						Text("Skew X")
						Slider(value: $geometry.skewX, in: -1...1)
						Text(String(format: "%.2f", geometry.skewX))
					}

					HStack {
						Text("Skew Y")
						Slider(value: $geometry.skewY, in: -1...1)
						Text(String(format: "%.2f", geometry.skewY))
					}

					Toggle("Flip X", isOn: $geometry.flipX)
					Toggle("Flip Y", isOn: $geometry.flipY)
				}

				Section(header: Text("Scale & Position")) {
					HStack {
						Text("Scale X")
						Slider(value: $geometry.scale.width, in: 0.1...3)
						Text(String(format: "%.1f", geometry.scale.width))
					}

					HStack {
						Text("Scale Y")
						Slider(value: $geometry.scale.height, in: 0.1...3)
						Text(String(format: "%.1f", geometry.scale.height))
					}

					HStack {
						Text("Offset X")
						Slider(value: $geometry.offset.width, in: -200...200)
						Text("\(Int(geometry.offset.width))")
					}

					HStack {
						Text("Offset Y")
						Slider(value: $geometry.offset.height, in: -200...200)
						Text("\(Int(geometry.offset.height))")
					}
				}

				Section(header: Text("Content Mode")) {
					Picker("Fit Mode", selection: $geometry.contentMode) {
						Text("Fit").tag(ContentMode.fit)
						Text("Fill").tag(ContentMode.fill)
					}
					.pickerStyle(SegmentedPickerStyle())
				}

				Section {
					HStack {
						Button("Reset") {
							geometry = ImageGeometry() // restores default values
						}
						.foregroundColor(.red)
						.frame(maxWidth: .infinity, alignment: .center)

						Button("Prime") {
							//prime geomtry
						}
						.foregroundColor(.red)
						.frame(maxWidth: .infinity, alignment: .center)
					}
				}
			}
		}
		.padding()
	}
}

#Preview {
	ImageGeometrySandbox()
}
