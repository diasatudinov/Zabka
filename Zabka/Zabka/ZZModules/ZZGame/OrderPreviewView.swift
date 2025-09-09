import SwiftUI
} else {
state.matchedKinds.insert(product.kind)
state.matchedFreshnessWeights.append(product.freshness.scoreMultiplier)
}
} else {
// Wrongly sent to order box
state.wrongInOrder += 1
}
case .good:
if !isRequired {
// Save for next level if at least acceptable
if product.freshness != .rotten {
state.addCarryOver(product)
}
} else {
// Sent required item to Good (not counted as matched)
// We'll penalize as "wrong in order" light penalty to discourage
state.wrongInOrder += 1
}
case .trash:
if isRequired {
// Big mistake will be covered by missedRequired at end (not matched)
state.wrongInOrder += 1
}
// else discard silently
}
}
}


// MARK: - UI Components


struct OrderPreviewView: View {
let order: OrderSpec
var body: some View {
VStack(alignment: .leading, spacing: 12) {
Text(order.title).font(.title2).bold()
Text(order.description).font(.subheadline).foregroundColor(.secondary)
Divider().opacity(0.3)
VStack(alignment: .leading, spacing: 8) {
ForEach(order.required, id: \.self) { kind in
HStack {
Circle().fill(.green).frame(width: 8, height: 8)
Text(kind.display)
if order.strictFreshOnly {
Text("(только свежий)").foregroundColor(.yellow).font(.caption)
}
}
}
}
.font(.headline)
}
.padding()
.frame(maxWidth: .infinity)
.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
.padding(.top, 10)
.padding(.horizontal)
}
}


struct ResultsView: View {
let percent: Int
let passed: Bool
let onContinue: () -> Void


var body: some View {
VStack(spacing: 16) {
Capsule().fill(Color.secondary.opacity(0.4)).frame(width: 60, height: 6).padding(.top, 8)
Text("Итоги уровня").font(.title2).bold()
Text("Соответствие заказу: \(percent)%").font(.title3)
Text(passed ? "Уровень пройден!" : "Не достигнут порог 70%")
.font(.headline)
.foregroundColor(passed ? .green : .red)
Button(action: onContinue) {
Text(passed ? "Дальше →" : "Повторить")
.font(.headline)
.frame(maxWidth: .infinity)
.padding()
.background(passed ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
.foregroundColor(.white)
.clipShape(RoundedRectangle(cornerRadius: 14))
}
.padding(.horizontal)
Spacer()
}
}
}