//
//  GameScene.swift
//  SpaceRace
//
//  Created by Noah Patterson on 1/15/17.
//  Copyright © 2017 noahpatterson. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starField: SKEmitterNode!
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var playAgain: SKLabelNode?
    var possibleEnemies = ["ball", "hammer", "tv"]
    var gameTimer: Timer!
    var isGameOver = false
    var isTouchingPlayer = false
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = UIColor.black
        
        starField = SKEmitterNode(fileNamed: "Starfield")!
        starField.position = CGPoint(x: 1024, y: 384)
        starField.advanceSimulationTime(10)
        addChild(starField)
        starField.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "player")
        player.name = "player"
        player.position = CGPoint(x: 100, y: 384)
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody!.contactTestBitMask = 1
        addChild(player)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
        
        score = 0
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        //create enemies
        gameTimer = Timer.scheduledTimer(timeInterval: 0.35, target: self, selector: #selector(createEnemy), userInfo: nil, repeats: true)
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        for node in children {
            if node.position.x < -300 {
                node.removeFromParent()
            }
        }
        
        if !isGameOver {
            score += 1
        }
    }
    
    func startGame() {
        score = 0
        playAgain!.isHidden = true
        
        starField.isPaused = false
        player.position = CGPoint(x: 100, y: 384)
        player.physicsBody!.contactTestBitMask = 1
        addChild(player)
        isGameOver = false
        gameTimer = Timer.scheduledTimer(timeInterval: 0.35, target: self, selector: #selector(createEnemy), userInfo: nil, repeats: true)
        
    }
    
    func stopGame() {
        gameTimer.invalidate()
    
        starField.isPaused = true
        if playAgain == nil {
            playAgain = SKLabelNode(fontNamed: "Chalkduster")

            playAgain!.text = "Play Again?"
            playAgain!.zPosition = 1
            playAgain!.fontSize = 36
            playAgain!.name = "playAgainLabel"
            playAgain!.position = CGPoint(x: 512, y: 384)
            addChild(playAgain!)
        } else {
            playAgain!.isHidden = false
        }
    }
    
    func createLaser() {
        let sprite = SKShapeNode(ellipseIn: CGRect(x: 0, y: 0, width: 50, height: 10))
        sprite.name = "laser"
        sprite.position = CGPoint(x: player.position.x + 10, y: player.position.y)
        sprite.fillColor = UIColor.orange
        sprite.lineWidth = 2.0
        sprite.strokeColor = UIColor.orange
        
        addChild(sprite)
        
        
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.path!.boundingBox.size, center: sprite.path!.boundingBox.origin)
        sprite.physicsBody!.contactTestBitMask = 1
        
//            SKPhysicsBody(texture: sprite.fillTexture!, size: CGSize(width: sprite.frame.width, height: sprite.frame.height))
        sprite.physicsBody!.velocity = CGVector(dx: 500, dy: 0)
        sprite.physicsBody!.angularVelocity = 5
        sprite.physicsBody!.linearDamping = 0
        sprite.physicsBody!.angularDamping = 0
        
    }
    
    func createEnemy() {
        possibleEnemies = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleEnemies) as! [String]
        let randomDistribution = GKRandomDistribution(lowestValue: 50, highestValue: 736)
        let sprite = SKSpriteNode(imageNamed: possibleEnemies[0])
        sprite.name = "enemy"
        sprite.position = CGPoint(x: 1200, y: randomDistribution.nextInt())
        addChild(sprite)
        
        sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size)
        sprite.physicsBody?.categoryBitMask = 1
        sprite.physicsBody?.velocity = CGVector(dx: -500, dy: 0)
        sprite.physicsBody?.angularVelocity = 5
        sprite.physicsBody?.linearDamping = 0
        sprite.physicsBody?.angularDamping = 0
        
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        var location = touch.location(in: self)
        if isTouchingPlayer {
            
            if location.y < 100 {
                location.y = 100
            } else if location.y > 668 {
                location.y = 668
            }
            
            player.position = location
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)
        
        if nodes.contains(player) {
            isTouchingPlayer = true
        } else {
            isTouchingPlayer = false
        }
        
        if !isGameOver {
            createLaser()
        } else if let again = playAgain, nodes.contains(again) {
            startGame()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if let laser = contact.bodyA.node, laser.name == "laser" {
            if let node = contact.bodyB.node {
                switch node.name! {
                    case "enemy":
                        let explosion = SKEmitterNode(fileNamed: "explosion")!
                        explosion.position = node.position
                        addChild(explosion)
                        
                        node.removeFromParent()
                        contact.bodyA.node!.removeFromParent()
                    default:
                        break
                }
            }
        } else if let laser = contact.bodyB.node, laser.name == "laser" {
            if let node = contact.bodyA.node {
                switch node.name! {
                case "enemy":
                    let explosion = SKEmitterNode(fileNamed: "explosion")!
                    explosion.position = node.position
                    addChild(explosion)
                    
                    node.removeFromParent()
                    contact.bodyB.node!.removeFromParent()
                default:
                    break
                }
            }
        } else if let player = contact.bodyA.node, player.name == "player" {
            let explosion = SKEmitterNode(fileNamed: "explosion")!
            explosion.position = player.position
            addChild(explosion)
            
            player.physicsBody!.contactTestBitMask = 0
            player.removeFromParent()
            
            isGameOver = true
            stopGame()
        } else if let player = contact.bodyB.node, player.name == "player" {
            let explosion = SKEmitterNode(fileNamed: "explosion")!
            explosion.position = player.position
            addChild(explosion)
            
            player.physicsBody!.contactTestBitMask = 0
            player.removeFromParent()
            
            isGameOver = true
            stopGame()
        }

    }
}














