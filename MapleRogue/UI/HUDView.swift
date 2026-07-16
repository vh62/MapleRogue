import SwiftUI

/// In-game HUD: HP bar and room counter. Pure rendering — no game logic.
struct HUDView: View {

    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    healthBar
                    pauseButton
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    roomCounter
                    goldCounter
                    tokenCounter
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            if let fraction = viewModel.bossHealthFraction {
                bossHealthBar(fraction: fraction)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.bossHealthFraction == nil)
    }

    private func bossHealthBar(fraction: Double) -> some View {
        VStack(spacing: 4) {
            Text(viewModel.bossName)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 2)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.black.opacity(0.6))
                Capsule()
                    .fill(LinearGradient(colors: [.red, .purple],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: 260 * fraction)
                    .animation(.easeOut(duration: 0.15), value: fraction)
            }
            .frame(width: 260, height: 14)
            .overlay(Capsule().stroke(.white.opacity(0.4), lineWidth: 1))
        }
    }

    private var healthBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.black.opacity(0.5))
                    Capsule()
                        .fill(healthColor)
                        .frame(width: geo.size.width * viewModel.heroHealthFraction)
                        .animation(.easeOut(duration: 0.2), value: viewModel.heroHealthFraction)
                }
            }
            .frame(width: 180, height: 18)
            .overlay(
                Text("\(viewModel.heroHP) / \(viewModel.heroMaxHP)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            )
        }
    }

    private var healthColor: Color {
        switch viewModel.heroHealthFraction {
        case ..<0.25: .red
        case ..<0.5: .orange
        default: .green
        }
    }

    private var goldCounter: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.yellow)
                .frame(width: 12, height: 12)
            Text("\(viewModel.gold)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.yellow)
                .contentTransition(.numericText())
                .animation(.snappy, value: viewModel.gold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.black.opacity(0.5), in: Capsule())
    }

    private var pauseButton: some View {
        Button {
            viewModel.pause()
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 34, height: 34)
                .background(.black.opacity(0.5), in: Circle())
        }
    }

    private var tokenCounter: some View {
        HStack(spacing: 4) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 11))
                .foregroundStyle(.cyan)
            Text("\(viewModel.skillTokens)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.black.opacity(0.5), in: Capsule())
    }

    private var roomCounter: some View {
        Text("Room \(viewModel.currentRoom) / \(viewModel.totalRooms)")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.5), in: Capsule())
    }
}

/// Pause menu: resume, restart, or bail to the lobby.
struct PauseOverlay: View {

    @ObservedObject var viewModel: GameViewModel
    let onExitToMenu: () -> Void

    var body: some View {
        if viewModel.phase == .paused {
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()

                VStack(spacing: 18) {
                    Text("PAUSED")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Room \(viewModel.currentRoom) / \(viewModel.totalRooms)  ·  \(viewModel.gold) gold")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))

                    Button {
                        viewModel.resume()
                    } label: {
                        Text("Resume")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(width: 220)
                            .padding(.vertical, 14)
                            .background(.yellow, in: Capsule())
                    }

                    Button {
                        viewModel.abandonRun()
                        viewModel.restart()
                    } label: {
                        Text("Restart Run")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 220)
                            .padding(.vertical, 11)
                            .background(.white.opacity(0.15), in: Capsule())
                    }

                    Button {
                        viewModel.abandonRun()
                        onExitToMenu()
                    } label: {
                        Text("Exit to Home")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 220)
                            .padding(.vertical, 11)
                            .background(.white.opacity(0.15), in: Capsule())
                    }

                    Text("Gold earned so far is kept when you leave")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
    }
}

/// Full-screen overlay for death / victory with a restart button.
struct RunEndOverlay: View {

    @ObservedObject var viewModel: GameViewModel
    let onExitToMenu: () -> Void

    var body: some View {
        if viewModel.phase == .dead || viewModel.phase == .victory {
            ZStack {
                Color.black.opacity(0.7).ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(viewModel.phase == .victory ? "RUN COMPLETE!" : "YOU DIED")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(viewModel.phase == .victory ? .yellow : .red)

                    Text(viewModel.phase == .victory
                         ? "Cleared all \(viewModel.totalRooms) rooms"
                         : "Made it to room \(viewModel.currentRoom)")
                        .font(.system(size: 18, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))

                    HStack(spacing: 16) {
                        Label("\(viewModel.gold)", systemImage: "circle.fill")
                            .foregroundStyle(.yellow)
                        Label("+\(viewModel.runXP) XP", systemImage: "arrow.up.circle.fill")
                            .foregroundStyle(.cyan)
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))

                    if let newLevel = viewModel.leveledUpTo {
                        Text("LEVEL UP!  Lv \(newLevel)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 8)
                            .background(.yellow.opacity(0.15), in: Capsule())
                            .overlay(Capsule().stroke(.yellow.opacity(0.5), lineWidth: 1.5))
                    }

                    Button {
                        viewModel.restart()
                    } label: {
                        Text("Try Again")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(.yellow, in: Capsule())
                    }

                    Button(action: onExitToMenu) {
                        Text("Home")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.15), in: Capsule())
                    }
                }
            }
        }
    }
}
