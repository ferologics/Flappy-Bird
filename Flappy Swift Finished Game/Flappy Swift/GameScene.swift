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
var bird:SKSpriteNode = SKSpriteNode()

// Background
let background:SKNode = SKNode()
let background_speed:Float = 100

// Score
var score:Int = 0
var label_score:SKLabelNode = SKLabelNode()

// Instructions
var instructions:SKSpriteNode = SKSpriteNode()

// Pipe Origin
let pipe_origin_x:CGFloat = 382.0

// Floor height
let floor_distance:CGFloat = 72.0

// Time Values
var delta:NSTimeInterval = NSTimeInterval(0)
var last_update_time:NSTimeInterval = NSTimeInterval(0)

// Physics Categories
let FSBoundaryCategory:UInt32 = 1 << 0
let FSPlayerCategory:UInt32   = 1 << 1
let FSPipeCategory:UInt32     = 1 << 2
let FSGapCategory:UInt32      = 1 << 3

// Game States

enum FSGameState: Int {
    case FSGameStateStarting
    case FSGameStatePlaying
    case FSGameStateEnded
}

var state:FSGameState = .FSGameStateStarting

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
        self.initHUD()
    }
    
    // #pragma mark - Init Physics
    func initWorld() {
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0, -5)
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRectMake(0, floor_distance, self.size.width, self.size.height - floor_distance))
        self.physicsBody.categoryBitMask = FSBoundaryCategory
        self.physicsBody.collisionBitMask = FSPlayerCategory
    }
    
    // #pragma mark - Init Bird
    func initBird() {
        bird = SKSpriteNode(imageNamed: "bird1")
        bird.position = CGPointMake(100, CGRectGetMidY(self.frame))
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.width / 2.5)
        bird.physicsBody.categoryBitMask = FSPlayerCategory
        bird.physicsBody.contactTestBitMask = FSPipeCategory | FSGapCategory | FSBoundaryCategory
        bird.physicsBody.collisionBitMask = FSPipeCategory | FSBoundaryCategory
        bird.physicsBody.restitution = 0.0
        bird.physicsBody.allowsRotation = false
        bird.physicsBody.affectedByGravity = false
        bird.zPosition = 50
        self.addChild(bird)
        
        let texture1: SKTexture = SKTexture(imageNamed: "bird1")
        let texture2: SKTexture = SKTexture(imageNamed: "bird2")
        let textures = [texture1, texture2]
        
        bird.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(textures, timePerFrame: 0.1)))
    }
    
    // #pragma mark Score
    
    func initHUD() {
        label_score = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        label_score.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(self.frame) - 100)
        label_score.text = "0"
        label_score.zPosition = 50
        self.addChild(label_score)
        
        instructions = SKSpriteNode(imageNamed: "TapToStart")
        instructions.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 10)
        instructions.zPosition = 50
        self.addChild(instructions)
    }
    
    // #pragma mark - Background Functions
    func initBackground() {
        self.addChild(background)
        
        for var i: Int = 0; i < 2; i++ {
            let tile = SKSpriteNode(imageNamed: "bg")
            tile.anchorPoint = CGPointZero
            tile.position = CGPointMake(CGFloat(i) * 640.0, 0)
            tile.name = "bg"
            tile.zPosition = 10
            background.addChild(tile)
        }
    }
    
    func moveBackground() {
        let posX : Float = -background_speed * Float(delta)
        background.position = CGPointMake(background.position.x + CGFloat(posX), 0)

        background.enumerateChildNodesWithName("bg") { (node, stop) in
            let background_screen_position: CGPoint = background.convertPoint(node.position, toNode: self)
            
            if background_screen_position.x <= -node.frame.size.width {
                node.position = CGPointMake(node.position.x + (node.frame.size.width * 2), node.position.y)
            }
            
        }
    }
    
    // #pragma mark - Pipes Functions
    func initPipes() {
        let bottom:SKSpriteNode = self.getPipeWithSize(CGSizeMake(62, Float.range(40, max: 360)), side: false)
        bottom.position = self.convertPoint(CGPointMake(pipe_origin_x, CGRectGetMinY(self.frame) + bottom.size.height/2 + floor_distance), toNode: background)
        bottom.physicsBody = SKPhysicsBody(rectangleOfSize: bottom.size)
        bottom.physicsBody.categoryBitMask = FSPipeCategory;
        bottom.physicsBody.contactTestBitMask = FSPlayerCategory;
        bottom.physicsBody.collisionBitMask = FSPlayerCategory;
        bottom.physicsBody.dynamic = false
        bottom.zPosition = 20
        background.addChild(bottom)
        
        let threshold:SKSpriteNode = SKSpriteNode(color: UIColor.clearColor(), size: CGSizeMake(10, 100))
        threshold.position = self.convertPoint(CGPointMake(pipe_origin_x, floor_distance + bottom.size.height + threshold.size.height/2), toNode: background)
        threshold.physicsBody = SKPhysicsBody(rectangleOfSize: threshold.size)
        threshold.physicsBody.categoryBitMask = FSGapCategory
        threshold.physicsBody.contactTestBitMask = FSPlayerCategory
        threshold.physicsBody.collisionBitMask = 0
        threshold.physicsBody.dynamic = false
        threshold.zPosition = 20
        background.addChild(threshold)
        
        let topSize:CGFloat = self.size.height - bottom.size.height - threshold.size.height - floor_distance
        
        let top:SKSpriteNode = self.getPipeWithSize(CGSizeMake(62, topSize), side: true)
        top.position = self.convertPoint(CGPointMake(pipe_origin_x, CGRectGetMaxY(self.frame) - top.size.height/2), toNode: background)
        top.physicsBody = SKPhysicsBody(rectangleOfSize: top.size)
        top.physicsBody.categoryBitMask = FSPipeCategory;
        top.physicsBody.contactTestBitMask = FSPlayerCategory;
        top.physicsBody.collisionBitMask = FSPlayerCategory;
        top.physicsBody.dynamic = false
        top.zPosition = 20
        background.addChild(top)
    }
    
    func getPipeWithSize(size: CGSize, side: Bool) -> SKSpriteNode {
        let textureSize:CGRect = CGRectMake(0, 0, size.width, size.height)
        let backgroundCGImage:CGImageRef = UIImage(named: "pipe").CGImage
        
        UIGraphicsBeginImageContext(size)
        let context:CGContextRef = UIGraphicsGetCurrentContext()
        CGContextDrawTiledImage(context, textureSize, backgroundCGImage)
        let tiledBackground:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let backgroundTexture:SKTexture = SKTexture(CGImage: tiledBackground.CGImage)
        let pipe:SKSpriteNode = SKSpriteNode(texture: backgroundTexture)
        pipe.zPosition = 1

        let cap:SKSpriteNode = SKSpriteNode(imageNamed: "bottom")
        cap.position = CGPointMake(0, side ? -pipe.size.height/2 + cap.size.height/2 : pipe.size.height/2 - cap.size.height/2)
        cap.zPosition = 5
        pipe.addChild(cap)
        
        if side == true {
            let angle:CGFloat = 180.0
            cap.zRotation = angle.degrees_to_radians()
        }
        
        return pipe
    }
    
    // #pragma mark - Game Over helpers
    func gameOver() {
        state = .FSGameStateEnded
        bird.physicsBody.categoryBitMask = 0
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

        score = 0
        label_score.text = "0"

        self.initBird()
        self.initBackground()
    }
    
    // #pragma mark - SKPhysicsContactDelegate
    func didBeginContact(contact: SKPhysicsContact!) {
        let collision:UInt32 = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask)
        
        if collision == (FSPlayerCategory | FSGapCategory) {
            score++
            label_score.text = "\(score)"
        }
        
        if collision == (FSPlayerCategory | FSPipeCategory) {
            self.gameOver()
        }
        
        if collision == (FSPlayerCategory | FSBoundaryCategory) {
            if bird.position.y < 150 {
                self.gameOver()
            }
        }
    }
    
    // #pragma mark - Touch Events
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if state == .FSGameStateStarting {
            state = .FSGameStatePlaying
            
            instructions.hidden = true
            
            bird.physicsBody.affectedByGravity = true
            bird.physicsBody.applyImpulse(CGVectorMake(0, 25))
            
            self.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock { self.initPipes()}])), withKey: "generator")
        }
            
        else if state == .FSGameStatePlaying {
            bird.physicsBody.applyImpulse(CGVectorMake(0, 25))
        }
    }
    
    // #pragma mark - Frames Per Second
    override func update(currentTime: CFTimeInterval) {
        if last_update_time == 0.0 {
            delta = 0
        } else {
            delta = currentTime - last_update_time
        }
        
        last_update_time = currentTime

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
}
