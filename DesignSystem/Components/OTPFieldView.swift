//
//  OTPFieldView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/18/26.
//


import SwiftUI
import Combine


// A SwiftUI view for entering OTP (One-Time Password).
struct OTPFieldView: View {
    
    @FocusState private var pinFocusState: FocusPin?
    @Binding private var otp: String
    @State private var pins: [String]
    
    var numberOfFields: Int
    
    enum FocusPin: Hashable {
        case pin(Int)
    }
    
    init(numberOfFields: Int, otp: Binding<String>) {
        self.numberOfFields = numberOfFields
        self._otp = otp
        self._pins = State(initialValue: Array(repeating: "", count: numberOfFields))
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfFields, id: \.self) { index in
                OTPTextField(
                    text: $pins[index],
                    onBackspace: {
                        if pins[index].isEmpty {
                            // Move focus to previous and clear previous pin
                            if index > 0 {
                                // Clear previous value and focus back
                                pins[index - 1] = ""
                                updateOTPString()
                                pinFocusState = FocusPin.pin(index - 1)
                                HapticManager.shared.light()
                            }
                        }
                    },
                    onCommit: {
                        // Called when a single character is entered
                        if pins[index].count == 1 {
                            if index < numberOfFields - 1 {
                                pinFocusState = FocusPin.pin(index + 1)
                            } else {
                                // Last digit entered — keep focus or clear if desired
                                // pinFocusState = nil
                            }
                        } else if pins[index].count == numberOfFields, let _ = Int(pins[index]) {
                            // Pasted full value into this field
                            otp = pins[index]
                            updatePinsFromOTP()
                            pinFocusState = FocusPin.pin(numberOfFields - 1)
                        }
                        updateOTPString()
                        HapticManager.shared.light()
                    }
                )
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.whiteApp, lineWidth: 1.2)
                )
                .focused($pinFocusState, equals: FocusPin.pin(index))
                .onTapGesture {
                    pinFocusState = FocusPin.pin(index)
                }
            }
        }
        .onAppear {
            // Initialize pins based on the OTP string
            updatePinsFromOTP()
        }
    }
    
    private func updatePinsFromOTP() {
        let otpArray = Array(otp.prefix(numberOfFields))
        for (index, char) in otpArray.enumerated() {
            pins[index] = String(char)
        }
    }
    
    private func updateOTPString() {
		DispatchQueue.main.async {
			otp = pins.joined()
		}
    }
}

struct OtpModifier: ViewModifier {
    @Binding var pin: String
    
    var textLimit = 1
    
    func limitText(_ upper: Int) {
        if pin.count > upper {
            self.pin = String(pin.prefix(upper))
        }
    }
    
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .onReceive(Just(pin)) { _ in limitText(textLimit) }
            .frame(width: 50, height: 50)
            .font(.medium24)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.whiteApp, lineWidth: 1.2)
            )
    }
}

struct OTPFieldView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        VStack(alignment: .leading, spacing: 8) {
            Text("VERIFICATION CODE")
                .foregroundColor(Color.gray)
                .font(.system(size: 12))
            OTPFieldView(numberOfFields: 5, otp: .constant("54321"))
                .previewLayout(.sizeThatFits)
            Spacer()
        }
        .backgroundStyle(Color.radiantBlue)
        .background(Color.radiantBlue)
    }
}

// Callback protocol to detect backspace on empty field
class BackspaceTextField: UITextField {
    var onBackspaceWhenEmpty: (() -> Void)?
    
    override func deleteBackward() {
        if text?.isEmpty == true {
            onBackspaceWhenEmpty?()
        }
        super.deleteBackward()
    }
}

struct OTPTextField: UIViewRepresentable {
    @Binding var text: String
    var onBackspace: () -> Void
    var onCommit: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onBackspace: onBackspace, onCommit: onCommit)
    }
    
    func makeUIView(context: Context) -> BackspaceTextField {
        let tf = BackspaceTextField()
        tf.delegate = context.coordinator
        tf.keyboardType = .numberPad
        tf.textAlignment = .center
        tf.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
		tf.textColor = .whiteApp
        tf.tintColor = .whiteApp
        tf.onBackspaceWhenEmpty = onBackspace
        return tf
    }
    
    func updateUIView(_ uiView: BackspaceTextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var onBackspace: () -> Void
        var onCommit: () -> Void
        
        init(text: Binding<String>, onBackspace: @escaping () -> Void, onCommit: @escaping () -> Void) {
            _text = text
            self.onBackspace = onBackspace
            self.onCommit = onCommit
        }
        
        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            guard string.count <= 1 else { return false }
			
			DispatchQueue.main.async { [ self] in
				text = string
				if !string.isEmpty {
					onCommit() // move to next field
				}

			}
			
            return false // we manage text manually
        }
    }
}


//
//#Preview {
//  VStack {
//      Spacer()
//      OTPFieldView(numberOfFields: 6, otp: .constant(""))
//      Spacer()
//  }
//  .backgroundStyle(Color.radiantBlue)
//}


