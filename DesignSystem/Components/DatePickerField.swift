//
//  DatePickerField.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/16/26.
//

import SwiftUI

// MARK: - Date Picker Field
struct DatePickerField: View {
    @Binding var date: Date
    let minDate: Date
    let maxDate: Date
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            HStack(spacing: 10) {
                Image("icEventDate")
					.frame(width: 24, height: 24)

                Text(date.formatted(date: .abbreviated, time: .omitted))
					.font(.medium20)
					.foregroundColor(.whiteApp)
					

                Spacer()

				Image(.icDownArrow)
					.resizable()
					.frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
			.cardBackground(bg:.clear)
        }
        .sheet(isPresented: $showPicker) {
			DatePickerSheet(date: $date, minDate: minDate, maxDate: maxDate)
        }
    }
}

