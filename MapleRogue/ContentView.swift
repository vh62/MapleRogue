//
//  ContentView.swift
//  MapleRogue
//
//  Created by Vikram Ho on 4/7/26.
//

import SwiftUI

/// App root: owns the persistent profile and switches between
/// the landing menu and an active run.
struct ContentView: View {

    private enum Screen {
        case menu
        case game
    }

    @StateObject private var profileVM = ProfileViewModel()
    @State private var screen: Screen = .menu

    var body: some View {
        switch screen {
        case .menu:
            MainMenuView(profileVM: profileVM,
                         onStartRun: { screen = .game })
        case .game:
            GameView(profileVM: profileVM,
                     onExitToMenu: { screen = .menu })
        }
    }
}

#Preview {
    ContentView()
}
