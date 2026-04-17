//
//  WatchDevice.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/17/26.
//

import SwiftUI

// MARK: - ChooseYourModelStepView

/// Step 3 — Lists nearby Garmin watches discovered via Bluetooth.
/// The user selects one before tapping "Pair".
struct ChooseDevicesStepView: View {

	@Bindable var viewModel: CreateAccountViewModel


    var body: some View {
        VStack(spacing: 0) {
            VSpace(height: 24)

            // Device list
            VStack(spacing: 16) {
				ForEach(viewModel.discoveredDevices) { device in
					WatchDeviceRow(
						device: device,
						isSelected: viewModel.selectedWatch?.id == device.id
					) {
						viewModel.selectedWatch = device
					}
				}
            }

            Spacer()
        }
		.clipped()
        .onAppear {
            if viewModel.selectedWatch == nil {
				viewModel.selectedWatch = viewModel.discoveredDevices.first
            }
        }
    }
}

// MARK: - WatchDeviceRow

struct WatchDeviceRow: View {
	let device: WatchDevice
	let isSelected: Bool
	let onTap: () -> Void

	var body: some View {
		Button(action: onTap) {
			HStack(spacing: 16) {
				Image(.icWatchModel)
					.resizable()
					.frame(width: 80, height: 80)
				
				VStack(alignment: .leading, spacing: 6) {
					Text(device.model)
						.font(.semiBold24)
						.foregroundStyle(.darkCharcoal)
					Text(device.nickname)
						.font(.regular16)
						.foregroundStyle(.neonAquaBlue)
				}
				
				Spacer()
				
				Image(isSelected ? .icRadioSelected : .icRadioUnSelected)
					.resizable()
					.frame(width: 24, height: 24)
			}
			.padding(8)
			.background(.whiteApp)
			.clipShape(RoundedRectangle(cornerRadius: Constant.UI.defaultCornerRadius))
		}
		.buttonStyle(.plain)
	}
}

#Preview {
//    @Previewable @State var selected: WatchDevice? = nil
//	ChooseDevicesStepView(vm: CreateAccountViewModel())
//        .appBackground()
}
