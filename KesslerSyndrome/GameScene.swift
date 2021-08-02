//
//  GameScene.swift
//  KesslerSyndrome
//
//  Created by Atin Agnihotri on 02/08/21.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let BASE_FONT = "Optima-ExtraBlack"
    
    var starfield: SKEmitterNode!
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    
    var enemies = ["ball", "tv", "hammer"]
    var gameTimer: Timer?
    
    var isGameOver = false {
        didSet {
            gameOver()
        }
    }
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var timerInterval: TimeInterval = 1 {
        didSet {
            setupGameTimer()
        }
    }
    var enemiesInTimerCycle = 0 {
        didSet {
            if enemiesInTimerCycle >= 20 {
                enemiesInTimerCycle = 0
                if timerInterval > 0.4 {
                    timerInterval *= 0.85
                }
            }
        }
    }
    
    override func didMove(to view: SKView) {
        setupBackground()
        addPlayer()
        addScoreLabel()
        setupWorldPhysics()
        setupGameTimer()
    }
    
    func setupBackground() {
        backgroundColor = .black
        
        starfield = SKEmitterNode(fileNamed: "starfield")!
        starfield.position = CGPoint(x: 1024, y: 384)
        starfield.advanceSimulationTime(10)
        starfield.zPosition = -1
        addChild(starfield)
    }
    
    func addPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 100, y: 384)
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.contactTestBitMask = 1
        addChild(player)
    }
    
    func addScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: BASE_FONT)
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
        score = 0
    }
    
    func setupWorldPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    func setupGameTimer() {
        if let gameTimer = gameTimer {
            gameTimer.invalidate()
        }
        gameTimer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(createEnemy), userInfo: nil, repeats: true)
        print("Timer setup with interval: \(timerInterval)")
    }
    
    // Switch to object pool later on
    @objc func createEnemy() {
        guard let enemyType = enemies.randomElement() else { return }
        let enemy = SKSpriteNode(imageNamed: enemyType)
        enemy.position = CGPoint(x: 1200, y: CGFloat.random(in: 50...730))
        enemy.physicsBody = SKPhysicsBody(texture: enemy.texture!, size: enemy.size)
        // makes it frictionless
        enemy.physicsBody?.linearDamping = 0
        enemy.physicsBody?.angularDamping = 0
        // makes it spin
        enemy.physicsBody?.angularVelocity = 5
        // moves it towards the left edge of screen
        enemy.physicsBody?.velocity = CGVector(dx: -400, dy: 0)
        enemy.name = enemyType
        
        addChild(enemy)
        enemiesInTimerCycle += 1
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        setPlayerPositionOnTouch(for: touches)
    }
    
    func setPlayerPositionOnTouch(for touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        var location = touch.location(in: self)
        
        // Prevent the teleportation hack
        let playerLocation = player.position
        location.x = clampedValue(for: location.x, upperBound: playerLocation.x + 20, lowerBound: playerLocation.x - 20)
        location.y = clampedValue(for: location.y, upperBound: playerLocation.y + 20, lowerBound: playerLocation.y - 20)
    
        
        // Clamp the location to stay within the screen
        location.y = clampedValue(for: location.y, upperBound: 668, lowerBound: 100)
        
        player.position = location
    }
    
    func clampedValue(for point: CGFloat, upperBound: CGFloat, lowerBound: CGFloat) -> CGFloat {
        var value = point
        if value > upperBound {
            value = upperBound
        } else if value < lowerBound {
            value = lowerBound
        }
        return value
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        addExplosion(at: player.position)
        player.removeFromParent()
        isGameOver = true
    }
    
    func addExplosion(at position: CGPoint) {
        let explosion = SKEmitterNode(fileNamed: "explosion")!
        explosion.position = position
        addChild(explosion)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Tweak this latter to support object pool
        for node in children {
            if node.position.x <= -300 {
                node.removeFromParent()
            }
        }
        
        if !isGameOver {
            score += 1
        }
    }
    
    func gameOver() {
        gameTimer?.invalidate()
        scoreLabel.removeFromParent()
        addGameOverText()
        addFinalScoreText()
    }
    
    func addGameOverText() {
        let gameOver = SKLabelNode(fontNamed: BASE_FONT)
        gameOver.text = "GAME OVER"
        gameOver.xScale = 1.5
        gameOver.yScale = 1.5
        gameOver.position = CGPoint(x: 512, y: 384)
        addChild(gameOver)
    }
    
    func addFinalScoreText() {
        let finalScore = SKLabelNode(fontNamed: BASE_FONT)
        finalScore.text = "Final Score: \(score)"
        finalScore.position = CGPoint(x: 512, y: 300)
        addChild(finalScore)
    }
}
