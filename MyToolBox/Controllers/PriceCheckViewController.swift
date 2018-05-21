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
import CoreData



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



class PriceCheckViewController: UIViewController, UITableViewDelegate , UITableViewDataSource, UISearchBarDelegate {
    
    

    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var barcode: UILabel!
    var barcodeReturnResult = String()
    @IBAction func unwindToPriceCheckSegue(segue: UIStoryboardSegue){
        
    }
    @IBOutlet weak var displayPriceInfoTableView: UITableView!
    
    //MARK: - set up the context for core data and variable of list of the entity
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var priceInfoModel = [PriceInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadData()
        searchBar.placeholder = "Search your history"
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
        displayPriceInfoTableView.register(UINib(nibName: "PriceInfoCell", bundle: nil), forCellReuseIdentifier: "PriceInfoCell")
        searchBar.delegate = self
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
                self.saveItemInfo(itemInfo: resultJSON.items[0])
            }
            catch {
                let alert = UIAlertController(title: "Item Not Found", message: "This item is not exist in walmart database", preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true)
            }
        }.resume()
    }
    

    

    
    func saveItemInfo(itemInfo : ItemInfo) {
        guard let imageURL = URL(string: itemInfo.largeImage) else {return}
        
        
        //download image from api url
        let task = URLSession.shared.dataTask(with: imageURL) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async {
                // save data to core data
                //MARK: - indicate newItem is an Object of PriceInfo, witch is the entity, and also would be the context
                let newItem = PriceInfo(context: self.context)
                newItem.name = itemInfo.name
                newItem.price = itemInfo.salePrice
                newItem.image = data
                newItem.date = Date()
                self.priceInfoModel.insert(newItem, at: 0)
                self.saveData()
                
            }
        }
        task.resume()
        //starting the download task
        
    }
    
    //MARK: - save the context into core data
    func saveData() {
        do {
            try context.save()
        }
        catch {
            print("Error saving context")
        }
        
        displayPriceInfoTableView.reloadData()
    }
    //MARK: - load(read) data from core data
    func loadData() {
        let request : NSFetchRequest<PriceInfo> = PriceInfo.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sort]
        do {
            priceInfoModel =  try context.fetch(request)
        }
        catch
        {
            print("Error fetch data from context \(error)")
        }
    }
    
    // search bar function
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
            let request:NSFetchRequest<PriceInfo> = PriceInfo.fetchRequest()
            let predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchBar.text!)
            request.predicate = predicate
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [sortDescriptor]
            do {
                priceInfoModel =  try context.fetch(request)
            }
            catch
            {
                print("Error fetch data from context \(error)")
            }
            displayPriceInfoTableView.reloadData()
 
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadData()
            displayPriceInfoTableView.reloadData()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()

            }
        }
    }
    
    // put priceData into table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return priceInfoModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = displayPriceInfoTableView.dequeueReusableCell(withIdentifier: "PriceInfoCell", for: indexPath) as! PriceInfoCell
        if let tempImageData = priceInfoModel[indexPath.row].image {
            cell.itemImage.image = UIImage(data: tempImageData)
        }
        else {cell.itemImage.image = nil}
        cell.itemName.text = priceInfoModel[indexPath.row].name
        cell.itemPrice.text = "$\(priceInfoModel[indexPath.row].price)"

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Order is very important!!!!!!
        context.delete(priceInfoModel[indexPath.row])
        priceInfoModel.remove(at: indexPath.row)
        
        
        saveData() 
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100

    }


}

