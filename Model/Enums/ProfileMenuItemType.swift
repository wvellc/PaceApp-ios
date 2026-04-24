//
//  ProfileMenuItemType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

enum ProfileMenuItemType {
    case navigation
    case toggle(binding: (Bool) -> Void, value: Bool)
}
