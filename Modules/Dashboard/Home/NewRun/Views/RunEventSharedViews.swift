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
//        Button(action: action) {
//            Text(title)
//                .font(.system(size: 17, weight: .semibold))
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 18)
//                .background(
//                    LinearGradient(
//                        colors: isEnabled
//                            ? [Color(hex: "4A90E2"), Color(hex: "2563EB")]
//                            : [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
//                        startPoint: .leading,
//                        endPoint: .trailing
//                    )
//                )
//                .cornerRadius(30)
//        }
//        .disabled(!isEnabled)
		
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
    let label: String
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "1E3A8A"))

            HStack(spacing: 0) {
                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60, id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 70, height: 90)
                .clipped()

                Text(":")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "1E3A8A"))
                    .padding(.horizontal, 4)

                Picker("Seconds", selection: $seconds) {
                    ForEach(0..<60, id: \.self) { s in
                        Text(String(format: "%02d", s)).tag(s)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 70, height: 90)
                .clipped()

                Spacer()

                Image(systemName: "drop.fill")
                    .foregroundColor(Color(hex: "3B82F6"))
                    .font(.system(size: 18))
            }
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "DBEAFE"), lineWidth: 1.5)
                    .background(Color.white.cornerRadius(12))
            )
        }
    }
}

// MARK: - Distance Picker Row

struct SegmentDistancePickerRow: View {
    let label: String
    let unit: String
    let options: [Double]
    @Binding var selected: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "1E3A8A"))

            HStack {
                Picker("Distance", selection: $selected) {
                    ForEach(options, id: \.self) { val in
                        Text(String(format: "%.1f", val)).tag(val)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100, height: 90)
                .clipped()

                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6B7280"))

                Spacer()

                Image(systemName: "arrow.up.and.down.circle.fill")
                    .foregroundColor(Color(hex: "3B82F6"))
                    .font(.system(size: 18))
            }
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "DBEAFE"), lineWidth: 1.5)
                    .background(Color.white.cornerRadius(12))
            )
        }
    }
}

// MARK: - White Content Card

struct RunContentCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
