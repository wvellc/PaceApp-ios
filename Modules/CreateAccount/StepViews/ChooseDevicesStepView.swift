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

	@Binding var vm: CreateAccountViewModel


    var body: some View {
        VStack(spacing: 0) {
            VSpace(height: 24)

            // Device list
            VStack(spacing: 16) {
				ForEach($vm.discoveredDevices, id: \.id) { device in
					WatchDeviceRow(
						device: device.wrappedValue,
						selectedWatch: $vm.selectedWatch   // ← pass binding
					) {
						vm.selectedWatch = device.wrappedValue
					}
					.id(vm.selectedWatch?.id == device.id) // forces redraw on selection change

				}
            }

            Spacer()
        }
		.clipped()
        .onAppear {
            if vm.selectedWatch == nil {
				vm.selectedWatch = vm.discoveredDevices.first
            }
        }
    }
}

// MARK: - WatchDeviceRow

struct WatchDeviceRow: View {
	let device: WatchDevice
	@Binding var selectedWatch: WatchDevice?   // ← Binding, not Bool
	let onTap: () -> Void
	
	private var isSelected: Bool {
		selectedWatch?.id == device.id         // ← computed live
	}
	
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
				
				// ✅ Now reacts to binding changes
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
