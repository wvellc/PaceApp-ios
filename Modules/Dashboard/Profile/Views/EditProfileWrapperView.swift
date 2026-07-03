//
//  EditProfileWrapperView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/3/26.
//
//  Thin environment-reading wrapper so the router can push EditProfileScreen
//  without needing to pass a ProfileViewModel argument through NavigationPath.
//  ProfileScreen injects its own viewModel into the environment before calling
//  router.navigate(to: .editProfile).
//

import SwiftUI

/// Reads `ProfileViewModel` from the SwiftUI environment and renders `EditProfileScreen`.
///
/// `ProfileScreen` must inject its viewModel into the environment on the destination view:
/// ```swift
/// Button("Edit Profile") {
///     router.navigate(to: .editProfile)
/// }
/// ```
/// The `.environment(viewModel)` is attached inside PaceApp.swift on the
/// `navigationDestination` resolver via `Router+Destination.swift`.
struct EditProfileWrapperView: View {

    @Environment(ProfileViewModel.self) private var viewModel

    var body: some View {
        EditProfileScreen(viewModel: viewModel)
    }
}
