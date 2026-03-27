//
//  ComplationScreenType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/27/26.
//

import Foundation

enum ComplationScreenType {
    case otpVerified
    case accountCreation

    var screenTitle: LocalizedStringResource {
        switch self {
        case .otpVerified:
            return .yourPhoneNumberHasBeenVerified
        case .accountCreation:
            return .raceReadyProfile
        }
    }

    var screenDescription: LocalizedStringResource {
        switch self {
        case .otpVerified:
            return .youWillSoonBeDirectedToTheMainPage
        case .accountCreation:
            return .yourSetupIsCompleteTimeToHitYourTargetPace
        }
    }
}
