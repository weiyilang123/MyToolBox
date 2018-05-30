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
    //let itemId : String
    
}
struct Items : Codable {
    let items : [ItemInfo]
}



class PriceCheckViewController: UIViewController, UITableViewDelegate , UITableViewDataSource, UISearchBarDelegate {
    
    
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var barcode: UILabel!
    var barcodeReturnResult = String() {
        didSet{
            if(barcodeReturnResult != ""){
                let fixedString =  String(barcodeReturnResult.dropFirst())
                barcode.text = fixedString
                
                getPriceInfo(barcode: fixedString)
                
            }
            else {
                barcode.text = "Scan an item to get barcode info"
            }
        }
    }
    @IBAction func unwindToPriceCheckSegue(segue: UIStoryboardSegue){
    }
    @IBOutlet weak var displayPriceInfoTableView: UITableView!
    
    //MARK: - set up the context for core data and variable of list of the entity
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let context2 = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var priceInfoModel = [PriceInfo]()
    var priceDetailModel = [PriceDetail]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadData()
        loadDetailData()
        // loadDetailData()
        
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        
        searchBar.placeholder = "Search your history"
        let headerView: UIView = UIView.init(frame: CGRect(x: 1, y: 50, width: screenWidth, height: 30))
        headerView.backgroundColor = UIColor(red:0.00, green:0.70, blue:1.00, alpha:1.0)
        
        let labelView: UILabel = UILabel.init(frame: CGRect(x: 4, y: 5, width: screenWidth, height: 24))
        labelView.text = "Scan History"
        
        displayPriceInfoTableView.addSubview(labelView)
        self.displayPriceInfoTableView.tableHeaderView = headerView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        displayPriceInfoTableView.delegate = self
        displayPriceInfoTableView.dataSource = self
        displayPriceInfoTableView.register(UINib(nibName: "PriceInfoCell", bundle: nil), forCellReuseIdentifier: "PriceInfoCell")
        searchBar.delegate = self
    }
    
    
    
    
    
    
    // get price info from api(walmart)
    
    
    var shareData : Data?
    func getPriceInfo (barcode : String)
    {
        let apiURL = "http://api.walmartlabs.com/v1/items"
        let apiKey = "4c7zp8aqw35dyv6d5p9yy7sp"
        let apiWithParams = "\(apiURL)?apiKey=\(apiKey)&upc=\(barcode)"
        guard let fixedURL = URL(string: apiWithParams) else {return}
        URLSession.shared.dataTask(with: fixedURL) { (data, response, error) in
            guard let data = data else {return}
            self.shareData = data
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
                newItem.like = false
                self.priceInfoModel.insert(newItem, at: 0)
                if let data = self.shareData{
                    self.getPriceDetailInfo(data: data)
                }
                else {
                    print("No JSON data")
                }
                
                self.saveData()
                
            }
        }
        task.resume()
        //starting the download task
        
    }
    
    func getPriceDetailInfo(data : Data)
    {
        do {
            let priceJSON : JSON = try JSON(data: data)
            savePriceDetailInfo(json: priceJSON)
        }
        catch {
            print ("No JSON Object")
        }
        
    }
    
    func savePriceDetailInfo(json: JSON) {
        let newItemDetail = PriceDetail(context: self.context2)
        newItemDetail.itemId = json["items"][0]["itemId"].stringValue
        newItemDetail.longDescription = json["items"][0]["shortDescription"].stringValue
        newItemDetail.productURL = json["items"][0]["productUrl"].stringValue
        newItemDetail.sellerInfo = json["items"][0]["sellerInfo"].stringValue
        newItemDetail.stockStatus = json["items"][0]["stock"].stringValue
        newItemDetail.upc = json["items"][0]["upc"].stringValue


        newItemDetail.name = json["items"][0]["name"].stringValue

        newItemDetail.price = json["items"][0]["salePrice"].doubleValue
        

        
        
       // download image from api url

        let sameItem : PriceInfo? = priceInfoModel[0]
        newItemDetail.parentItem = sameItem
        priceDetailModel.insert(newItemDetail, at: 0)
        saveDetailData()
    }
    
    //MARK: - save the context into core data
    func saveData() {
        do {
            try context.save()
        }
        catch {
            print("Error saving context1 \(error)")
        }
        
        displayPriceInfoTableView.reloadData()
    }
    
    func saveDetailData() {
        do {
            try context2.save()
        }
        catch {
            print("Error saving context2 \(error)")
        }
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
    
    func loadDetailData() {
        let request : NSFetchRequest<PriceDetail> = PriceDetail.fetchRequest()
        do {
            priceDetailModel = try context2.fetch(request)

        }
        catch
        {
            print("Error fetch data from context2 \(error)")
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      
        if segue.identifier == "priceDetailSegue"{
    
            let destinationVC = segue.destination as! PriceDetailViewController
             if let indexPath = displayPriceInfoTableView.indexPathForSelectedRow{
                destinationVC.itemDetail = priceDetailModel[priceDetailModel.count - 1 - indexPath.row]
                destinationVC.itemImage = priceInfoModel[indexPath.row].image
               


            }
        }
    }
    
    
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
        if(priceInfoModel[indexPath.row].like == true){
            cell.starOrNot.textColor = UIColor(red:1.00, green:0.69, blue:0.00, alpha:1.0)
        }
        else {
            cell.starOrNot.textColor = UIColor(red:0.72, green:0.72, blue:0.72, alpha:1.0)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        loadDetailData()
        performSegue(withIdentifier: "priceDetailSegue", sender: self)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        var path : Int = 0
        let detail = UITableViewRowAction(style: .normal, title: "❤️\nLike") { action, IndexPath in
            path = IndexPath.row
            if self.priceInfoModel[IndexPath.row].like == false {
                self.priceInfoModel[IndexPath.row].like = true
                action.title = "💔\nDislike"
                
            }else
            {
                self.priceInfoModel[IndexPath.row].like = false
                action.title = "❤️\nLike"
            }
            self.saveData()
            self.displayPriceInfoTableView.reloadData()
            
        }
        if self.priceInfoModel[path].like == false {
            detail.title = "❤️\nLike"
        }else {
            detail.title = "💔\nDislike"
        }
        detail.backgroundColor = .lightGray
        
        
        
        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "🗑\nDelete") { action, IndexPath in
            // Order is very important!!!!!!
            self.context.delete(self.priceInfoModel[IndexPath.row])
            self.priceInfoModel.remove(at: IndexPath.row)
            self.priceDetailModel.remove(at: IndexPath.row)
            
            
            self.displayPriceInfoTableView.reloadData()
            self.saveData()
            self.saveDetailData()
            self.displayPriceInfoTableView.reloadData()
            
            
            self.loadDetailData()
            
            
        }
        
        delete.backgroundColor = .red
        
        return [delete, detail]
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    
    
}
