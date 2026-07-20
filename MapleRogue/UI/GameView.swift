import SwiftUI
import SpriteKit

/// Hosts one run: the SpriteKit scene plus HUD and end-of-run overlays.
struct GameView: View {

    @ObservedObject var profileVM: ProfileViewModel
    @StateObject private var viewModel = GameViewModel()
    @State private var sceneID = UUID()

    let onExitToMenu: () -> Void

    var body: some View {
        ZStack {
            SpriteView(scene: makeScene())
                .id(sceneID)
                .ignoresSafeArea()

            HUDView(viewModel: viewModel)

            GachaOverlayView(viewModel: viewModel)

            PauseOverlay(viewModel: viewModel, onExitToMenu: onExitToMenu)

            RunEndOverlay(viewModel: viewModel, onExitToMenu: onExitToMenu)
        }
        .statusBarHidden()
        .onAppear {
            viewModel.onRestartRequested = { sceneID = UUID() }
            viewModel.onRunEnded = { gold, xp, roomReached, victory in
                let levelsGained = profileVM.bankRun(goldEarned: gold,
                                                     xpEarned: xp,
                                                     roomReached: roomReached,
                                                     victory: victory)
                if levelsGained > 0 {
                    viewModel.leveledUpTo = profileVM.profile.level
                }
                if victory {
                    viewModel.victoryLoot = profileVM.rollVictoryLoot()
                }
            }
        }
    }

    /// A fresh scene per sceneID — changing the id tears down the old
    /// SpriteView and starts a brand-new run. Class stats set the baseline;
    /// weapon stars raise base damage on top.
    private func makeScene() -> SKScene {
        GameScene(viewModel: viewModel,
                  size: CGSize(width: 750, height: 1334),
                  heroClass: profileVM.selectedClass,
                  build: profileVM.heroBuild)
    }
}
