//
//  PreviewRoot.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//


// ToastExampleView.swift
// Complete example demonstrating ALL toast capabilities
// Works in SwiftUI Preview, Simulator, and Device
//
// PREVIEW SETUP: The PreviewRoot wrapper installs the toast system
// so all previews work correctly out of the box.

import SwiftUI

// MARK: - Preview Root Wrapper
// ✅ Always wrap previews with this to activate the toast overlay
struct PreviewRoot<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
			.installToast(position: .top)
    }
}

// ============================================================
// MARK: - Toast Example ViewModel
// ============================================================
@Observable
@MainActor
final class ToastExampleViewModel {

    // MARK: Basic Toasts from ViewModel

    func showSuccess() {
        ToastManager.shared.present(.success("Profile saved successfully!"))
    }

    func showError() {
        ToastManager.shared.present(.error("Failed to load data. Please retry."))
    }

    func showWarning() {
        ToastManager.shared.present(.warning("Storage is almost full (90%)."))
    }

    func showInfo() {
        ToastManager.shared.present(.info("App updated to version 2.4.1"))
    }

    // MARK: Custom Icon Toast

    func showCustomIcon() {
        ToastManager.shared.present(ToastValue(
            icon: Image(systemName: "star.fill"),
            message: "You earned a new badge!",
            type: .success,
            duration: 4.0
        ))
    }

    // MARK: Message Only Toast (No Icon)

    func showMessageOnly() {
        ToastManager.shared.present(ToastValue(
            message: "Copied to clipboard.",
            type: .info,
            duration: 2.0
        ))
    }

    // MARK: Long Duration Toast

    func showLongDuration() {
        ToastManager.shared.present(ToastValue(
            icon: Image(systemName: "clock.fill"),
            message: "This toast stays for 8 seconds.",
            type: .info,
            duration: 8.0
        ))
    }

    // MARK: Short Duration Toast

    func showShortDuration() {
        ToastManager.shared.present(ToastValue(
            icon: Image(systemName: "bolt.fill"),
            message: "Quick!",
            type: .info,
            duration: 1.5
        ))
    }

    // MARK: Toast with Action Button

    func showWithUndoButton() {
        ToastManager.shared.present(ToastValue(
            icon: Image(systemName: "trash.fill"),
            message: "Email deleted.",
            type: .warning,
            duration: 5.0,
            button: ToastButton(title: "Undo", color: .orange) {
                ToastManager.shared.present(.success("Email restored!"))
            }
        ))
    }

    func showWithRetryButton() {
        ToastManager.shared.present(ToastValue(
            icon: Image(systemName: "xmark.circle.fill"),
            message: "Network request failed.",
            type: .error,
            duration: 6.0,
            button: ToastButton(title: "Retry", color: .red) {
                self.simulateAsyncTask()
            }
        ))
    }

    func showWithConfirmButton() {
        ToastManager.shared.present(ToastValue(
            icon: Image(systemName: "bell.fill"),
            message: "You have 3 new messages.",
            type: .info,
            duration: 5.0,
            button: ToastButton(title: "View", color: .blue) {
                ToastManager.shared.present(.info("Opening Messages..."))
            }
        ))
    }

    // MARK: Async / Loading Toast

    func simulateAsyncTask() {
        ToastManager.shared.present(
            message: "Uploading file...",
            task: {
                // Simulate network delay
                try await Task.sleep(nanoseconds: 2_500_000_000)
                let success = Bool.random()
                if success {
                    return "file_v2.pdf"
                } else {
                    throw URLError(.timedOut)
                }
            },
            onSuccess: { filename in
                ToastValue(
                    icon: Image(systemName: "checkmark.circle.fill"),
                    message: "\(filename) uploaded!",
                    type: .success
                )
            },
            onFailure: { error in
                ToastValue(
                    icon: Image(systemName: "xmark.circle.fill"),
                    message: "Upload failed: \(error.localizedDescription)",
                    type: .error,
                    duration: 4.0
                )
            }
        )
    }

    func simulateLoginTask() {
        ToastManager.shared.present(
            message: "Signing in...",
            task: {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return "Alice"
            },
            onSuccess: { username in
                ToastValue(
                    icon: Image(systemName: "person.circle.fill"),
                    message: "Welcome back, \(username)!",
                    type: .success
                )
            },
            onFailure: { _ in
                ToastValue.error("Sign in failed. Check credentials.")
            }
        )
    }

    // MARK: Queue Multiple Toasts

    func showMultipleQueued() {
        ToastManager.shared.present(.info("Step 1: Validating data..."))
        ToastManager.shared.present(.success("Step 2: Data is valid."))
        ToastManager.shared.present(.warning("Step 3: Partial sync."))
        ToastManager.shared.present(.error("Step 4: Final sync failed."))
    }

    // MARK: Long Message Toast

    func showLongMessage() {
        ToastManager.shared.present(ToastValue(
            icon: Image(systemName: "info.circle.fill"),
            message: "Your subscription will renew on Dec 31. Update your payment method to avoid interruption.",
            type: .warning,
            duration: 5.0
        ))
    }
}

// ============================================================
// MARK: - Main Example View
// ============================================================

struct ToastExampleView: View {

    // ✅ Via Environment — for use directly in Views
    @Environment(\.presentToast) var presentToast

    // ✅ Via ViewModel — for business logic toasts
	@State private var viewModel = ToastExampleViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ─── Section: Basic Types ───
                    ToastSectionView(title: "Basic Types", icon: "square.grid.2x2") {
                        VStack(spacing: 10) {
                            ToastDemoButton(label: "✅  Success", color: .green) {
                                presentToast(.success("Changes saved successfully!"))
                            }
                            ToastDemoButton(label: "❌  Error", color: .red) {
                                presentToast(.error("Something went wrong."))
                            }
                            ToastDemoButton(label: "⚠️  Warning", color: .orange) {
                                presentToast(.warning("Low battery — 10% remaining."))
                            }
                            ToastDemoButton(label: "ℹ️  Info", color: .blue) {
                                presentToast(.info("Your session expires in 5 minutes."))
                            }
                        }
                    }

                    // ─── Section: Icon Variants ───
                    ToastSectionView(title: "Icon Variants", icon: "photo") {
                        VStack(spacing: 10) {
                            ToastDemoButton(label: "Custom SF Symbol Icon", color: .purple) {
                                presentToast(ToastValue(
                                    icon: Image(systemName: "heart.fill"),
                                    message: "Added to favourites.",
                                    type: .success
                                ))
                            }
                            ToastDemoButton(label: "No Icon (Message Only)", color: .gray) {
                                presentToast(ToastValue(
                                    message: "Link copied to clipboard.",
                                    type: .info
                                ))
                            }
                            ToastDemoButton(label: "Custom Duration (8s)", color: .indigo) {
                                presentToast(ToastValue(
                                    icon: Image(systemName: "timer"),
                                    message: "This toast stays for 8 seconds.",
                                    type: .info,
                                    duration: 8.0
                                ))
                            }
                            ToastDemoButton(label: "Short Duration (1.5s)", color: .teal) {
                                presentToast(ToastValue(
                                    icon: Image(systemName: "bolt.fill"),
                                    message: "Done!",
                                    type: .success,
                                    duration: 1.5
                                ))
                            }
                        }
                    }

                    // ─── Section: With Action Buttons ───
                    ToastSectionView(title: "With Action Buttons", icon: "hand.tap") {
                        VStack(spacing: 10) {
                            ToastDemoButton(label: "Undo Delete", color: .orange) {
                                presentToast(ToastValue(
                                    icon: Image(systemName: "trash"),
                                    message: "Message deleted.",
                                    type: .warning,
                                    duration: 5.0,
                                    button: ToastButton(title: "Undo", color: .orange) {
                                        presentToast(.success("Message restored!"))
                                    }
                                ))
                            }
                            ToastDemoButton(label: "Retry on Error", color: .red) {
                                presentToast(ToastValue(
                                    icon: Image(systemName: "wifi.slash"),
                                    message: "No internet connection.",
                                    type: .error,
                                    duration: 6.0,
                                    button: ToastButton(title: "Retry", color: .red) {
                                        presentToast(.success("Connected!"))
                                    }
                                ))
                            }
                            ToastDemoButton(label: "View Action", color: .blue) {
                                presentToast(ToastValue(
                                    icon: Image(systemName: "envelope.fill"),
                                    message: "3 new messages arrived.",
                                    type: .info,
                                    duration: 5.0,
                                    button: ToastButton(title: "Open", color: .blue) {
                                        presentToast(.info("Opening inbox..."))
                                    }
                                ))
                            }
                            ToastDemoButton(label: "Settings Prompt", color: .gray) {
                                presentToast(ToastValue(
                                    icon: Image(systemName: "bell.slash.fill"),
                                    message: "Notifications are disabled.",
                                    type: .warning,
                                    duration: 6.0,
                                    button: ToastButton(title: "Enable", color: .indigo) {
                                        presentToast(.success("Notifications enabled!"))
                                    }
                                ))
                            }
                        }
                    }

                    // ─── Section: Async / Loading (from ViewModel) ───
                    ToastSectionView(title: "Async / Loading (ViewModel)", icon: "arrow.triangle.2.circlepath") {
                        VStack(spacing: 10) {
                            ToastDemoButton(label: "Upload File (random result)", color: .cyan) {
                                viewModel.simulateAsyncTask()
                            }
                            ToastDemoButton(label: "Sign In Flow", color: .green) {
                                viewModel.simulateLoginTask()
                            }
                        }
                    }

                    // ─── Section: From ViewModel (Direct) ───
                    ToastSectionView(title: "From ViewModel", icon: "server.rack") {
                        VStack(spacing: 10) {
                            ToastDemoButton(label: "ViewModel → Success", color: .green) {
                                viewModel.showSuccess()
                            }
                            ToastDemoButton(label: "ViewModel → Error", color: .red) {
                                viewModel.showError()
                            }
                            ToastDemoButton(label: "ViewModel → Warning", color: .orange) {
                                viewModel.showWarning()
                            }
                            ToastDemoButton(label: "ViewModel → Custom Icon", color: .yellow) {
                                viewModel.showCustomIcon()
                            }
                            ToastDemoButton(label: "ViewModel → With Undo Button", color: .purple) {
                                viewModel.showWithUndoButton()
                            }
                            ToastDemoButton(label: "ViewModel → With Retry Button", color: .red) {
                                viewModel.showWithRetryButton()
                            }
                            ToastDemoButton(label: "ViewModel → With Confirm Button", color: .blue) {
                                viewModel.showWithConfirmButton()
                            }
                        }
                    }

                    // ─── Section: Edge Cases ───
                    ToastSectionView(title: "Edge Cases", icon: "testtube.2") {
                        VStack(spacing: 10) {
                            ToastDemoButton(label: "Long Message (2 lines)", color: .indigo) {
                                viewModel.showLongMessage()
                            }
                            ToastDemoButton(label: "Queue 4 Toasts", color: .mint) {
                                viewModel.showMultipleQueued()
                            }
                            ToastDemoButton(label: "Rapid Fire (tap 3x fast)", color: .pink) {
                                presentToast(.success("Rapid \(Int.random(in: 1...99))"))
                            }
                        }
                    }

                    // ─── Section: Navigation Test ───
                    ToastSectionView(title: "Navigation Test", icon: "arrow.right.circle") {
                        NavigationLink("Push to Child View →") {
                            ToastChildView()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Toast Examples")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// ============================================================
// MARK: - Child View (Navigation Stack Test)
// ============================================================

struct ToastChildView: View {
    @Environment(\.presentToast) var presentToast

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "arrow.up.message.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 32)

                Text("Toasts work above NavigationStack!")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text("These toasts appear above the navigation bar, just like the root view.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Divider().padding(.vertical, 8)

                VStack(spacing: 10) {
                    ToastDemoButton(label: "Show from Child View", color: .blue) {
                        presentToast(.info("Toast from child view!"))
                    }
                    ToastDemoButton(label: "Success from Child", color: .green) {
                        presentToast(.success("Done from inside navigation!"))
                    }
                    ToastDemoButton(label: "Error from Child", color: .red) {
                        presentToast(.error("Error from pushed view."))
                    }
                    ToastDemoButton(label: "From Child ViewModel", color: .purple) {
                        // Direct singleton call — no environment needed
                        ToastManager.shared.present(ToastValue(
                            icon: Image(systemName: "desktopcomputer"),
                            message: "From ViewModel inside child!",
                            type: .success
                        ))
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("Child View")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ============================================================
// MARK: - Reusable UI Helpers
// ============================================================

struct ToastSectionView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.2)
            }
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ToastDemoButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color.opacity(0.6))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(color.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - Previews
// ============================================================

// ✅ Preview 1: Full example — all sections
#Preview("All Toast Examples") {
    PreviewRoot {
        ToastExampleView()
    }
}

// ✅ Preview 2: Dark mode
#Preview("Dark Mode") {
    PreviewRoot {
        ToastExampleView()
    }
    .preferredColorScheme(.dark)
}

// ✅ Preview 3: Child / Navigation view only
#Preview("Child View (Navigation)") {
    PreviewRoot {
        NavigationStack {
            ToastChildView()
        }
    }
}

// ✅ Preview 4: Individual component — just the toast UI itself
#Preview("Toast View — Success") {
    PreviewRoot {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                ToastView(
                    toast: ToastValue(
                        icon: Image(systemName: "checkmark.circle.fill"),
                        message: "Profile saved successfully!",
                        type: .success
                    ),
                    onDismiss: {
						
					}
                )
				
                ToastView(
                    toast: ToastValue(
                        icon: Image(systemName: "xmark.circle.fill"),
                        message: "Network request failed. Please check your connection.",
                        type: .error,
                        button: ToastButton(title: "Retry", color: .red) {}
                    ),
                    onDismiss: {}
                )
				
                ToastView(
                    toast: ToastValue(
                        icon: Image(systemName: "exclamationmark.triangle.fill"),
                        message: "Storage almost full.",
                        type: .warning,
                        button: ToastButton(title: "Manage", color: .orange) {}
                    ),
                    onDismiss: {}
                )
				
                ToastView(
                    toast: ToastValue(
                        message: "Copied to clipboard.",
                        type: .info
                    ),
                    onDismiss: {}
                )
            }
            .padding()
        }
    }
}

// ✅ Preview 5: iPad layout
#Preview("iPad", traits: .fixedLayout(width: 768, height: 1024)) {
    PreviewRoot {
        ToastExampleView()
    }
}
