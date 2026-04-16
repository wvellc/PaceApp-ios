//
//  DatePickerSheet.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/16/26.
//

import SwiftUI

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var date: Date
    let minDate: Date
    let maxDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
				Text(.selectDate)
					.font(.semiBold17)
					.foregroundStyle(.blackApp)
				
                Spacer()
				Button(.done) { dismiss() }
					.font(.semiBold17)
					.foregroundColor(.radiantBlue)
            }
			.padding(.top, 18)

            DatePicker(
                "",
                selection: $date,
                in: minDate...maxDate,
                displayedComponents: .date
            )
			.datePickerStyle(.graphical)
			.tint(.radiantBlue)
			
			
		}
		.padding(.horizontal, Constant.UI.defaultPadding)
		.fixedSize(horizontal: false, vertical: true)
		.presentationDetents([.height(434)])
		.presentationDragIndicator(.visible)


    }
}
