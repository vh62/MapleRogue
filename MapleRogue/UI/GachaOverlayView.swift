import SwiftUI

/// Post-room skill chooser: 3 rarity-colored cards, tap one to take it
/// and continue immediately. Fast by design — one tap resolves it.
struct GachaOverlayView: View {

    @ObservedObject var viewModel: GameViewModel
    @State private var chosenID: String?

    var body: some View {
        if viewModel.phase == .skillChoice {
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()

                VStack(spacing: 22) {
                    Text("CHOOSE A SKILL")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .kerning(1)
                        .foregroundStyle(.yellow)

                    HStack(spacing: 12) {
                        ForEach(viewModel.offeredSkills) { skill in
                            skillCard(skill)
                        }
                    }
                    .padding(.horizontal, 16)

                    Button {
                        viewModel.skipSkillChoice()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.08), in: Capsule())
                    }
                }
            }
            .transition(.opacity)
            .onAppear { chosenID = nil }
        }
    }

    private func skillCard(_ skill: SkillDefinition) -> some View {
        let tint = color(for: skill.rarity)
        let isChosen = chosenID == skill.id

        return Button {
            guard chosenID == nil else { return }
            chosenID = skill.id
            // Brief beat so the pick lands visually before the run resumes.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                viewModel.chooseSkill(skill)
            }
        } label: {
            VStack(spacing: 8) {
                Text(skill.rarity.displayName.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .kerning(0.5)
                    .foregroundStyle(tint)

                Circle()
                    .fill(tint.opacity(0.25))
                    .overlay(Circle().stroke(tint, lineWidth: 2))
                    .frame(width: 44, height: 44)

                Text(skill.name)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(skill.blurb)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(tint.opacity(isChosen ? 0.3 : 0.1),
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(tint, lineWidth: isChosen ? 3 : 1.5))
            .scaleEffect(isChosen ? 1.06 : (chosenID != nil ? 0.94 : 1))
            .opacity(chosenID != nil && !isChosen ? 0.4 : 1)
            .animation(.bouncy(duration: 0.25), value: chosenID)
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
