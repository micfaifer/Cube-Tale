//
//  TodayViewController.swift
//  Today-Phrases
//
//  Created by Michelle Faifer on 17/02/18.
//  Copyright © 2018 Micfaifer. All rights reserved.
//


import UIKit
import LTMorphingLabel
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, LTMorphingLabelDelegate {
    @IBOutlet weak var phraseLabel: LTMorphingLabel!
    
    let phrases = Bundle.main.object(forInfoDictionaryKey: "phrases") as! [String]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phraseLabel.lineBreakMode = .byWordWrapping
        phraseLabel.numberOfLines = 3
        phraseLabel.delegate = self
        phraseLabel.morphingEnabled = true
        phraseLabel.morphingEffect = .fall
       
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(phrasesTap))
        
        tap.numberOfTapsRequired = 1
        newPhrase()
        self.view.addGestureRecognizer(tap)
        
    }
    
    func newPhrase (){
        let randomPhrase = phrases[self.random(min: 0, max: phrases.count - 1)]
        phraseLabel.text = randomPhrase
    }
    
    @objc func phrasesTap(){
        print("tap aqui")
        phraseLabel.text = phraseLabel.text
        phraseLabel.morphingEnabled = true
        phraseLabel.morphingEffect = .fall
        phraseLabel.morphingDuration = 1
        newPhrase()
    }
    
    func random(min: Int, max: Int) -> Int{
        let result = Int(arc4random_uniform(UInt32(max - min + 1))) +   min
        return result
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
    func morphingDidStart(_ label: LTMorphingLabel) {
        print("comecou")
    }
    
}
