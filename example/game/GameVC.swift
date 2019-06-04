import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : String) -> SKNode? {
        if let path = Bundle.main.path(forResource: file, ofType: "sks") {
            let sceneData = try! NSData(contentsOfFile: path, options: .mappedIfSafe)

           //var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            let archiver = NSKeyedUnarchiver(forReadingWith: sceneData as Data)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}




class GameVC: UIViewController {

    @IBOutlet weak var gameView: SKView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.gameView {
            if let scene = GameScene.unarchiveFromFile(file: "GameScene") as? GameScene {
                // Configure the view.
                
                view.showsFPS = true
                view.showsNodeCount = true
                
               
                scene.gameDelegate = self
                
                
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                view.ignoresSiblingOrder = true
                
                /* Set the scale mode to scale to fit the window */
                scene.scaleMode = .aspectFill
                
                view.presentScene(scene)
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    func prefersStatusBarHidden() -> Bool {
        return true
    }
  
    override var shouldAutorotate: Bool {
        return false
    }
  
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

}

extension GameVC: GameDelegate
{
    func leaveGame(isWin: Bool)
    {
        self.dismiss(animated: true)
    }
}
