//
//  PriceDetailViewController.swift
//  MyToolBox
//
//  Created by Yilang Wei on 5/21/18.
//  Copyright © 2018 Yilang Wei. All rights reserved.
//

import UIKit
import SwiftyJSON

class PriceDetailViewController: UIViewController {

    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemPrice: UILabel!
    @IBOutlet weak var itemDetailTextView: UITextView!
    
    var itemImage : Data? {
        didSet {
           
        }
    }
    
    var itemDetail : PriceDetail? {
        didSet {
            


        }
    }
    
 
    
   var url : URL?
    override func viewDidLoad() {
        super.viewDidLoad()
        itemDetailTextView.isEditable = false
        itemDetailTextView.isScrollEnabled = true

        
        if let tempImage = itemImage {
            image.image = UIImage(data: tempImage)
        } else {
            image.image = UIImage(named: "unknow")
            
        }
        
        if let tempItemDetail = itemDetail {
            itemName.text = tempItemDetail.name!
            itemPrice.text = "$\(tempItemDetail.price)"
            itemDetailTextView.text = "Item ID: \(tempItemDetail.itemId!)\n\nUPC: \(tempItemDetail.upc!)\n\nDescription: \(tempItemDetail.longDescription!)\n\nSeller Information: \(tempItemDetail.sellerInfo!)\n\nStock Status: \(tempItemDetail.stockStatus!)\n\nProduct Link:*****************************\n\n"
            url = URL(string: tempItemDetail.productURL!)
            
            
            let buttonHeight: CGFloat = 44
            let contentInset: CGFloat = 8
            
            //inset the textView
            itemDetailTextView.textContainerInset = UIEdgeInsets(top: contentInset, left: contentInset, bottom: (buttonHeight+contentInset*3), right: contentInset)
            
            let button = UIButton(frame: CGRect(x: contentInset, y: itemDetailTextView.contentSize.height + 10 - contentInset, width: itemDetailTextView.contentSize.width-contentInset*2, height: buttonHeight))
            
            //setup your button here
            button.setTitle("Press to The Item Website", for: UIControlState.normal)
            button.setTitleColor(UIColor.white, for: UIControlState.normal)
            button.backgroundColor = UIColor.black
            button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
            //Add the button to the text view
            itemDetailTextView.addSubview(button)
            
        }
       
    }

    @objc func buttonAction(sender: UIButton!) {
        
        if let tempURL = url {
        UIApplication.shared.open(tempURL, options: [:], completionHandler: nil)
        } else {
            
        }
    }



}
