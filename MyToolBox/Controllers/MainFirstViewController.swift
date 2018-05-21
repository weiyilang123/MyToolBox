//
//  ViewController.swift
//  MyToolBox
//
//  Created by Yilang Wei on 5/17/18.
//  Copyright © 2018 Yilang Wei. All rights reserved.
//

import UIKit

class MainFirstViewController: UIViewController {

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func weatherButton(_ sender: UIButton) {
        
        performSegue(withIdentifier: "weatherSegue", sender: self)
        
    }
    
    @IBAction func translateButton(_ sender: UIButton) {
        
        performSegue(withIdentifier: "translateSegue", sender: self)
    }
    
    @IBAction func priceCheckButton(_ sender: UIButton) {
        
        performSegue(withIdentifier: "priceCheckSegue", sender: self)
    }
}

