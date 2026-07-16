import SwiftUI

/// Full-screen gacha shown between rooms. Pull skills with tokens,
/// then continue the run.
struct GachaOverlayView: View {

    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        if viewModel.phase == .gacha {
            ZStack {
                Color.black.opacity(0.85).ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("SKILL GACHA")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.yellow)

                    HStack(spacing: 16) {
                        Label("\(viewModel.skillTokens)", systemImage: "ticket.fill")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.cyan)
                        Text("Pity in \(viewModel.pullsUntilPity)")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    resultCard
                        .frame(height: 200)

                    oddsTable

                    Button(action: viewModel.pullSkill) {
                        Text("PULL  (1 token)")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundStyle(viewModel.skillTokens > 0 ? .black : .white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.skillTokens > 0 ? .yellow : Color.white.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.skillTokens == 0)
                    .padding(.horizontal, 40)

                    Button(action: viewModel.finishGacha) {
                        Text("Continue Run")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.15), in: Capsule())
                    }
                }
                .padding(24)
            }
        }
    }

    @ViewBuilder
    private var resultCard: some View {
        if let skill = viewModel.lastPull {
            VStack(spacing: 10) {
                Text(skill.rarity.displayName.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(color(for: skill.rarity))
                Text(skill.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(skill.blurb)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(color(for: skill.rarity).opacity(0.12))
                    .stroke(color(for: skill.rarity), lineWidth: 2)
            )
            .padding(.horizontal, 40)
            .transition(.scale(scale: 0.7).combined(with: .opacity))
            .id(viewModel.acquiredSkills.count)   // re-animate every pull
            .animation(.bouncy(duration: 0.4), value: viewModel.acquiredSkills.count)
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(0.05))
                .stroke(.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8]))
                .overlay(
                    Text("?")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                )
                .padding(.horizontal, 40)
        }
    }

    /// App Store guideline 3.1.1 requires disclosing gacha odds.
    private var oddsTable: some View {
        HStack(spacing: 14) {
            ForEach(Rarity.allCases, id: \.self) { rarity in
                VStack(spacing: 2) {
                    Text(rarity.displayName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(color(for: rarity))
                    Text("\(Int(rarity.weight))%")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    private func color(for rarity: Rarity) -> Color {
        switch rarity {
        case .common: .gray
        case .rare: .blue
        case .epic: .purple
        case .unique: .orange
        case .legendary: .yellow
        }
    }
}
