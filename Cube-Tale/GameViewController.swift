import UIKit
import QuartzCore
import SceneKit

import GameKit

enum PlayerState{case jumping, onFloor, onFlying}
enum BodyType: Int {case player = 1, platform = 2, pickUps = 3}

class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
    var playing: Bool = true
    
    var scnScene: SCNScene!
    var scnView: SCNView!
    var cameraNode: SCNNode!
    var spawnTime: TimeInterval = 0
    
    var gapSize: Float = 3
    var playerNode: SCNNode!
    
    var score: Int = 0

    var lastPlatformNode: SCNNode = SCNNode()
    
    //Random de plataformas
    var minSize = 5
    var maxSize = 15
    
    var gap = 3
    var minY = -1
    var maxY = 1
    
    var scoreLabel = UILabel()
    
    var playerState: PlayerState = PlayerState.onFloor
    
    var gameOverLabel: UILabel = UILabel()
    var restartButton: UIButton = UIButton()
    var menuButton: UIButton = UIButton()
    var phraseLabel: UILabel = UILabel()
    
    let audioSource = SCNAudioSource(named: "caiQuadrado.wav")
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    }
    
    func addScoreAndSubmitToGC(){
        let bestScoreInt = GKScore(leaderboardIdentifier: GameData.LEADERBOARD_ID)
        bestScoreInt.value = Int64(score)
        GKScore.report([bestScoreInt]) { (error) in
            if error != nil {
//                print(error!.localizedDescription)
            } else {
                print("Best score submitted to your leaderboard!")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupView()
        setupScene()
        setupPlayer()
        setupCamera()
        
        setMusic()
        
        //Action de aumentar a velocidade da camera e do player
        let increaseVel = SCNAction.run({_ in
            self.playerNode.physicsBody?.velocity.x = Float((self.playerNode.physicsBody?.velocity.x)! * 1.1)
            self.cameraNode.physicsBody?.velocity.x = Float((self.cameraNode.physicsBody?.velocity.x)! * 1.1)
        })
        
        playerNode.runAction(SCNAction.repeatForever(SCNAction.sequence([SCNAction.wait(duration: 10), increaseVel])))
        
        let applyVelocity = SCNAction.run({_ in
            self.playerNode.physicsBody?.velocity = SCNVector3(5, 0 , 0)
            self.cameraNode.physicsBody?.velocity = SCNVector3(x: 5, y: 0, z: 0)
        })
        
        playerNode.runAction(SCNAction.sequence([        SCNAction.wait(duration: 2)
            , applyVelocity]))
        
    }
    
    func setupView() {
        scnView = self.view as? SCNView
//        scnView.showsStatistics = true
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
        scnView.isPlaying = true
        
        scoreLabel = UILabel(frame: CGRect(x: scnView.frame.width - 90, y: 0 + 20, width: 80, height: 20))
        scoreLabel.textAlignment = .right
        scoreLabel.text = "0"
        
        scnView.addSubview(scoreLabel)
        
        self.scoreLabel.font = UIFont(name: "HelveticaNeue-Condensed", size: 47)
        self.scoreLabel.textColor = UIColor.gray
    }
    
    func setupPlayer(){
        var geometryPlayer: SCNGeometry
        geometryPlayer = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
        geometryPlayer.materials.first?.diffuse.contents = UIColor.white
        playerNode = SCNNode(geometry: geometryPlayer)
        playerNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        playerNode.position = SCNVector3(x: 0, y: 2, z: 0)
        
        playerNode.physicsBody?.friction = 0
        playerNode.physicsBody?.damping = 0
        playerNode.physicsBody?.restitution = 0

        
        playerNode.physicsBody?.categoryBitMask = BodyType.player.rawValue
        playerNode.physicsBody?.contactTestBitMask = BodyType.platform.rawValue
        
        
        playerState = .onFloor
        scnScene.rootNode.addChildNode(playerNode)
    }
    
    func spawnPlatforms(){
//        print("Posicao do player: \(playerNode.presentation.position.x) Posicao da ultima plataforma: \(lastPlatformNode.position.x)")
        
        let randomY = Helper.random(min: minY, max: maxY)
        let randomSize = Float(Helper.random(min: minSize, max: maxSize))
        
        if (cameraNode.presentation.position.x > lastPlatformNode.position.x){
            
            let geometry =  SCNBox(width: CGFloat(randomSize), height: 1, length: 1, chamferRadius: 0.1)
            
            let geometryNode = SCNNode(geometry: geometry)
            
            geometry.materials.first?.diffuse.contents = UIColor.white
            geometryNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
            geometryNode.physicsBody?.isAffectedByGravity = false
            geometryNode.physicsBody?.categoryBitMask = BodyType.platform.rawValue
            
            print("Silvio \(lastPlatformNode.boundingBox.max.x * 2) Maria \(randomSize)")
            
            geometryNode.position = SCNVector3Make(lastPlatformNode.position.x + (lastPlatformNode.boundingBox.max.x) + (randomSize/2) + gapSize, Float(randomY), 0)
            
            scnScene.rootNode.addChildNode(geometryNode)
            
            lastPlatformNode = geometryNode
            
            let willGenerate = Helper.random(min: 0, max: 3)
            if (willGenerate == 1){
                generatePickUp()
            }
        }
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.physicsWorld.contactDelegate = self
        
        var geometry: SCNGeometry
        geometry = SCNBox(width: 10, height: 1, length: 1,      chamferRadius: 0.1)
        let geometryNode = SCNNode(geometry: geometry)
        geometry.materials.first?.diffuse.contents = UIColor.white
        
        lastPlatformNode = geometryNode
        scnScene.rootNode.addChildNode(geometryNode)
        geometryNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        geometryNode.physicsBody?.isAffectedByGravity = false
        geometryNode.physicsBody?.categoryBitMask = BodyType.platform.rawValue
        
        //        scnScene.background.contents = UIImage(named: "BK")
        scnScene.background.contents = UIColor.white
    }
    
    func setMusic(){
        let audioSource = SCNAudioSource(named: "quadradoMusica.wav")
        audioSource?.loops = true
        playerNode.runAction(SCNAction.playAudio(audioSource!, waitForCompletion: true))
        
    }
    
    func setupCamera() {
        let physicGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        
        cameraNode = SCNNode(geometry: physicGeometry)
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 4.5, z: 8)
        
        let action = SCNAction.rotateBy(x: -0.3, y: -0.6, z: 0, duration: 2)
        
        cameraNode.runAction(action)
        
        cameraNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        cameraNode.physicsBody?.isAffectedByGravity = false
        cameraNode.physicsBody?.friction = 0
        cameraNode.physicsBody?.damping = 0
        
        cameraNode.camera?.vignettingPower = 1
        
//        cameraNode.camera?.bloomIntensity = 3
//        cameraNode.camera?.bloomBlurRadius = 5
//        cameraNode.camera?.focalSize = 20
//        cameraNode.camera?.focalBlurRadius = 5.0
        
//        cameraNode.camera?.wantsDepthOfField = true
//        cameraNode.camera?.fStop = 5.6
//        cameraNode.camera?.focusDistance = 0.5
//        cameraNode.camera?.wantsHDR = true
        
//        cameraNode.camera?.apertureBladeCount = 3
//        cameraNode.camera?.motionBlurIntensity = 1
//
//        cameraNode.camera?.screenSpaceAmbientOcclusionIntensity = 1.0
//        cameraNode.camera?.screenSpaceAmbientOcclusionRadius = 0.1
//        cameraNode.camera?.screenSpaceAmbientOcclusionDepthThreshold = 0.2
//        cameraNode.camera?.screenSpaceAmbientOcclusionNormalThreshold = 0.3
        
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (playerState == PlayerState.onFloor){
            playerState = PlayerState.jumping
            let force = SCNVector3Make(0, 7, 0)
            let position = SCNVector3Zero
            playerNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
            let audioSource = SCNAudioSource(named: "puloQuadrado.wav")
            playerNode.runAction(SCNAction.playAudio(audioSource!, waitForCompletion: true))
            pauseGame()
        }
    }
    

    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if (contact.nodeA.physicsBody?.categoryBitMask == BodyType.player.rawValue && contact.nodeB.physicsBody?.categoryBitMask == BodyType.platform.rawValue && playerState != .onFloor ){
            playerState = .onFloor
            
//            playerNode.runAction(SCNAction.playAudio(audioSource!, waitForCompletion: true))
        
        }
        
        if(contact.nodeB.physicsBody?.categoryBitMask == BodyType.pickUps.rawValue && contact.nodeA.physicsBody?.categoryBitMask == BodyType.player.rawValue){
            score = score + 10
            contact.nodeB.removeFromParentNode()
        }
    
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        if (playerState == .onFloor){
            playerState = .onFlying
        }
    }
    
    //MARK: - Render Silvao
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async(execute: {
            self.spawnPlatforms()
            self.setScore()
            if (self.playerNode.presentation.position.y < -5 && self.playing == true){
                let phrases = Bundle.main.object(forInfoDictionaryKey: "phrases") as! [String]
                
                let randomPhrase = phrases[Helper.random(min: 0, max: phrases.count - 1)]
                
                self.phraseLabel = UILabel(frame: CGRect(x: 0, y: -5, width: self.scnView.frame.width, height: 60))
                self.phraseLabel.font = UIFont(name: "HelveticaNeue-Condensed", size: 43)
                self.phraseLabel.textColor = UIColor.darkGray
                self.phraseLabel.text = randomPhrase
                self.phraseLabel.textAlignment = NSTextAlignment.center
                
                self.restartButton = UIButton(frame: CGRect(x: self.scnView.frame.midX - 100, y: self.scnView.frame.maxY - 30 - 15, width: 95, height: 30))
                self.restartButton.setTitle("Restart", for: .normal)
                self.restartButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Condensed", size: 57)
                self.restartButton.addTarget(self, action: #selector(self.restartAction), for: .touchUpInside)
                self.restartButton.backgroundColor = UIColor.clear
                self.restartButton.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
                self.restartButton.setTitleColor(UIColor.gray, for: UIControl.State.highlighted)
                
                self.menuButton = UIButton(frame: CGRect(x: self.scnView.frame.midX - 100 + 100, y: self.scnView.frame.maxY - 30 - 15 , width: 95, height: 30))
                self.menuButton.setTitle("Menu", for: .normal)
                self.menuButton.addTarget(self, action: #selector(self.goToMenu), for: .touchUpInside)
                self.menuButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Condensed", size: 57)
                self.menuButton.backgroundColor = UIColor.clear
                
                self.menuButton.setTitleColor(UIColor.darkGray, for: UIControl.State.normal)
                self.menuButton.setTitleColor(UIColor.gray, for: UIControl.State.highlighted)
                
                self.scnView.addSubview(self.phraseLabel)
                self.scnView.addSubview(self.gameOverLabel)
                self.scnView.addSubview(self.restartButton)
                self.scnView.addSubview(self.menuButton)
                
                self.addScoreAndSubmitToGC()
                self.playing = false
            }
        })
    }
    
    func generatePickUp(){
        let geometry =  SCNBox(width: CGFloat(0.3), height: 0.3, length: 0.3, chamferRadius: 0.1)
        
        let geometryNode = SCNNode(geometry: geometry)
        
        geometry.materials.first?.diffuse.contents = UIColor.lightGray
        
        geometryNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        geometryNode.physicsBody?.isAffectedByGravity = false
        
        geometryNode.physicsBody?.mass = 0.000001
        
        geometryNode.physicsBody?.categoryBitMask = BodyType.pickUps.rawValue
        geometryNode.physicsBody?.contactTestBitMask = BodyType.player.rawValue
//        geometryNode.physicsBody?.collisionBitMask = BodyType.pickUps.rawValue
        
        let randomPlace = Helper.random(min: Int(lastPlatformNode.position.x) , max: Int(lastPlatformNode.position.x + lastPlatformNode.boundingBox.max.x * 2))
        geometryNode.position.x = Float(randomPlace)
        geometryNode.position.y = lastPlatformNode.boundingBox.max.y + 3
        
        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    @objc func goToMenu(){
        self.menuButton.removeFromSuperview()
        self.restartButton.removeFromSuperview()
        self.gameOverLabel.removeFromSuperview()
        self.scoreLabel.removeFromSuperview()
        self.phraseLabel.removeFromSuperview()
        
        playerNode.removeAllAudioPlayers()
        playerNode.removeAllActions()
        self.performSegue(withIdentifier: "menuSegue", sender: nil)
    }
    
    @objc func restartAction(){
        self.menuButton.removeFromSuperview()
        self.restartButton.removeFromSuperview()
        self.gameOverLabel.removeFromSuperview()
        self.scoreLabel.removeFromSuperview()
        self.phraseLabel.removeFromSuperview()

        playerNode.removeAllAudioPlayers()
        playerNode.removeAllActions()
        
        self.playing = true
        
        self.viewDidLoad()
        
    }
    
    func setScore(){
        if (playing){
            score = Int(playerNode.presentation.position.x)
            scoreLabel.text = "\(score)"
        }
    }
    
    func clearPlatform(){
        
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func pauseGame(){
        let pauseAction = SCNAction.run({_ in
            self.scnView.isPlaying = false
        })
        
        playerNode.runAction(pauseAction)
    }
}
