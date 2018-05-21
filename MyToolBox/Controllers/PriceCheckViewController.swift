//
//  PriceCheckViewController.swift
//  MyToolBox
//
//  Created by Yilang Wei on 5/20/18.
//  Copyright © 2018 Yilang Wei. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON



//struct DataListModel : Codable {
//
//    let itemsList : [ItemValues]
//}


struct ItemInfo : Codable {
    let salePrice : Double
    let largeImage : String
    let name : String
}

struct Items : Codable {
    let items : [ItemInfo]
}



class PriceCheckViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    

    var priceInfoModel = itemPriceInformationModel()
    @IBOutlet weak var barcode: UILabel!
    var barcodeReturnResult = String()
    @IBAction func unwindToPriceCheckSegue(segue: UIStoryboardSegue){
        
    }
    @IBOutlet weak var displayPriceInfoTableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(barcodeReturnResult != ""){
        let fixedString =  String(barcodeReturnResult.dropFirst())
        barcode.text = fixedString
  
        getPriceInfo(barcode: fixedString)
        }
        else {
            barcode.text = "Scan an item to get barcode info"
        }
        
        displayPriceInfoTableView.delegate = self
        displayPriceInfoTableView.dataSource = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    
    // get price info from api(walmart)
    
    
    
    func getPriceInfo (barcode : String)
    {
        let apiURL = "http://api.walmartlabs.com/v1/items"
        let apiKey = "4c7zp8aqw35dyv6d5p9yy7sp"
        let apiWithParams = "\(apiURL)?apiKey=\(apiKey)&upc=\(barcode)"
        guard let fixedURL = URL(string: apiWithParams) else {return}
        URLSession.shared.dataTask(with: fixedURL) { (data, response, error) in
            guard let data = data else {return}
            
            do{
                let resultJSON = try JSONDecoder().decode(Items.self, from: data)
                self.displayItemInfo(itemInfo: resultJSON.items[0])
            }
            catch {
                let alert = UIAlertController(title: "Item Not Found", message: "This item is not exist in walmart database", preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true)
            }
        }.resume()
    }
    
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemPrice: UILabel!
    
    

    
    func displayItemInfo(itemInfo : ItemInfo) {
        guard let imageURL = URL(string: itemInfo.largeImage) else {return}
        
        
        //download image from api url
        let task = URLSession.shared.dataTask(with: imageURL) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async { // Make sure you're on the main thread here
                self.priceInfoModel.name.insert(itemInfo.name, at: 0)
                self.priceInfoModel.price.insert("$\(itemInfo.salePrice)", at: 0)
                self.priceInfoModel.image.insert(UIImage(data: data), at: 0)
                self.displayPriceInfoTableView.reloadData()
            }
        }
        task.resume()
        //starting the download task
        
    }
        
    // put priceData into table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return priceInfoModel.name.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("PriceInfoCell", owner: self, options: nil)?.first as! PriceInfoCell
        cell.itemImage.image = priceInfoModel.image[indexPath.row]
        cell.itemName.text = priceInfoModel.name[indexPath.row]
        cell.itemPrice.text = priceInfoModel.price[indexPath.row]
        print(priceInfoModel.name)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
        
    }
    

}

