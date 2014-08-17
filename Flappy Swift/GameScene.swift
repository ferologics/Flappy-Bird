//
//  GameScene.swift
//  Flappy Swift
//
//  Created by Julio Montoya on 13/07/14.
//  Copyright (c) 2014 Julio Montoya. All rights reserved.
//
//  Copyright (c) 2014 AvionicsDev
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


import SpriteKit

// Bird
var bird: SKSpriteNode = SKSpriteNode()

// Background
let background:SKNode      = SKNode()
var backgroundSpeed: Float = 100

// Time Values
var delta: NSTimeInterval          = NSTimeInterval(0)
var lastUpdateTime: NSTimeInterval = NSTimeInterval(0)

// Score
var score:Int               = 0
var labelScore: SKLabelNode = SKLabelNode()

// Instructions
var instructions: SKSpriteNode = SKSpriteNode()

// Floor Height
let floorDistance:CGFloat = 72.0

// Pipe Origin
let pipeOriginX: CGFloat = 382.0

// Physics Categories
let FSBoundaryCategory: UInt32 = 1 << 0
let FSPlayerCategory: UInt32   = 1 << 1
let FSPipeCategory: UInt32     = 1 << 2
let FSGapCategroy: UInt32      = 1 << 3

// Game States
enum FSGameState: Int {
    case FSGameStateStarting
    case FSGameStatePlaying
    case FSGameStateEnded
}

var state: FSGameState = .FSGameStateStarting

// #pragma mark - Math functions
extension Float {
    static func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        if(value > max) {
            return max
        } else if(value < min) {
            return min
        } else {
            return value
        }
    }
    
    static func range(min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }
}

extension CGFloat {
    func degrees_to_radians() -> CGFloat {
        return CGFloat(M_PI) * self / 180.0
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    init(coder aDecoder: NSCoder!) {
        super.init()
    }
    
    // #pragma mark - SKScene Initializacion
     init(size: CGSize) {
        super.init(size: size)
        
        self.initWorld()
        self.initBackground()
        self.initBird()
        
        self.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.waitForDuration(2.99), SKAction.runBlock { self.initPipes()}])))
        
        self.initHUD()
    }
    
    // #pragma mark - Init Physics
    func initWorld() {
        
        state = .FSGameStatePlaying
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity         = CGVectorMake(0, -5)
        self.physicsBody                  = SKPhysicsBody(edgeLoopFromRect: CGRectMake(0, floorDistance, self.size.width, self.size.height - floorDistance))
        self.physicsBody.categoryBitMask  = FSBoundaryCategory
        self.physicsBody.collisionBitMask = FSPlayerCategory
    }
    
    // #pragma mark - Init Bird
    func initBird() {
        
        // 1.
        bird          = SKSpriteNode(imageNamed: "bird1")
        bird.position = CGPointMake( 100, CGRectGetMidY(self.frame))
        
        // 2.
        bird.physicsBody                    = SKPhysicsBody(circleOfRadius: bird.size.width / 2.5)
        bird.physicsBody.categoryBitMask    = FSPlayerCategory
        bird.physicsBody.contactTestBitMask = FSGapCategroy | FSBoundaryCategory | FSPipeCategory
        bird.physicsBody.collisionBitMask   = FSBoundaryCategory | FSPipeCategory
        bird.physicsBody.restitution        = 0.0
        bird.physicsBody.affectedByGravity  = false
        bird.physicsBody.allowsRotation     = false
        bird.zPosition                      = 20
        self.addChild(bird)
        
        // 3.
        let texture1: SKTexture = SKTexture(imageNamed: "bird1")
        let texture2: SKTexture = SKTexture(imageNamed: "bird2")
        let textures            = [texture1, texture2]
        
        // 4.
        bird.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(textures, timePerFrame: 0.1)))
        
    }
    
    // #pragma mark - Background Functions
    func initBackground() {
        
        // 1.
        self.addChild(background)
        
        //2.
        for var i: Int = 0; i < 2; i++ {
            
            var tile         = SKSpriteNode(imageNamed: "bg")
            tile.anchorPoint = CGPointZero
            tile.position    = CGPointMake(CGFloat(i) * 640.0, 0)
            tile.name        = "bg"
            tile.zPosition   = 10
            
            background.addChild(tile)
        }
    }
    
    func moveBackground() {
        
        // 3.
        let posX: Float = -backgroundSpeed * Float(delta)
        background.position = CGPointMake( background.position.x + CGFloat(posX), 0)
        
        // 4.
        background.enumerateChildNodesWithName("bg") {  (node, stop) in
            let backgroundScreenPosition: CGPoint = background.convertPoint(node.position, toNode: self)
        
            if backgroundScreenPosition.x <= -node.frame.size.width {
                node.position = CGPointMake( node.position.x + (node.frame.size.width * 2), node.position.y)
            }
        }
    }
    
    // #pragma mark - Pipes Functions
    func initPipes() {
        
        // 1.
        let bottom: SKSpriteNode              = self.getPipeWithSize(CGSizeMake(62, Float.range(40, max: 360)), side: false)
        bottom.position                       = self.convertPoint(CGPointMake(pipeOriginX, CGRectGetMinY(self.frame) + bottom.size.height/2 + floorDistance), toNode: background)
        bottom.physicsBody                    = SKPhysicsBody(rectangleOfSize: bottom.size)
        bottom.physicsBody.categoryBitMask    = FSPipeCategory
        bottom.physicsBody.contactTestBitMask = FSPlayerCategory
        bottom.physicsBody.collisionBitMask   = FSPlayerCategory
        bottom.physicsBody.dynamic            = false
        bottom.zPosition                      = 20
        background.addChild(bottom)
        
        // 2.
        let treshold: SKSpriteNode              = SKSpriteNode(color: SKColor.clearColor(), size: CGSizeMake(10, 100))
        treshold.position                       = self.convertPoint(CGPointMake(pipeOriginX, floorDistance + bottom.size.height + treshold.size.height/2), toNode: background)
        treshold.physicsBody                    = SKPhysicsBody(rectangleOfSize: treshold.size)
        treshold.physicsBody.categoryBitMask    = FSGapCategroy
        treshold.physicsBody.contactTestBitMask = FSPlayerCategory
        treshold.physicsBody.collisionBitMask   = 0
        treshold.physicsBody.dynamic            = false
        treshold.zPosition                      = 20
        background.addChild(treshold)
        
        // 3.
        let topSize: CGFloat = self.size.height - bottom.size.height - treshold.size.height - floorDistance
        
        // 4.
        let top: SKSpriteNode              = self.getPipeWithSize(CGSizeMake(62, topSize), side: true)
        top.position                       = self.convertPoint(CGPointMake(pipeOriginX, CGRectGetMaxY(self.frame) - top.size.height/2), toNode: background)
        top.physicsBody                    = SKPhysicsBody(rectangleOfSize: top.size)
        top.physicsBody.categoryBitMask    = FSPipeCategory
        top.physicsBody.contactTestBitMask = FSPlayerCategory
        top.physicsBody.collisionBitMask   = FSPlayerCategory
        top.physicsBody.dynamic            = false
        top.zPosition                      = 20
        background.addChild(top)
        
    }
    
    func getPipeWithSize(size: CGSize, side: Bool) -> SKSpriteNode {
        
        // 1.
        let textureSize: CGRect           = CGRectMake(0, 0, size.width, size.height)
        let backgroundCGImage: CGImageRef = UIImage(named: "pipe").CGImage
    
        // 2.
        UIGraphicsBeginImageContext(size)
        let context: CGContextRef   = UIGraphicsGetCurrentContext()
        CGContextDrawImage(context, textureSize, backgroundCGImage)
        let tiledBackground:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 3.
        let backgroundTexture: SKTexture = SKTexture(CGImage: tiledBackground.CGImage)
        let pipe: SKSpriteNode           = SKSpriteNode(texture: backgroundTexture)
        pipe.zPosition                   = 1
        
        // 4.
        let cap: SKSpriteNode = SKSpriteNode(imageNamed: "bottom")
        cap.position          = CGPointMake(0, side ? -pipe.size.height/2 + cap.size.height/2 : pipe.size.height/2 - cap.size.height/2)
        cap.zPosition         = 5
        pipe.addChild(cap)
        
        // 5.
        if side == true {
            let angle: CGFloat = 180.0
            cap.zRotation      = angle.degrees_to_radians()
        }
        
        return pipe
    }
    
    // #pragma mark - Game Over helpers
    func gameOver() {
        
        state = .FSGameStateEnded

        bird.physicsBody.categoryBitMask  = 0
        bird.physicsBody.collisionBitMask = FSBoundaryCategory
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: Selector("restartGame"), userInfo: nil, repeats: false)
        
    }
    
    func restartGame() {
        
        state = .FSGameStateStarting
        bird.removeFromParent()
        background.removeAllChildren()
        background.removeFromParent()
        
        instructions.hidden = false
        self.removeActionForKey("generator")
    
        score           = 0
        labelScore.text = "\(score)"
        
        self.initBird()
        self.initBackground()
    }
    
    // #pragma mark - SKPhysicsContactDelegate
    func didBeginContact(contact: SKPhysicsContact!) {
        
        let collision: UInt32 = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask)
        
        if collision == (FSPlayerCategory | FSGapCategroy) {
            
            score++
            labelScore.text = "\(score)"
        } else if collision == (FSPlayerCategory | FSBoundaryCategory) {
            
            if bird.position.y < 150 {
                self.gameOver()
            }
        } else if collision == (FSPlayerCategory | FSPipeCategory) {
            
            self.gameOver()
        }
    }
    
    // #pragma mark - Touch Events
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        if state == .FSGameStateStarting {
            
            state               = .FSGameStatePlaying
            instructions.hidden = true
            
            bird.physicsBody.affectedByGravity = true
            bird.physicsBody.applyImpulse(CGVectorMake(0, 25))
            
            self.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock { self.initPipes()}])), withKey: "generator")
        }
            
            // 2
        else if state == .FSGameStatePlaying {
            bird.physicsBody.applyImpulse(CGVectorMake(0, 25))
        }
    }
    
    // #pragma mark - Frames Per Second
    override func update(currentTime: CFTimeInterval) {
        
        // 5.
        if lastUpdateTime == 0.0 {
            delta = 0
        } else {
            delta = currentTime - lastUpdateTime
        }
        
        lastUpdateTime = currentTime
        
        if state != .FSGameStateEnded {
        
            self.moveBackground()
        
            if bird.physicsBody.velocity.dy > 280 {
                bird.physicsBody.velocity = CGVectorMake(bird.physicsBody.velocity.dx, 280)
            }
            
            bird.zRotation = Float.clamp(-1, max: 0.0, value: bird.physicsBody.velocity.dy * (bird.physicsBody.velocity.dy < 0 ? 0.003 : 0.001))
        } else {
            
            bird.zRotation = CGFloat(M_PI)
            bird.removeAllActions()
        }
    }
    
    func initHUD() {
        
        labelScore           = SKLabelNode(fontNamed: (UIFont: "joystix monospace"))
        labelScore.position  = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(self.frame))
        labelScore.text      = "\(score)"
        labelScore.zPosition = 50
        self.addChild(labelScore)
        
        instructions           = SKSpriteNode(imageNamed: "TapToStart")
        instructions.position  = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        instructions.zPosition = 50
        self.addChild(instructions)
        
    }
}









































