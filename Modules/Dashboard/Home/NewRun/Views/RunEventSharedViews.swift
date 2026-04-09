import SwiftUI

// MARK: - Fixed Header Card (reused across all steps after step 1)

struct RunEventHeaderCard: View {
	
	let onInfoTap: () -> Void
	
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("NewRunEventImage")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
				.frame(height: 280)
                .clipped()
				.cornerRadius(Constant.UI.defaultCornerRadius)

            // Green dot indicator
			Button(action: onInfoTap) {
				Image("icInfo")
				.frame(width: 24, height: 24)
				.padding(11)

			}
        }
    }
}

#Preview {
	RunEventHeaderCard(onInfoTap: {
		
	})
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
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
			AppLabel(title: label, font: .semiBold20)

            HStack(spacing: 0) {
                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60, id: \.self) { m in
                        Text(String(format: "%02d", m))
							.tag(m)
							.font(.medium16)
							.foregroundColor(.darkCharcoal)

                    }
                }
                .pickerStyle(.wheel)
				.frame(width: 100, height: 90)
                .clipped()

                Text(":")
					.font(.medium20)
					.foregroundColor(.darkCharcoal)
                    .padding(.horizontal, 4)

                Picker("Seconds", selection: $seconds) {
                    ForEach(0..<60, id: \.self) { s in
                        Text(String(format: "%02d", s))
							.tag(s)
							.font(.medium16)
							.foregroundColor(.darkCharcoal)

                    }
                }
                .pickerStyle(.wheel)
				.frame(width: 100, height: 90)
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
                Picker("Distance", selection: $selected) {
                    ForEach(options, id: \.self) { val in
                        Text(String(format: "%.1f", val))
							.tag(val)
							.font(.medium16)
							.foregroundColor(.darkCharcoal)

                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100, height: 90)
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
