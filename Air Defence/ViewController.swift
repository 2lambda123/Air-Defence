import UIKit
import SceneKit
import SpriteKit
import ARKit
import AVFoundation

class ViewController: UIViewController, SCNPhysicsContactDelegate, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    func fire(_ colour: UIColor){
        let (direction, position) = getCameraVector()
        let start = Projectile.start
        let end = Projectile.end
        let origin = SCNVector3(position.x + direction.x * start, position.y + direction.y * start, position.z + direction.z * start)
        let target = SCNVector3(position.x + direction.x * end, position.y + direction.y * end, position.z + direction.z * end)
        addEntity(Projectile(origin: origin, target: target, colour: colour))
    }
    var i = 0
    @IBAction func Rotation(_ sender: Any) {
        i += 1
        i %= 35
        switch i {
        case 0:
            fire(UIColor.brown)
        case 5:
            fire(UIColor.blue)
        case 10:
            fire(UIColor.red)
        case 15:
            fire(UIColor.yellow)
        case 20:
            fire(UIColor.green)
        case 25:
            fire(UIColor.black)
        case 30:
            fire(UIColor.cyan)
            
        default:
            print(i)
        }
    }

    @IBAction func SwipeRight(_ sender: Any) {
        fire(UIColor.yellow)
        
    }
    @IBAction func SwipeLeft(_ sender: Any) {
        fire(UIColor.green)
    }
    @IBAction func touchSight(_ sender: Any) {
        fire(UIColor.red)
    }
    @IBAction func SwipeDown(_ sender: Any) {
        fire(UIColor.brown)
    }
    
    
    @IBAction func SwipeUp(_ sender: Any) {
        fire(UIColor.cyan)
    }
    
    public func addEntity(_ entity: Entity) {
        entity.setID(entityCounter)
        pendingEntities.append(entity)
        entityCounter = entityCounter &+ 1
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    public func getCameraVector() -> (SCNVector3, SCNVector3) {
        if let frame = sceneView.session.currentFrame {
            let transform = SCNMatrix4(frame.camera.transform)
            let direction = SCNVector3(-1 * transform.m31, -1 * transform.m32, -1 * transform.m33) // Orientation of camera in world space.
            let position = SCNVector3(transform.m41, transform.m42, transform.m43) // Location of camera in world space.
            return (direction, position)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var nodeA, nodeB: SCNNode?
        if contact.nodeA.physicsBody?.categoryBitMask == Projectile.bitMask {
            nodeA = contact.nodeA
            nodeB = contact.nodeB
        }
        else {
            nodeA = contact.nodeB
            nodeB = contact.nodeA
        }
        if let nodeA = nodeA, let nodeB = nodeB {
            if nodeA.physicsBody?.categoryBitMask == Projectile.bitMask && nodeB.physicsBody?.categoryBitMask == EnemyShip.bitMask {
                if let particleSystem = SCNParticleSystem(named: "explosion", inDirectory: "art.scnassets") {
                    playSound(sound: .explosion)
                    let explosionNode = SCNNode()
                    explosionNode.addParticleSystem(particleSystem)
                    explosionNode.position = nodeA.position
                    sceneView.scene.rootNode.addChildNode(explosionNode)
                }
                if let nameA = nodeA.name, let nameB = nodeB.name {
                    var newEntities: [Entity] = []
                    for entity in entities {
                        if entity.getID() == nameA || entity.getID() == nameB {
                            entity.die()
                            deadEntities.append(entity)
                        }
                        else {
                            newEntities.append(entity)
                        }
                    }
                    entities = newEntities
                }
            }
        }
    }
    
    private func playSound(sound: Sound) {
        DispatchQueue.main.async {
            do
            {
                if let soundPath = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3", subdirectory: "Sounds") {
                    self.soundPlayer = try AVAudioPlayer(contentsOf: soundPath)
                    self.soundPlayer?.play()
                }
            }
            catch let error as NSError {
                print(error.description)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if worldIsSetUp {
            for entity in pendingEntities {
                sceneView.scene.rootNode.addChildNode(entity.getNode())
            }
            var newEntities: [Entity] = pendingEntities
            pendingEntities = []
            for entity in entities {
                if entity.dead() {
                    deadEntities.append(entity)
                }
                else {
                    entity.update(self)
                    newEntities.append(entity)
                }
            }
            entities = newEntities
            for entity in deadEntities {
                entity.remove()
            }
        }
        else {
            setUpWorld()
        }
    }
    
    /*func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        if worldIsSetUp {
            var newEntities: [Entity] = pendingEntities
            pendingEntities = []
            for entity in entities {
                if entity.dead() {
                    deadEntities.append(entity)
                }
                else {
                    entity.update(self)
                    newEntities.append(entity)
                }
            }
            entities = newEntities
            for entity in deadEntities {
                entity.remove()
            }
        }
        else {
            setUpWorld()
        }
    }*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    private func setUpWorld() {
        if let currentFrame = sceneView.session.currentFrame {
            if EnemyShip.scene != nil {
                for _ in 1...10 {
                    addEntity(EnemyShip(currentFrame))
                }
                worldIsSetUp = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the scene to the view
        sceneView.scene = SCNScene()

        // Set the view's delegates
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        //shipHud = HUD(size: self.view.bounds.size)
        //sceneView.overlaySKScene = SKScene(size: self.view.bounds.size)
        //sceneView.overlaySKScene?.addChild(SKSpriteNode(imageNamed: "art.scnassets/crosshairs.png"))
        
        // Toggle debugging options
        //sceneView.debugOptions = //.showPhysicsShapes // ARSCNDebugOptions.showWorldOrigin
        
        // Set EnemyShip's scene
        EnemyShip.scene = SCNScene(named: "art.scnassets/enemy_ship.scn")!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    private var entities: [Entity] = []
    private var entityCounter: Int = 0
    private var pendingEntities: [Entity] = []
    private var deadEntities: [Entity] = []
    private var soundPlayer: AVAudioPlayer?
    private var worldIsSetUp: Bool = false

    private enum Sound: String {
        case explosion = "explosion"
    }
    
}
