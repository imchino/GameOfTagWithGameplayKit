/*
 鬼ごっこゲーム
 プレイヤーに向かって鬼（エネミー）が移動する
 プレイヤーは、タップ座標に移動する
 鬼は、プレイヤー位置を自動追尾
 接触すると、ゲームオーバー
 */

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    var gameoverMessageLabel: SKNode?
    
    // GKAgent2Dオブジェクトは、GKGoalのルールに基づいて移動するGKConponentサブクラス
    let player = SKShapeNode(circleOfRadius: 10)
    let playerAgent = GKAgent2D()       // エネミーの追尾目標になる

    var enemies = [SKShapeNode]()
    var enemyAgents = [GKAgent2D]()     // エネミーの挙動を管理する配列

    var timer: Timer?
    var prevTime: TimeInterval = 0  // 最後に描画を更新したタイム
    var startTime: TimeInterval = 0 // ゲーム開始タイム
    var isGameFinished = false
    
    //GKComponentSystemは、機能を一括管理してくれる（GKAgentは、GKComponentサブクラスなので管理できる）
    let agentSystem = GKComponentSystem(componentClass: GKAgent2D.self)

    // 初期化
    // プレイヤーとエネミーをセット
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector()
        gameoverMessageLabel = childNode(withName: "labels")
        gameoverMessageLabel?.isHidden = true

        player.fillColor = UIColor.yellow
        addChild(player)
        
        setCreateEnemyTimer()
    }
    
    
    // 5秒に一度、createEnemyを呼び出す
    func setCreateEnemyTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 5.0,
                                     target: self,
                                     selector: #selector(GameScene.createEnemy),
                                     userInfo: nil,
                                     repeats: true)
        timer?.fire()
    }

    // エネミーノードを生成したら、対応するエネミーエージェントも生成
    // それぞれを別の配列に格納して管理する（同じIndexで操作できる）
    func createEnemy() {
        let enemy = SKShapeNode(circleOfRadius: 10)
        enemy.position.x = size.width / 2
        enemy.fillColor = UIColor.red
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.frame.width / 2)
        addChild(enemy)
        enemies.append(enemy)   // エネミー配列で管理
        
        // エネミーに対応するエージェントを生成
        let enemyAgent = GKAgent2D()
        enemyAgent.delegate = self  // このシーンは、エージェントひとつずつのデリゲート先になる
        enemyAgent.maxAcceleration = 30
        enemyAgent.maxSpeed = 70
        enemyAgent.position = vector_float2(x: Float(enemy.position.x), y: Float(enemy.position.y))
        let trackPlayer = GKGoal(toSeekAgent: playerAgent)
        enemyAgent.behavior = GKBehavior(goals: [trackPlayer,])
        agentSystem.addComponent(enemyAgent)        // コンポーネントに追加
        enemyAgents.append(enemyAgent)              // エージェント配列で管理
    }
    
    // シーン描画サイクル
    override func update(_ currentTime: TimeInterval) {
        if prevTime == 0 {  // ゲーム起動直後なら
            prevTime = currentTime  // 開始タイミングの日時
            startTime = currentTime // 開始時刻を設定
        }
        
        agentSystem.update(deltaTime: currentTime - prevTime)   // コンポーネント更新メソッド（更新間隔を渡す）
        playerAgent.position = vector_float2(x: Float(player.position.x), y: Float(player.position.y))
        
        if isGameFinished { return }
        
        // エネミーごとに接触判定する
        for enemy in enemies {
            let threshold = player.frame.width/2 + enemy.frame.width/2  // 接触とみなす間隔
            let distanceX = enemy.position.x - player.position.x
            let distanceY = enemy.position.y - player.position.y
            let distanceToPlayer = sqrt(distanceX*distanceX + distanceY*distanceY)  // プレイヤーまでの距離
            
            if distanceToPlayer < threshold {
            // 接触したらゲームオーバーにする
                gameoverWith(record: Int(currentTime - startTime))
                break
            }
        }
        
        prevTime = currentTime  // 最後の描画更新タイム
    }
    
    // タッチした座標にプレイヤーを移動させる
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touche in touches {
            let  point = touche.location(in: self)
            player.removeAllActions()
            
            let distanceOfX = point.x - player.position.x
            let distanceOfY = point.y - player.position.y
            let movingPath = CGPoint(x: distanceOfX, y: distanceOfY)
            
            let path = CGMutablePath()
            path.move(to: CGPoint())
            path.addLine(to: movingPath)
            player.run(SKAction.follow(path, speed: 50.0))
            
        }
    }
    
    func gameoverWith(record time: Int) {
        timer?.invalidate()
        isGameFinished = true
        gameoverMessageLabel?.isHidden = false
        let label = SKLabelNode(text: "\(time) sec!!")
        label.fontSize = 60
        label.fontName = "Helvetica Light"
        label.position = CGPoint(x: 0, y: -150)
        addChild(label)
    }
    
}

//MARK: プロトコルとデリゲートメソッド
extension GameScene: GKAgentDelegate {
    // エージェント更新直後に呼ばれるデリゲートメソッド
    // 更新されたエージェントを利用して、エネミー座標を移動させる
    func agentDidUpdate(_ agent: GKAgent) {
        if let agent = agent as? GKAgent2D, let index = enemyAgents.index(where: { $0 == agent }) {
            let enemy = enemies[index]
            enemy.position = CGPoint(x: CGFloat(agent.position.x), y: CGFloat(agent.position.y))
        }
    }
}
