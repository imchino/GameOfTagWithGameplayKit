//
//  GameScene.swift
//  GameOfTag
//
//  Created by chino on 2017/02/17.
//  Copyright © 2017年 chino. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    let player = SKShapeNode(circleOfRadius: 10)

    var enemies = [SKShapeNode]()
    var timer: Timer?
    var prevTime: TimeInterval = 0
    
    var startTime: TimeInterval = 0
    var isGameFinished = false
    
    let playerAgent = GKAgent2D()
    let agentSystem = GKComponentSystem(componentClass: GKAgent2D.self)
    var enemyAgents = [GKAgent2D]()

    override func didMove(to view: SKView) {
        player.fillColor = UIColor(red: 0.93, green: 0.96, blue: 0.00, alpha: 1.0)
        addChild(player)
        
        setCreateEnemyTimer()
        physicsWorld.gravity = CGVector()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach {
            let point = $0.location(in: self)
            player.removeAllActions()
            
            let path = CGMutablePath()
            path.move(to: CGPoint())
            path.addLine(to: CGPoint(x: point.x - player.position.x, y: point.y - player.position.y))
            player.run(SKAction.follow(path, speed: 50.0))
        }
    }
    
    func setCreateEnemyTimer() {
        timer?.invalidate()
        // 5秒に一度、createEnemyを呼び出す処理
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(GameScene.createEnemy), userInfo: nil, repeats: true)
        timer?.fire()
    }

    func createEnemy() {
        let enemy = SKShapeNode(circleOfRadius: 10)
        enemy.position.x = size.width / 2
        enemy.fillColor = UIColor(red: 0.94, green: 0.14, blue: 0.08, alpha: 1.0)
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.frame.width / 2)
        addChild(enemy)
        enemies.append(enemy)
        
        let anemyAgent = GKAgent2D()
        anemyAgent.maxAcceleration = 30
        anemyAgent.maxSpeed = 70
        anemyAgent.position = vector_float2(x: Float(enemy.position.x), y: Float(enemy.position.y))
        anemyAgent.delegate = self
        anemyAgent.behavior = GKBehavior(goals: [
            GKGoal(toSeekAgent: playerAgent),
            ])
        agentSystem.addComponent(anemyAgent)
        enemyAgents.append(anemyAgent)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if prevTime == 0 {
            prevTime = currentTime
            startTime = currentTime
        }
        
        agentSystem.update(deltaTime: currentTime - prevTime)
        playerAgent.position = vector_float2(x: Float(player.position.x), y: Float(player.position.y))
        
        if !isGameFinished {
            for enemy in enemies {
                let dx = enemy.position.x - player.position.x
                let dy = enemy.position.y - player.position.y
                if sqrt(dx*dx + dy*dy) < player.frame.width / 2 + enemy.frame.width / 2 {
                    isGameFinished = true
                    timer?.invalidate()
                    let label = SKLabelNode(text: "記録:\(Int(currentTime - startTime))秒")
                    label.fontSize = 80
                    label.position = CGPoint(x: 0, y: -100)
                    addChild(label)
                    break
                }
            }
        }
        
        prevTime = currentTime
    }
    
}

extension GameScene: GKAgentDelegate {
    func agentDidUpdate(_ agent: GKAgent) {
        if let agent = agent as? GKAgent2D, let index = enemyAgents.index(where: { $0 == agent }) {
            let enemy = enemies[index]
            enemy.position = CGPoint(x: CGFloat(agent.position.x), y: CGFloat(agent.position.y))
        }
    }
}
