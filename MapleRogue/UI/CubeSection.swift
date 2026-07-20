import SwiftUI

private extension GearRarity {
    var cubeColor: Color {
        switch self {
        case .common: Color(red: 0.55, green: 0.58, blue: 0.65)
        case .rare: Color(red: 0.29, green: 0.64, blue: 1.0)
        case .epic: Color(red: 0.72, green: 0.41, blue: 0.95)
        case .legendary: Color(red: 1.0, green: 0.70, blue: 0.22)
        }
    }
}

/// Cube reroll UI inside the Forge: pick an equipped item, roll its
/// potential lines, chase rank-ups. Odds and pity always visible.
struct CubeSection: View {

    @ObservedObject var profileVM: ProfileViewModel

    @State private var selectedSlot: GearSlot = .weapon
    @State private var selectedCube: String = CubeType.basic.id
    @State private var lastResult: CubeSystem.Result?

    private var cube: CubeType {
        selectedCube == CubeType.premium.id ? .premium : .basic
    }

    private var target: GearItem? {
        profileVM.equippedItem(in: selectedSlot)
    }

    var body: some View {
        VStack(spacing: 14) {
            slotPicker

            if let item = target {
                if let pending = profileVM.pendingCube, pending.itemID == item.id {
                    comparisonPanel(item: item, roll: pending.roll)
                } else {
                    cubePicker
                    itemPanel(item)
                    rollButton(item)
                    disclosure(item)
                }
            } else {
                Text("Nothing equipped in this slot")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.vertical, 30)
            }
        }
    }

    // MARK: - Cube picker

    private var cubePicker: some View {
        HStack(spacing: 8) {
            cubeChoice(.basic, subtitle: "\(CubeType.basic.costMesos) mesos · replaces lines")
            cubeChoice(.premium, subtitle: "\(CubeType.premium.costGems) gems · you choose")
        }
    }

    private func cubeChoice(_ candidate: CubeType, subtitle: String) -> some View {
        let selected = selectedCube == candidate.id
        return Button {
            selectedCube = candidate.id
        } label: {
            VStack(spacing: 2) {
                Text(candidate.name)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(selected ? .black : .white.opacity(0.7))
                Text(subtitle)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(selected ? .black.opacity(0.6) : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected
                        ? AnyShapeStyle(candidate.id == "premium" ? Color.purple.opacity(0.9) : .yellow)
                        : AnyShapeStyle(.white.opacity(0.08)),
                        in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Keep-or-replace comparison (premium)

    private func comparisonPanel(item: GearItem, roll: CubeSystem.PendingRoll) -> some View {
        VStack(spacing: 12) {
            Text("CHOOSE YOUR POTENTIAL")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .kerning(1)
                .foregroundStyle(.purple)

            HStack(alignment: .top, spacing: 10) {
                linesColumn(title: "CURRENT", lines: item.potentialLines, highlight: false)
                linesColumn(title: "NEW ROLL", lines: roll.newLines, highlight: true)
            }

            HStack(spacing: 10) {
                Button {
                    profileVM.resolvePendingCube(takeNew: false)
                } label: {
                    Text("Keep Current")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                Button {
                    profileVM.resolvePendingCube(takeNew: true)
                } label: {
                    Text("Take New")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.purple, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(14)
        .background(.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.purple.opacity(0.5), lineWidth: 1.5))
    }

    private func linesColumn(title: String, lines: [PotentialLine], highlight: Bool) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(highlight ? .purple : .white.opacity(0.5))
            ForEach(lines) { line in
                HStack(spacing: 4) {
                    if line.isPrime {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                    }
                    Text(line.stat.format(line.value))
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(line.isPrime ? .yellow : .white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Slot picker

    private var slotPicker: some View {
        HStack(spacing: 8) {
            ForEach(GearSlot.allCases, id: \.self) { slot in
                let item = profileVM.equippedItem(in: slot)
                Button {
                    selectedSlot = slot
                    lastResult = nil
                } label: {
                    EquipSlotView(label: slot.rawValue,
                                  rarity: item?.rarity,
                                  level: item?.level,
                                  size: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedSlot == slot ? .yellow : .clear, lineWidth: 2))
                }
            }
        }
    }

    // MARK: - Item + lines

    private func itemPanel(_ item: GearItem) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text(item.name)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(item.rarity.displayName.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(item.rarity.cubeColor, in: Capsule())
            }

            if item.potentialLines.isEmpty {
                Text("No potential — use a cube to unlock stat lines")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 6) {
                    ForEach(item.potentialLines) { line in
                        HStack(spacing: 6) {
                            if line.isPrime {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.yellow)
                            }
                            Text(line.stat.format(line.value))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(line.isPrime ? .yellow : .white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.white.opacity(line.isPrime ? 0.1 : 0.05),
                                    in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            if let result = lastResult, result.rankedUp {
                Text("RANK UP → \(result.newRank.displayName.uppercased())!")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(result.newRank.cubeColor)
            } else if let roll = profileVM.lastAutoAppliedRoll, roll.rankedUp {
                Text("RANK UP → \(roll.newRank.displayName.uppercased())!")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(roll.newRank.cubeColor)
            }
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(item.rarity.cubeColor.opacity(0.5), lineWidth: 1.5))
    }

    // MARK: - Roll

    private func rollButton(_ item: GearItem) -> some View {
        let affordable = profileVM.canAffordCube(cube)
        let isPremium = cube.id == CubeType.premium.id
        let costLabel = isPremium ? "\(cube.costGems) gems" : "\(cube.costMesos) mesos"

        return Button {
            withAnimation(.bouncy) {
                if isPremium {
                    profileVM.usePremiumCube(on: item.id)
                } else {
                    lastResult = profileVM.useCube(cube, on: item.id)
                }
            }
        } label: {
            Text("\(cube.name.uppercased())  ·  \(costLabel)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(affordable ? (isPremium ? .white : .black) : .white.opacity(0.35))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(affordable
                            ? (isPremium ? AnyShapeStyle(Color.purple) : AnyShapeStyle(.yellow))
                            : AnyShapeStyle(.white.opacity(0.08)),
                            in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!affordable)
    }

    // MARK: - Odds disclosure (guideline 3.1.1)

    private func disclosure(_ item: GearItem) -> some View {
        VStack(spacing: 3) {
            if item.rarity < cube.maxRank {
                Text("Rank-up chance: \(Int(cube.rankUpChance * 100))%  ·  guaranteed within \(cube.pityThreshold) (\(cube.pityThreshold - item.cubePity) to pity)")
            } else {
                Text("This cube ranks up to \(cube.maxRank.displayName) (reached)")
            }
            Text("Rerolls all lines · \(PotentialPool.lineCount(for: item.rarity)) line(s) at \(item.rarity.displayName) · Prime chance \(Int(PotentialPool.primeChance * 100))% on line 1")
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(.white.opacity(0.45))
        .multilineTextAlignment(.center)
    }
}
