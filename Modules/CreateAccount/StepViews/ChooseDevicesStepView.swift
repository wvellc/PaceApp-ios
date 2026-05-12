//
//  ChooseDevicesStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/17/26.
//

import SwiftUI
import ConnectIQ

// MARK: - ChooseDevicesStepView

/// Step 3 — Lists Garmin watches returned by ConnectIQ after device selection.
/// Reads ciqManager.devices directly so @Observable auto-refreshes the list.
struct ChooseDevicesStepView: View {

    @Bindable var viewModel: CreateAccountViewModel

    var body: some View {
        VStack(spacing: 0) {
            VSpace(height: 24)

            VStack(spacing: 16) {
                let devices = viewModel.ciqManager?.devices ?? []
                ForEach(devices, id: \.uuid) { device in
                    WatchDeviceRow(
                        device: device,
                        isSelected: viewModel.selectedWatch?.uuid == device.uuid
                    ) {
                        viewModel.selectedWatch = device
                    }
                }
            }

            Spacer()
        }
        .clipped()
        .onAppear {
            viewModel.syncSelectedWatch()
        }
        // When ConnectIQManager.devices changes (arrives from Garmin Connect),
        // @Observable triggers a re-render here automatically; we just keep
        // selectedWatch in sync.
        .onChange(of: viewModel.ciqManager?.devices.count ?? 0) { _, _ in
            viewModel.syncSelectedWatch()
        }
    }
}

// MARK: - WatchDeviceRow

struct WatchDeviceRow: View {
    let device: IQDevice
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(.icWatchModel)
                    .resizable()
                    .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 6) {
                    Text(device.modelName ?? device.uuid.uuidString)
                        .font(.semiBold24)
                        .foregroundStyle(.darkCharcoal)
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
//  ChooseDevicesStepView(viewModel: CreateAccountViewModel())
//      .appBackground()
}
