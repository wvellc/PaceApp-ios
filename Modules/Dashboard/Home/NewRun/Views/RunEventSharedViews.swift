import SwiftUI

// MARK: - Fixed Header Card (reused across all steps after step 1)

struct RunEventHeaderCard: View {
	
    var body: some View {
		Image("NewRunEventImage")
			.resizable()
			.scaledToFill()
			.frame(maxWidth: .infinity)
			.frame(height: 280)
			.clipped()
			.cornerRadius(Constant.UI.defaultCornerRadius)
    }
}

#Preview {
	RunEventHeaderCard()
}

// MARK: - Styled Input Field

struct RunEventInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
		HStack(alignment:.center, spacing: 12) {
            Image(icon)
				.frame(width: 24, height: 24)

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.5))
                }
                .foregroundColor(.white)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Next Button

struct RunNextButton: View {
    let title: LocalizedStringResource
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
		AppButton(title) {
			action()
		}
		.disabled(!isEnabled)

    }
}

// MARK: - Back Button

struct RunBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Segment Time Picker Row

struct SegmentTimePickerRow: View {
	let label: LocalizedStringResource
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
			AppLabel(title: label, font: .semiBold20)

            HStack {
				Picker("Hourse", selection: $hours) {
					ForEach(0..<24, id: \.self) { m in
						Text(String(format: "%02d", m))
							.tag(m)
							.font(.medium16)
							.foregroundColor(.darkCharcoal)
						
					}
				}
				.pickerStyle(.wheel)
				.frame(width: 80, height: 90)
				.clipped()
				
				Text(":")
					.font(.medium20)
					.foregroundColor(.darkCharcoal)
					.padding(.horizontal, 2)
				
                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60, id: \.self) { m in
                        Text(String(format: "%02d", m))
							.tag(m)
							.font(.medium16)
							.foregroundColor(.darkCharcoal)

                    }
                }
                .pickerStyle(.wheel)
				.frame(width: 80, height: 90)
                .clipped()

                Text(":")
					.font(.medium20)
					.foregroundColor(.darkCharcoal)
                    .padding(.horizontal, 2)

                Picker("Seconds", selection: $seconds) {
                    ForEach(0..<60, id: \.self) { s in
                        Text(String(format: "%02d", s))
							.tag(s)
							.font(.medium16)
							.foregroundColor(.darkCharcoal)

                    }
                }
                .pickerStyle(.wheel)
				.frame(width: 80, height: 90)
                .clipped()

                Spacer()

				Image(.icOvertime)
					.frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
			.cardBackground()
        }
    }
}

// MARK: - Distance Picker Row

struct SegmentDistancePickerRow: View {
	let label: LocalizedStringResource
    let unit: String
    let options: [Double]
    @Binding var selected: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AppLabel(title: label, font: .semiBold20)

            HStack {
                // Integer part 0...999 with leading zeros (00, 01, ... 999)
                Picker("Integer Distance", selection: Binding(
                    get: {
                        let clamped = max(0, min(999, Int(selected)))
                        return clamped
                    },
                    set: { newValue in
                        let fractional = selected - floor(selected)
                        let clampedInt = max(0, min(999, newValue))
                        selected = Double(clampedInt) + fractional
                    }
                )) {
                    ForEach(1...999, id: \.self) { intVal in
                        let text = intVal < 100 ? String(format: "%02d", intVal) : String(intVal)
                        Text(text)
                            .tag(intVal)
                            .font(.medium16)
                            .foregroundColor(.darkCharcoal)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 90)
                .clipped()

                Text(".")
                    .font(.medium20)
                    .foregroundColor(.darkCharcoal)
                    .padding(.horizontal, 2)

                // Fractional part in hundredths (00, 01, ... 99) representing .00 to .99
                Picker("Fractional Distance", selection: Binding(
                    get: {
                        let fractional = selected - floor(selected)
                        let hundredths = Int((fractional * 100).rounded())
                        return max(0, min(99, hundredths))
                    },
                    set: { newValue in
                        let clampedHundredths = max(0, min(99, newValue))
                        let intPart = Int(selected)
                        selected = Double(intPart) + Double(clampedHundredths) / 100.0
                    }
                )) {
                    ForEach(0...99, id: \.self) { frac in
                        Text(String(format: "%02d", frac))
                            .tag(frac)
                            .font(.medium16)
                            .foregroundColor(.darkCharcoal)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 90)
                .clipped()

                Text(unit)
                    .font(.medium18)
                    .foregroundColor(.darkCharcoal)

                Spacer()

                Image(.icDistance)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .cardBackground()
        }
        .onChange(of: selected) {oldVaue, newValue in
            // Clamp to 0...999.99
            let clamped = max(0.0, min(999.99, newValue))
            if clamped != selected {
                selected = clamped
            }
        }
    }
}

// MARK: - White Content Card

struct RunContentCard<Content: View>: View {
    let content: Content
	let spacing: CGFloat
	
	init(@ViewBuilder content: () -> Content, spacing: CGFloat = 16) {
        self.content = content()
		self.spacing = spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(16)
		.background(.whiteApp)
		.cornerRadius(Constant.UI.cardCornerRadius)
		.shadow(color: .radiantBlue.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Helpers

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xff0000) >> 16) / 255
        let g = Double((rgbValue & 0xff00) >> 8) / 255
        let b = Double(rgbValue & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}

