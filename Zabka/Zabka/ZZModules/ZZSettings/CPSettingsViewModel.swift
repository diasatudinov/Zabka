//
//  CPSettingsViewModel.swift
//  Zabka
//
//  Created by Dias Atudinov on 04.09.2025.
//


import SwiftUI

class CPSettingsViewModel: ObservableObject {
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
}