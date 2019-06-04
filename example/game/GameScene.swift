import SpriteKit
import GameplayKit
import CoreMotion
import AudioToolbox

enum EN_DYNAMIC_TYPE: Int
{
    case EN_TYPE_X = 0
    case EN_TYPE_Y
}

//  GKShuffledDistribution 取後不放回
//  GKRandomDistribution   取後放回

@objc protocol GameDelegate {
    @objc optional func leaveGame(isWin: Bool)
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    weak var gameDelegate: GameDelegate? = nil
    
    var bubble = SKSpriteNode()
    var border = SKSpriteNode()
    var target = SKSpriteNode()
    var timeLabel = SKLabelNode()
    
    var background = SKSpriteNode()
    var motionManager = CMMotionManager()
    var destX: CGFloat  = 0.0
    var destY: CGFloat  = 0.0
    
    let ballCategory: UInt32 = 0x1 << 0
    let boomCategory: UInt32 = 0x1 << 1
    let obstacleCategory: UInt32 = 0x1 << 2
    let canDestoryCategory: UInt32 = 0x1 << 3
    let targetCategory: UInt32 = 0x1 << 4
    let canGetCategory: UInt32 = 0x1 << 5
    
    var lastUpdateTime: CFTimeInterval = 0.0
    var deltaTime: CFTimeInterval = 0.0
    var doSomethingTimer: CFTimeInterval = 0.0
    var isInContact: Bool = false
    
    var cam = SKCameraNode()
    let gravity: CGFloat = 3.0
    var scale: CGFloat = 10.0
    
    let baseBlockRange: CGFloat = 200
    let baseStickWidth: CGFloat = 200
    let baseStickheight: CGFloat = 20
    let baseCircleRadius: CGFloat = 100
    
    var timerCountdown: Timer?
    var time: Int = 0
    var bomber: Int = 0 {
        didSet {
            timeLabel.text = "time=\(time) boom=\(bomber)"
        }
    }
    
    override func didMove(to view: SKView) {
     
        bomber = Int(self.scale / 5) + 1
        
        self.camera = cam //set the scene's camera to reference cam
        self.addChild(cam)
        
        background = (self.childNode(withName: "background") as? SKSpriteNode)!
        background.size = CGSize(width: self.frame.width * scale, height: self.frame.height * scale)
        background.position = CGPoint(x: background.size.width / 2, y: background.size.height / 2)
        
        let borderBody = SKPhysicsBody(edgeLoopFrom: background.frame)//CGRect(x: self.frame.minX, y: self.frame.minY, width: self.frame.width * 10, height: self.frame.height * 10))
        borderBody.friction = 0
        borderBody.categoryBitMask = obstacleCategory
        self.physicsBody = borderBody
        
        target = (self.childNode(withName: "target") as? SKSpriteNode)!
        target.name = "target"
        target.physicsBody?.categoryBitMask = targetCategory + canDestoryCategory
        target.physicsBody?.contactTestBitMask = boomCategory
        
        let bgWidthHalf = Int(background.frame.width / 2)
        let bgHeightHalf = Int(background.frame.height / 2)
        let posX = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: bgWidthHalf) + bgWidthHalf - 200)
        let posY = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: bgHeightHalf) + bgWidthHalf - 200)
        target.position = CGPoint(x: posX, y: posY)
        
        
        self.bubble = (self.childNode(withName: "bubble") as? SKSpriteNode)!
        self.bubble.name = "bubble"
        
        let range = SKRange(constantValue:0)
        let constraint = SKConstraint.distance(range, to: self.bubble)
        self.cam.constraints = [constraint]
        
        
        // Position the label relative to the camera node
        timeLabel =  SKLabelNode(text: "")
        timeLabel.fontColor = SKColor.yellow
        timeLabel.position = CGPoint(x: 0, y: self.frame.height/2 - 50)
        timeLabel.zPosition = 5
        self.cam.addChild(timeLabel)
        
        let bgHeight = background.size.height
        let bgWidth = background.size.width
        let row = bgHeight / self.baseBlockRange
        let col = bgWidth / self.baseBlockRange
        for i in 0...Int(row) {
            for j in 0...Int(col) {
                let random = GKRandomSource.sharedRandom().nextInt(upperBound: 10)
                let shiftX = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 50) - 25)
                let shiftY = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 50) - 25)

                let position = CGPoint(x: self.baseBlockRange / 2 + bgWidth * CGFloat(j) / col + shiftX,
                                       y: self.baseBlockRange / 2 + bgHeight * CGFloat(i) / row + shiftY)
                switch random {
                case 0...1:
                    createSpinItem(pos: position)
                case 2:
                    createFixField(pos: position)
                case 3:
                    createDynamicItem(pos: position, parallel: true)
                case 5:
                    createDynamicItem(pos: position, parallel: false)
                default:
                    createFixItem(pos: position)
                }
            }
        }
        for i in 0...Int(self.scale) {
            let randomRow = GKRandomSource.sharedRandom().nextInt(upperBound: Int(row) - i)
            let randomCol = GKRandomSource.sharedRandom().nextInt(upperBound: Int(col) - i)
            let position = CGPoint(x: self.baseBlockRange / 2 + bgWidth * CGFloat(randomCol) / col,
                                   y: self.baseBlockRange / 2 + bgHeight * CGFloat(randomRow) / row)
            createBomb(pos: position)
        }
        
        
        self.physicsWorld.contactDelegate = self

        if motionManager.isAccelerometerAvailable == true {
           
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler:{
                data, error in
              
                let currentX = self.bubble.position.x
                let currentY = self.bubble.position.y
                if let _data = data {
                    let accelerationY = Double(_data.acceleration.y)
                    let accelerationX = Double(_data.acceleration.x)
//                    print("x:\(accelerationX),y:\(accelerationY)")
                    if abs(accelerationY) <= 0.1 {
                        self.physicsWorld.gravity.dx = 0
                    } else {
                        let nextX = currentX - CGFloat((data?.acceleration.y)! * 100)
                        self.physicsWorld.gravity.dx = (nextX-currentX > 0 ) ? self.gravity : -self.gravity
                    }
                    
                    if abs(accelerationX) <= 0.1 {
                        self.physicsWorld.gravity.dy = 0
                    } else {
                        let nextY = currentY + CGFloat((data?.acceleration.x)! * 100)
                        self.physicsWorld.gravity.dy = (nextY-currentY > 0 ) ? self.gravity : -self.gravity
                    }
                }
            })
        }
        
        timerCountdown = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.countDown), userInfo: nil, repeats: true)
        
        
    }
    
    @objc func countDown()
    {
        time += 1
        timeLabel.text = "time=\(time) boom=\(bomber)"
    }
    
    func removeAllTimer()
    {
        self.timerCountdown?.invalidate()
    }
    
    func createBomb(pos: CGPoint)
    {
        let node = SKSpriteNode()
        
        let radius = self.baseCircleRadius / 2
        node.size = CGSize(width: radius, height: radius)
        node.position = pos
        
        node.texture = SKTexture(imageNamed: "bomb")
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        
        node.physicsBody?.isDynamic = false
        node.physicsBody?.pinned = true
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.affectedByGravity = false
        
        node.physicsBody?.categoryBitMask = canGetCategory
        node.physicsBody?.contactTestBitMask = ballCategory
        node.physicsBody?.collisionBitMask = 0
        
        self.addChild(node)
    }
    
    func createFixField(pos: CGPoint)
    {
        let node = SKSpriteNode()
        
        let radius = self.baseCircleRadius * CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 3) + 2) / 2
        node.size = CGSize(width: radius, height: radius)
        node.position = pos
        
        node.texture = SKTexture(imageNamed: "circular")
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        
        node.physicsBody?.isDynamic = false
        node.physicsBody?.pinned = true
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.affectedByGravity = false
        
        node.physicsBody?.categoryBitMask = obstacleCategory
        node.physicsBody?.contactTestBitMask = 0
        node.physicsBody?.collisionBitMask = ballCategory
        
        self.addChild(node)
    }
    
    func createButton(isWin: Bool)
    {
        let title = isWin ? "You Win!" : "You Lose!"
        let lbl =  SKLabelNode(text: title)
        
        lbl.zPosition = 5
       
        lbl.position =  CGPoint.zero
        self.cam.addChild(lbl)
        
        
        
        let btn =  SKLabelNode(text: "Leave")
        btn.name = "Leave"
        btn.zPosition = 5
        btn.fontColor = SKColor.green
        btn.position = CGPoint(x: 0, y: -60)
        self.cam.addChild(btn)
      
    }
    
    func createFixItem(pos: CGPoint)
    {
        let node = SKSpriteNode()
        node.color = .white
        node.size = CGSize(width: self.baseStickWidth * CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 5) + 1) / 2, height: self.baseStickheight)
        node.position = pos
        node.zRotation = 2 * CGFloat.pi * CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 16)) / 16
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        
        node.physicsBody?.isDynamic = false
        node.physicsBody?.pinned = true
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.affectedByGravity = false
        
        node.physicsBody?.categoryBitMask = obstacleCategory + canDestoryCategory
        node.physicsBody?.contactTestBitMask = boomCategory
        node.physicsBody?.collisionBitMask = ballCategory
        
        self.addChild(node)
    }
    
    func createSpinItem(pos: CGPoint)
    {
        let node = SKSpriteNode()
        node.color = .green
        node.size = CGSize(width: self.baseStickWidth, height: self.baseStickheight)
        node.position = pos
        node.zRotation = 2 * CGFloat.pi * CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 16)) / 16
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        
        node.physicsBody?.isDynamic = true
        node.physicsBody?.pinned = true
        node.physicsBody?.allowsRotation = true
        node.physicsBody?.affectedByGravity = false
        
        node.physicsBody?.categoryBitMask = obstacleCategory
        node.physicsBody?.contactTestBitMask = 0
        node.physicsBody?.collisionBitMask = ballCategory
        
        self.addChild(node)
    }
    
    func createDynamicItem(pos: CGPoint, parallel: Bool)
    {
        let node = SKSpriteNode()
        node.color = parallel ? .yellow : .orange
        node.size = CGSize(width: self.baseStickWidth * CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 2) + 1) / 2, height: self.baseStickheight)
        node.position = pos
        node.zRotation = 2 * CGFloat.pi * CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 8)) / 8//parallel ? CGFloat.pi / 2 : 0
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
     
        node.physicsBody?.isDynamic = false
        node.physicsBody?.pinned = false
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.affectedByGravity = false
        
        node.physicsBody?.categoryBitMask = obstacleCategory
        node.physicsBody?.contactTestBitMask = 0
        node.physicsBody?.collisionBitMask = ballCategory
        
        var act1: SKAction!
        var act2: SKAction!
        let time = Double(GKRandomSource.sharedRandom().nextInt(upperBound: 5) / 2) + 1.0
        if(parallel) {
            act1 = SKAction.moveTo(x: node.position.x + self.baseBlockRange, duration: time)
            act2 = SKAction.moveTo(x: node.position.x - self.baseBlockRange, duration: time)
        } else {
            act1 = SKAction.moveTo(y: node.position.y + self.baseBlockRange, duration: time)
            act2 = SKAction.moveTo(y: node.position.y - self.baseBlockRange, duration: time)
        }
        let acts = SKAction.repeatForever(SKAction.sequence([act1,act2]))
        node.run(acts)
        
        self.addChild(node)
    }
    
    func createDynamicYItem(rect: CGRect)
    {
        let node = SKSpriteNode()
        node.color = .orange
        node.size = rect.size
        node.position = rect.origin
        node.zRotation = CGFloat.pi / 2
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.isDynamic = false
        
        let act1 = SKAction.moveTo(y: node.position.y + rect.size.width, duration: 2)
        let act2 = SKAction.moveTo(y: node.position.y - rect.size.width, duration: 2)
        let acts = SKAction.repeatForever(SKAction.sequence([act1,act2]))
        node.run(acts)
        
        self.addChild(node)
    }
    
    func didEnd(_ contact: SKPhysicsContact){

        self.isInContact = false

    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {

        self.isInContact = true

        
        //use the bit mask of the rocket and the asteroid to see if they have collided
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & boomCategory ) != 0 && (secondBody.categoryBitMask & canDestoryCategory) != 0 {

            if let obstacleNode = secondBody.node as? SKSpriteNode {
                obstacleNode.removeFromParent()
            }
            if((secondBody.categoryBitMask & targetCategory) != 0) {
                print("win")
                self.removeAllTimer()
                self.createButton(isWin: true)
            }
        }
        
        if (firstBody.categoryBitMask & ballCategory ) != 0 && (secondBody.categoryBitMask & canGetCategory) != 0 {
            if let obstacleNode = secondBody.node as? SKSpriteNode {
                obstacleNode.removeFromParent()
                self.bomber += 1
            }
        
        }
    }
    

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let location = touches.first?.location(in: self) {
//            print(location)
            let frame = CGRect(x: self.bubble.frame.origin.x - 50,
                               y: self.bubble.frame.origin.y - 50,
                               width: 100,
                               height: 100)
            if frame.contains(location) {
                if(self.bomber>0) {
                    self.bomber -= 1
                    self.boom(from: self.bubble)
                } else {
                    self.removeAllTimer()
                    self.createButton(isWin: false)
                }
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            if let node = atPoint(location) as? SKLabelNode,
            let name = node.name {
                if (name == "Leave") {
                    self.gameDelegate?.leaveGame?(isWin: false)
                }
            }
        }
    }

    
    override func update(_ currentTime: CFTimeInterval) {

        cam.position = bubble.position
        if(!background.contains(bubble.position)) {
            bubble.position = CGPoint(x: 100, y: 100)
        }

    }
    
    func addParallaxToView(vw: UIView) {
        let amount = 100
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        vw.addMotionEffect(group)
    }
    
    func boom(from: SKSpriteNode) {
        let laser = SKSpriteNode(imageNamed: "fire")
        laser.position = from.position
        laser.zPosition = 1
        let minRadius = min(self.frame.width,self.frame.height)
        laser.size = CGSize(width: minRadius/10, height: minRadius/10)
        
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size )
        laser.physicsBody?.isDynamic = true
        laser.physicsBody?.categoryBitMask = boomCategory
        laser.physicsBody?.contactTestBitMask = obstacleCategory
        self.addChild(laser)
        
        var actionArray = [SKAction]()
        let duration = 0.5
        actionArray.append(SKAction.moveTo(y: laser.position.y + 10, duration: duration))
        actionArray.append(SKAction.removeFromParent())
        
        let explosion = SKEmitterNode(fileNamed: "explosion")!
        explosion.position = from.position
        self.addChild(explosion)
        
        
        self.run(SKAction.wait(forDuration: 1)) {
            explosion.removeFromParent()
        }
        
        laser.run(SKAction.sequence(actionArray))
        
    }
    
}
