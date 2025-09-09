
// ConveyorSorterGame.swift
// SwiftUI + SpriteKit prototype for "Conveyor Sorter"
// iOS 16.0 (Xcode 14+). Single-file sample; split into files as needed.
//
// Features:
// - Core loop: pre-level order preview (memorize!), conveyor spawns items, drag to 3 bins
// - Levels scale speed/lanes/time; every 2 levels adds a lane
// - "Пригодно" carry-over: items degrade by one freshness step and reappear next level
// - Scoring: percent match vs order + basic penalties; pass threshold 70%
// - Simple isometric-styled belts (visual tilt), can be swapped for art later
//
// NOTE: Uses colored nodes + short labels for products. Replace with textures when you have assets.

import SwiftUI
import SpriteKit
import Combine

// MARK: - Game Models

enum Freshness: Int, Codable, CaseIterable {
    case rotten = 0
    case acceptable = 1
    case fresh = 2

    var nextLower: Freshness? {
        switch self {
        case .fresh: return .acceptable
        case .acceptable: return .rotten
        case .rotten: return nil
        }
    }

    var scoreMultiplier: Double { // general weighting (except strict level 2)
        switch self {
        case .fresh: return 1.0
        case .acceptable: return 0.7
        case .rotten: return 0.0
        }
    }

    var uiColor: UIColor {
        switch self {
        case .fresh: return .systemGreen
        case .acceptable: return .systemYellow
        case .rotten: return .systemBrown
        }
    }

    var display: String {
        switch self {
        case .fresh: return "Свежий"
        case .acceptable: return "Приемлемый"
        case .rotten: return "Гнилой"
        }
    }
}

enum ProductKind: String, CaseIterable, Codable {
    // Овощи
    case tomato, cucumber, eggplant, carrot, cabbage, potato, onion, broccoli
    // Фрукты
    case apple, banana, orange, grape, pear, lemon, strawberry, pineapple

    var isFruit: Bool {
        switch self {
        case .apple, .banana, .orange, .grape, .pear, .lemon, .strawberry, .pineapple:
            return true
        default:
            return false
        }
    }

    var display: String {
        switch self {
        case .tomato: return "Помидор"
        case .cucumber: return "Огурец"
        case .eggplant: return "Баклажан"
        case .carrot: return "Морковь"
        case .cabbage: return "Капуста"
        case .potato: return "Картофель"
        case .onion: return "Лук"
        case .broccoli: return "Брокколи"
        case .apple: return "Яблоко"
        case .banana: return "Банан"
        case .orange: return "Апельсин"
        case .grape: return "Виноград"
        case .pear: return "Груша"
        case .lemon: return "Лимон"
        case .strawberry: return "Клубника"
        case .pineapple: return "Ананас"
        }
    }

    var short: String {
        // 2–3 letters for node labels
        let map: [ProductKind: String] = [
            .tomato:"Tom", .cucumber:"Cuc", .eggplant:"Egg", .carrot:"Car", .cabbage:"Cab", .potato:"Pot", .onion:"On", .broccoli:"Bro",
            .apple:"App", .banana:"Ban", .orange:"Orn", .grape:"Grp",
            .pear:"Per", .lemon:"Lem", .strawberry:"Str", .pineapple:"Pin"
        ]
        return map[self] ?? String(display.prefix(3))
    }
}

// ADD: рядом с Freshness
extension Freshness {
    var assetSuffix: String {
        switch self {
        case .fresh: return "fresh"
        case .acceptable: return "ok"
        case .rotten: return "rotten"
        }
    }
}

// ADD: рядом с ProductKind
extension ProductKind {
    /// Базовое имя для ассета (без состояния)
    var assetBaseName: String { "prod_\(rawValue)" }
}

struct Product: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: ProductKind
    var freshness: Freshness
    var fromCarryOver: Bool

    init(kind: ProductKind, freshness: Freshness, fromCarryOver: Bool = false, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.freshness = freshness
        self.fromCarryOver = fromCarryOver
    }
}

enum BinType: String { case order, good, trash }

struct OrderSpec {
    let title: String
    let description: String
    let required: [ProductKind]
    let strictFreshOnly: Bool // Level 2: only "fresh" counts
}

struct LevelConfig {
    let level: Int
    let lanes: Int
    let spawnInterval: TimeInterval
    let conveyorSpeed: CGFloat
    let timeLimit: TimeInterval
    let moveLimit: Int
    let order: OrderSpec

    static func forLevel(_ n: Int) -> LevelConfig {
        let lanes = 1 + (n - 1) / 2 // add a lane every 2 levels
        let spawnInterval = max(0.7, 1.6 - Double(n) * 0.2) // faster spawns each level
        let conveyorSpeed: CGFloat = 120 + CGFloat(n) * 30 // px per second
        let timeLimit: TimeInterval = max(35, 55 - Double(n) * 5)
        let moveLimit = max(18, 28 - n * 3)
        var orders: [OrderSpec] = [
            OrderSpec(
                title: "Фруктовый смузи",
                description: "Нам нужны фрукты для свежего летнего смузи! Собери яркие, спелые плоды.",
                required: [.apple, .banana, .orange, .strawberry],
                strictFreshOnly: false
            ),
            OrderSpec(
                title: "Салат из свежих овощей",
                description: "Только самые свежие овощи. Никаких уступок по качеству!",
                required: [.cucumber, .tomato, .broccoli],
                strictFreshOnly: true
            ),
            
            OrderSpec(
                title: "Салат из свежих фрукты",
                description: "Только самые свежие фрукты. Никаких уступок по качеству!",
                required: [.eggplant, .grape, .apple, .lemon],
                strictFreshOnly: true
            )
        ]
        let order: OrderSpec
        order = orders.randomElement() ?? OrderSpec(
            title: "Салат из свежих фрукты",
            description: "Только самые свежие фрукты. Никаких уступок по качеству!",
            required: [.eggplant, .grape, .apple, .lemon],
            strictFreshOnly: true
        )

        return LevelConfig(level: n, lanes: lanes, spawnInterval: spawnInterval, conveyorSpeed: conveyorSpeed, timeLimit: timeLimit, moveLimit: moveLimit, order: order)
    }
}

// MARK: - SwiftUI Game State

final class GameState: ObservableObject {
    @Published var level: Int = 1
    @Published var config: LevelConfig = .forLevel(1)
    @Published var timeLeft: TimeInterval = 0
    @Published var movesLeft: Int = 0
    @Published var showOrderPreview: Bool = true
    @Published var showResults: Bool = false
    @Published var resultPercent: Int = 0
    @Published var passed: Bool = false

    // progress
    @Published var matchedKinds: Set<ProductKind> = []
    @Published var matchedFreshnessWeights: [Double] = [] // used for average multiplier
    @Published var wrongInOrder: Int = 0
    @Published var missedRequired: Int = 0

    // carry-over inventory (degraded next level)
    private(set) var carryOver: [Product] = []

    private var timerCancellable: AnyCancellable?

    func startLevel() {
        config = .forLevel(level)
        timeLeft = config.timeLimit
        movesLeft = config.moveLimit
        showOrderPreview = true
        showResults = false
        resultPercent = 0
        passed = false

        matchedKinds = []
        matchedFreshnessWeights = []
        wrongInOrder = 0
        missedRequired = 0

        // Order preview for 4 seconds, then start ticking
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.showOrderPreview = false
            self.beginTimer()
        }
    }

    func nextLevelOrRetry(passed: Bool) {
        if passed {
           // level += 1
        }
        startLevel()
    }

    func useMove() {
        if movesLeft > 0 { movesLeft -= 1 }
        if movesLeft == 0 { endLevel(reason: .outOfMoves) }
    }

    private func beginTimer() {
        timerCancellable?.cancel()
        let start = Date()
        timerCancellable = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.timeLeft = max(0, self.config.timeLimit - Date().timeIntervalSince(start))
                if self.timeLeft <= 0 {
                    self.endLevel(reason: .timeUp)
                }
            }
    }

    enum EndReason { case timeUp, outOfMoves, finishedStream, noReason }

    func endLevel(reason: EndReason) {
        timerCancellable?.cancel()
        // Missed required = required that we never matched
        let required = Set(config.order.required)
        let unmatchedRequired = required.subtracting(matchedKinds)
        missedRequired = unmatchedRequired.count

        // base completion based on matched ratio
        let baseRatio: Double
        if required.isEmpty {
            baseRatio = 1
        } else {
            baseRatio = Double(matchedKinds.count) / Double(required.count)
        }

        // average freshness multiplier for matched items (fallback 1)
        let avgFreshMult = matchedFreshnessWeights.isEmpty ? 1.0 : (matchedFreshnessWeights.reduce(0, +) / Double(matchedFreshnessWeights.count))

        var percent = baseRatio * 100.0 * avgFreshMult

        // penalties
        percent -= Double(missedRequired) * 25.0
        percent -= Double(wrongInOrder) * 10.0

        resultPercent = max(0, min(100, Int(round(percent))))
        passed = resultPercent >= 70
        if passed {
            CPUser.shared.updateUserMoney(for: 100)
        }
        if reason != .noReason {
            showResults = true
        }
    }

    func addCarryOver(_ p: Product) {
        var degraded = p
        if let next = p.freshness.nextLower {
            degraded.freshness = next
        }
        degraded.fromCarryOver = true
        carryOver.append(degraded)
    }

    func takeCarryOverBatch() -> [Product] {
        let batch = carryOver
        carryOver.removeAll()
        return batch
    }
}

// MARK: - SpriteKit Scene & Nodes

final class ProductNode: SKSpriteNode {
    let product: Product

    init(product: Product) {
        self.product = product
        let tex = textureForProduct(product)
        let targetHeight: CGFloat = 56
        let scale = targetHeight / max(tex.size().height, 1)
        super.init(texture: tex, color: .clear, size: CGSize(width: tex.size().width * scale,
                                                             height: tex.size().height * scale))
        self.name = "product"
        self.zPosition = 5
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.run(pulseAction())
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func pulseAction() -> SKAction {
        let up = SKAction.scale(to: 1.04, duration: 0.5)
        let dn = SKAction.scale(to: 1.0, duration: 0.5)
        return .repeatForever(.sequence([up, dn]))
    }
    
}

func textureForProduct(_ product: Product) -> SKTexture {
    let name = "\(product.kind.assetBaseName)_\(product.freshness.assetSuffix)"
    return SKTexture(imageNamed: name)
}

final class ConveyorScene: SKScene {
    // Config
    var gameConfig: LevelConfig!
    var onDrop: ((Product, BinType) -> Void)?
    var onMiss: ((Product) -> Void)?
    var onExhaustedStream: (() -> Void)? // called when stream ends (optional)

    private var laneY: [CGFloat] = []
    private var spawnTimer: Timer?
    private var productsToPrepend: [Product] = [] // carry-over batch
    private var randomPool: [ProductKind] = ProductKind.allCases
    private var streamCount: Int = 0
    private var maxStream: Int = 28 // adjusted per level in configure

    // drag state
    private var dragged: ProductNode?

    // bins
    private var binOrder: SKSpriteNode!
    private var binGood: SKSpriteNode!
    private var binTrash: SKSpriteNode!

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .clear
    }

    func configure(config: LevelConfig, carryOver: [Product]) {
        removeAllChildren()
        removeAllActions()
        spawnTimer?.invalidate()

        self.gameConfig = config
        self.productsToPrepend = carryOver
        self.maxStream = max(18, 22 + (config.level - 1) * 6)

        buildScene()
        startSpawning()
    }

    private func buildScene() {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height

        // Belts (lanes) with isometric slant
        laneY.removeAll()
        let topMargin: CGFloat = h * 0.62
        let laneHeight: CGFloat = 56
        for i in 0..<gameConfig.lanes {
            let y = topMargin - CGFloat(i) * (laneHeight + 10)
            laneY.append(y)

            let path = UIBezierPath()
            let beltWidth = w * 0.95
            let originX = 0.0
            let tilt: CGFloat = 18 // pixels of skew
            // Parallelogram
            path.move(to: CGPoint(x: originX, y: y))
            path.addLine(to: CGPoint(x: originX + beltWidth, y: y + tilt))
            path.addLine(to: CGPoint(x: originX + beltWidth, y: y + tilt - laneHeight))
            path.addLine(to: CGPoint(x: originX, y: y - laneHeight))
            path.close()

            let belt = SKShapeNode(path: path.cgPath)
            belt.fillColor = UIColor(white: 0.15, alpha: 0.9)
            belt.strokeColor = UIColor(white: 0.35, alpha: 1)
            belt.lineWidth = 2
            belt.zPosition = 1
            addChild(belt)

            // moving stripes for conveyor feel
            let stripe = SKShapeNode(rectOf: CGSize(width: 18, height: laneHeight - 10), cornerRadius: 4)
            stripe.fillColor = .darkGray
            stripe.strokeColor = .clear
            stripe.alpha = 0.35
            stripe.zPosition = 2
            stripe.position = CGPoint(x: 0.0, y: y - laneHeight * 0.5 + tilt * 0.5)
            addChild(stripe)
            let move = SKAction.moveBy(x: beltWidth * 0.86, y: 0, duration: 1.4)
            stripe.run(.repeatForever(.sequence([move, .moveBy(x: -beltWidth * 0.86, y: 0, duration: 0.0)])))
        }

        // Bins area
        let binSize = CGSize(width: 170, height: 130)
        let yBin = h * 0.2
        binOrder = makeBin(imageName: "bin_order", title: "", size: binSize)
        binOrder.position = CGPoint(x: w * 0.2, y: yBin)
        addChild(binOrder)

        binGood = makeBin(imageName: "bin_good", title: "", size: binSize)
        binGood.position = CGPoint(x: UIScreen.main.bounds.width / 2, y: yBin)
        addChild(binGood)

        binTrash = makeBin(imageName: "bin_trash", title: "", size: binSize)
        binTrash.position = CGPoint(x: w * 0.8, y: yBin)
        addChild(binTrash)
    }

    private func makeBin(imageName: String, title: String, size: CGSize) -> SKSpriteNode {
        let tex = SKTexture(imageNamed: imageName)
        // Подгоняем текстуру под заданный размер (центрированная)
        let node = SKSpriteNode(texture: tex)
        node.size = size
        node.name = "bin"
        node.zPosition = 3

        // Заголовок над ящиком
        let label = SKLabelNode(fontNamed: "Avenir-Heavy")
        label.text = title
        label.fontSize = 16
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: size.height/2 + 20)
        label.zPosition = 4
        node.addChild(label)

        return node
    }

    private func startSpawning() {
        streamCount = 0
        // Use Timer for simple control; stops automatically on invalidate
        spawnTimer = Timer.scheduledTimer(withTimeInterval: gameConfig.spawnInterval, repeats: true) { [weak self] t in
            guard let self = self else { return }
            self.spawnOne()
        }
    }

    private func spawnOne() {
        guard streamCount < maxStream else {
            spawnTimer?.invalidate()
            onExhaustedStream?()
            return
        }
        streamCount += 1

        // Decide product: use carry-over first
        let product: Product
        if !productsToPrepend.isEmpty {
            product = productsToPrepend.removeFirst()
        } else {
            // Bias towards order items so player can complete
            let required = gameConfig.order.required
            let pool: [ProductKind] = (0..<3).map { _ in required.randomElement() ?? randomPool.randomElement()! } + [randomPool.randomElement()!]
            let kind = pool.randomElement() ?? randomPool.randomElement()!
            let freshness: Freshness = {
                // Make order items more likely to be fresh
                if required.contains(kind) {
                    return [.fresh, .fresh, .acceptable].randomElement()!
                } else {
                    return Freshness.allCases.randomElement()!
                }
            }()
            product = Product(kind: kind, freshness: freshness)
        }

        let node = ProductNode(product: product)
        node.name = "product"
        let laneIdx = Int.random(in: 0..<gameConfig.lanes)
        let y = laneY[laneIdx] - 28 // center on belt
        let startX = 0.0
        let endX = UIScreen.main.bounds.width * 0.9
        node.position = CGPoint(x: startX, y: y)
        addChild(node)

        let travel = endX - startX
        let duration = TimeInterval(travel / gameConfig.conveyorSpeed)
        node.run(.sequence([
            .moveTo(x: endX, duration: duration),
            .run { [weak self, weak node] in
                guard let self = self, let node = node else { return }
                self.onMiss?(node.product)
                node.removeFromParent()
            }
        ]), withKey: "move")
    }

    // MARK: - Touches (drag & drop)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard dragged == nil, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        if let node = nodes(at: loc).first(where: { $0.name == "product" }) as? ProductNode {
            dragged = node
            node.removeAction(forKey: "move")
            node.setScale(1.08)
            node.zPosition = 10
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragged = dragged else { return }
        let loc = touch.location(in: self)
        dragged.position = loc
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let dragged = dragged else { return }
        defer { self.dragged = nil }

        let bin: BinType? = {
            if dragged.frame.intersects(binOrder.frame) { return .order }
            if dragged.frame.intersects(binGood.frame) { return .good }
            if dragged.frame.intersects(binTrash.frame) { return .trash }
            return nil
        }()

        if let bin = bin {
            onDrop?(dragged.product, bin)
            dragged.removeFromParent()
        } else {
            // Return to belt and continue moving
            dragged.setScale(1.0)
            dragged.zPosition = 5
            let endX = UIScreen.main.bounds.width * 0.46
            let remaining = endX - dragged.position.x
            let duration = TimeInterval(max(0.1, remaining / gameConfig.conveyorSpeed))
            dragged.run(.sequence([
                .moveTo(x: endX, duration: duration),
                .run { [weak self, weak dragged] in
                    guard let self = self, let dragged = dragged else { return }
                    self.onMiss?(dragged.product)
                    dragged.removeFromParent()
                }
            ]), withKey: "move")
        }
    }
}


// MARK: - SwiftUI Views

struct GameView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject var state = GameState()
    @State private var scene = ConveyorScene(size: UIScreen.main.bounds.size)
    @State var level: Int
    var body: some View {
        ZStack {
            Image(.gameViewBgZZ)
                .resizable()
                .ignoresSafeArea()
                .scaledToFill()
                

            CPSpriteViewContainer(scene: scene, level: level)
                .ignoresSafeArea()

            hud
            
            VStack {
                Spacer()
                HStack {
                    Button {
                        state.endLevel(reason: .noReason)
                        presentationMode.wrappedValue.dismiss()
                       
                    } label: {
                        Image(.backIconZZ)
                            .resizable()
                            .scaledToFit()
                            .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:50)
                    }
                    
                    Spacer()
                    
                    
                }.padding()
            }
        }
        .onAppear { setupSceneAndStart() }
        .sheet(isPresented: $state.showResults) {
            ResultsView(percent: state.resultPercent, passed: state.passed) {
                
                presentationMode.wrappedValue.dismiss()
                
                reconfigureScene()
            }
            .presentationDetents([.fraction(0.5)])
        }
        .overlay(alignment: .top) {
            if state.showOrderPreview { OrderPreviewView(order: state.config.order) }
        }
    }

    private var hud: some View {
        VStack {
            HStack {
                CPCoinBg()
                Spacer()
                pill(text: "Time: \(Int(ceil(state.timeLeft)))s")
                Spacer()
                pill(text: "Moves: \(state.movesLeft)")
            }
            .padding([.horizontal, .top])

            Spacer()
        }
    }

    private func pill(text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private func setupSceneAndStart() {
        scene.scaleMode = .resizeFill
        bindSceneCallbacks()
        state.startLevel()
        reconfigureScene()
    }

    private func reconfigureScene() {
        // Provide carry-over batch to the scene and (re)configure
        let batch = state.takeCarryOverBatch()
        scene.configure(config: state.config, carryOver: batch)
    }

    private func bindSceneCallbacks() {
        scene.onDrop = { product, bin in
            state.useMove()
            process(product: product, into: bin)
        }
        scene.onMiss = { product in
            // Missed item sliding off the belt
            if state.config.order.required.contains(product.kind) {
                // Treat as missed required at end (counted in scoring)
                // We'll account it when computing results.
            }
        }
        scene.onExhaustedStream = {
            // End level if time/moves still left but stream finished
            state.endLevel(reason: .finishedStream)
        }
    }

    private func process(product: Product, into bin: BinType) {
        let order = state.config.order
        let isRequired = order.required.contains(product.kind)

        switch bin {
        case .order:
            if isRequired {
                // Level 2 strict: only fresh counts
                if order.strictFreshOnly {
                    if product.freshness == .fresh {
                        state.matchedKinds.insert(product.kind)
                        state.matchedFreshnessWeights.append(1.0)
                    } else {
                        // placed but not counted (quality too low) => small wrong penalty
                        state.wrongInOrder += 1
                    }
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
        HStack(alignment: .center, spacing: 12) {
            
            HStack(alignment: .center, spacing: 8) {
                ForEach(order.required, id: \.self) { kind in
                    VStack {
                        
                        Image("\(kind.assetBaseName)_fresh")
                            .resizable()
                            .scaledToFit()
                        if order.strictFreshOnly {
                            Text("(Only fresh)").foregroundColor(.black).font(.caption)
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
        
        ZStack {
            Image(.appBgZZ)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                
                Spacer()
                Image(passed ? .winBgZZ: .loseBgZZ)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                Spacer()
                HStack {
                    Button {
                        onContinue()
                    } label: {
                        Image(.backIconZZ)
                            .resizable()
                            .scaledToFit()
                            .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:50)
                    }
                    
                    Spacer()
                    
                    
                }.padding()
            }
        }
        
    }
}

#Preview {
    LevelPickerView()
}


struct CPSpriteViewContainer: UIViewRepresentable {
    @StateObject var user = CPUser.shared
    var scene: ConveyorScene
    var level: Int
    func makeUIView(context: Context) -> SKView {
        let skView = SKView(frame: UIScreen.main.bounds)
        skView.backgroundColor = .clear
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .resizeFill
        scene.gameConfig = .forLevel(level)
        skView.presentScene(scene)
        
        return skView
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        uiView.frame = UIScreen.main.bounds
    }
}

struct LevelPickerView: View {
    private let totalRounds = 8
    @State private var showGame = false
    @Environment(\.presentationMode) var presentationMode

    @State var state = GameState()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
                    VStack(spacing: 20) {
                        
                        HStack(alignment: .top) {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                                
                            } label: {
                                Image(.backIconZZ)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: CPDeviceManager.shared.deviceType == .pad ? 100:50)
                            }
                            Spacer()
                            CPCoinBg()
                        }.padding([.horizontal, .top])
                        
                        
                        Spacer()
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                            ForEach(1...totalRounds, id: \.self) { round in
                                ZStack {
                                    Image(.levelBgZZ)
                                        .resizable()
                                        .scaledToFit()
                                    
                                    Text("\(round)")
                                        .font(.title)
                                        .bold()
                                        .foregroundStyle(.black)
                                        .padding(12)
                                        .offset(y: -10)
                                    
                                }.frame(height: CPDeviceManager.shared.deviceType == .pad ? 200:100)
                                    .onTapGesture {
                                        showGame = true
                                    }
                                
                            }
                        }
                        .padding(.horizontal, 16)
                        Spacer()
                    }
                    
                }.background(
                    ZStack {
                        Image(.appBgZZ)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    }
                )
                .fullScreenCover(isPresented: $showGame) {
                    GameView(level: 1)
                }
            }
        }
