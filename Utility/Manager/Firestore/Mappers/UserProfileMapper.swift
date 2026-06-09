//
//  UserProfileMapper.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore

enum UserProfileMapper {

    // MARK: - Model → Document

    static func document(from model: UserModel, userId: String) -> FirestoreUserDocument {
        FirestoreUserDocument(
            uuid: userId,
            firstName: model.firstName ?? "",
            lastName: model.lastName ?? "",
            gender: model.gender?.rawValue ?? "",
            email: model.email ?? "",
            phoneNumber: model.phoneNumber ?? "",
            lastSyncedAt: Timestamp(date: Date()),
            gait: model.gait.map { gaitDocument(from: $0) },
            intervalVibrate: model.intervalVibrate,
            intervalBeep: model.intervalBeep,
            distanceUnit: model.distanceUnit?.rawValue
        )
    }

    // MARK: - Document → Model

    static func userModel(from document: FirestoreUserDocument, userId: String) -> UserModel {
        var model = UserModel(uuid: userId)
        model.firstName = document.firstName.nilIfEmpty
        model.lastName = document.lastName.nilIfEmpty
        if let gender = Gender(rawValue: document.gender) {
            model.gender = gender
        }
        model.email = document.email.nilIfEmpty
        model.phoneNumber = document.phoneNumber.nilIfEmpty

        // Settings
        if let gaitDoc = document.gait {
            model.gait = gaitData(from: gaitDoc)
        }
        model.intervalVibrate = document.intervalVibrate ?? false
        model.intervalBeep = document.intervalBeep ?? false
        if let unitRaw = document.distanceUnit, let unit = MeasureUnit(rawValue: unitRaw) {
            model.distanceUnit = unit
        } else {
            model.distanceUnit = .miles
        }
        return model
    }

    // MARK: - Gait Helpers

    static func gaitDocument(from gait: GaitUserData) -> FirestoreGaitDocument {
        FirestoreGaitDocument(
            walkingStepLength: gait.walkingData.stepLength,
            walkingUnit: gait.walkingData.unit,
            runningStepLength: gait.runningData.stepLength,
            runningUnit: gait.runningData.unit
        )
    }

    static func gaitData(from doc: FirestoreGaitDocument) -> GaitUserData {
        GaitUserData(
            walkingData: GaitData(stepLength: doc.walkingStepLength, unit: doc.walkingUnit),
            runningData: GaitData(stepLength: doc.runningStepLength, unit: doc.runningUnit)
        )
    }
}
