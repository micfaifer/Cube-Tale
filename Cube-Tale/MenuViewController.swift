//
//  MenuViewController.swift
//
//  Created by Michelle Faifer on 23/08/17.
//  Copyright © 2017 Micfaifer. All rights reserved.
//

import Foundation
import UIKit
import GameKit

class MenuViewController: UIViewController, GKGameCenterControllerDelegate {
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticateLocalPlayer()
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func checkGCLeaderboard(_ sender: Any) {
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = GameData.LEADERBOARD_ID
        
        present(gcVC, animated: true, completion: nil)
    }
    
    // MARK: - AUTHENTICATE LOCAL PLAYER
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: {
                    (leaderboardIdentifer, error) in
                    if error != nil {
                        print(error ?? "")
                    } else {
                        self.gcDefaultLeaderBoard = leaderboardIdentifer!
                        
                    }
                })
                
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                print(error ?? "")
            }
        }
    }
}
