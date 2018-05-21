//
//  WeatherViewController.swift
//  MyToolBox
//
//  Created by Yilang Wei on 5/17/18.
//  Copyright © 2018 Yilang Wei. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation

class WeatherViewController: UIViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {

   
    
    

    //UI Elements

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherIconImage: UIImageView!
    @IBOutlet weak var tempUnitChange: UISegmentedControl!
    @IBOutlet weak var displayFiveDayWeather: UICollectionView!
    @IBOutlet weak var displayFiveDayWeatherCollectionView: UICollectionView!
    let pickerView = UIPickerView()
    
    @IBOutlet weak var pickDate: UITextField!
    // !step- how to use location manager
    // @Step - request api and manipulate data
    
    
    // !step1 Create an instance of the CLLocationManager class
    let locationManager = CLLocationManager()
    
   
    // @step1 - Create variables, store url and API ID key,
    let currentWeatherURL = "http://api.openweathermap.org/data/2.5/weather"
    let fiveDayWeatherURL = "http://api.openweathermap.org/data/2.5/forecast"
    let apiID = "4519a921992a2fe42911e11ba17006dc"
    let fiveDaysWeatherURL = ""
    
    let weatherDataModel = WeatherDataModel()
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // !step2 Assign a custom object to the delegate property. This object must conform to the CLLocationManagerDelegate protocol.
        locationManager.delegate = self
        // !step3 Configure the properties related to the service you intend to use. For example, when getting location updates, always configure the distanceFilter and desiredAccuracy properties.
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // !step4 Call the appropriate method to start the delivery of events. (request authrication and set plist)
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //UI segmented control setting
        tempUnitChange.setTitle("℃", forSegmentAt: 0)
        tempUnitChange.setTitle("℉", forSegmentAt: 1)
        //displayFiveDayWeather.
        pickerView.delegate = self
        pickDate.inputView = pickerView
        
    }
    // Button to change city and make Api call
    @IBAction func currentLocationWeather(_ sender: UIButton) {
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    
    }
    
    
    
    @IBAction func changeCity(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let changeCityAlert = UIAlertController(title: "Change City", message: "Enter a city name to get the weather", preferredStyle: .alert)
        let action = UIAlertAction(title: "Change", style: .default) { (action) in
            var weatherAPIRequestParameter : [String : String] = [:]
            if let temp = textField.text {
                weatherAPIRequestParameter = ["q" : temp, "appid" : self.apiID]
                self.getCurrentWeatherData(url: self.currentWeatherURL, parameter: weatherAPIRequestParameter)
                self.getFiveDayWeatherData(url: self.fiveDayWeatherURL, parameter: weatherAPIRequestParameter)
            }
            else{
                
            }
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        changeCityAlert.addAction(cancelAction)
        changeCityAlert.addAction(action)
        changeCityAlert.addTextField { (field) in
            textField = field
        }
        present(changeCityAlert, animated: true, completion: nil)
        }
        
    
    
    
    //MARK: - Get location and make API request
    // !step5 Tells the delegate that new location data is available.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //get the last and most accurate location data
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            // !step6 - Stop getting location data and set delegate to nil
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            
            //@ step2 Prepare the format for API url and pass the parameter into getWeatherData function
            let weatherAPIRequestParameter = ["lat" : String(location.coordinate.latitude), "lon" : String(location.coordinate.longitude), "appid" : apiID]
            getCurrentWeatherData(url: currentWeatherURL, parameter: weatherAPIRequestParameter)
            getFiveDayWeatherData(url: fiveDayWeatherURL, parameter: weatherAPIRequestParameter)
        }
    }
    
    // !step6 If location unavailable then inform the user
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print(error)
        cityLabel.text = "Unable to get location"
        
    }
    
    // @step3 getWeatherData function
    func getCurrentWeatherData(url : String, parameter: [String:String]) {
        // Use Alamofire to make the api request
        Alamofire.request(url, method: .get, parameters: parameter).responseJSON { (response) in
            if response.result.isSuccess{
                
                //format the weather data into standard JSON
                let weatherJSON : JSON = JSON(response.result.value!)
                self.updateCurrentWeatherData(json: weatherJSON)
                
            }
            
            }
        }
    
    func getFiveDayWeatherData(url : String, parameter: [String:String]) {
        Alamofire.request(url, method: .get, parameters: parameter).responseJSON { (response) in
            if response.result.isSuccess{
                
                //format the weather data into standard JSON
                let weatherJSON : JSON = JSON(response.result.value!)

                //self.updateWeatherData(json: weatherJSON)
                self.displayFiveDayWeatherCollectionView.delegate = self
                self.displayFiveDayWeatherCollectionView.dataSource = self
                self.updateFiveDayWeatherData(json: weatherJSON)
                
                
            }
            
        }
    }
    // Use Model to convert JSON to readable data
    // @step4 updateWeatherData using model (create weather data model)
    func updateCurrentWeatherData(json: JSON) {
 
        if let temperature = json["main"]["temp"].double {

            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.temperature = temperature
            weatherDataModel.weatherIcon = json["weather"][0]["icon"].stringValue
            displayWeatherOnWeatherView()
            
            

        }
        else{
            
        }
    }
    
    
    func updateFiveDayWeatherData(json: JSON) {
        
        var fiveDayTemperature : [Double] = []
        var fiveDayDateAndTime : [String] = []
        var fiveDayWeatherIcon : [String] = []
        weatherDataModel.fiveDayTemperature = []
        weatherDataModel.fiveDayDateAndTime = []
        weatherDataModel.fiveDayWeatherIcon = []
        if let _ = json["list"][0]["main"]["temp"].double {
            for i in 0...json["list"].count-1 {
                
                fiveDayTemperature.append(json["list"][i]["main"]["temp"].doubleValue)
                fiveDayDateAndTime.append(json["list"][i]["dt_txt"].stringValue)
                fiveDayWeatherIcon.append(json["list"][i]["weather"][0]["icon"].stringValue)
            }
        }
        else{
            print("no data")
        }
        weatherDataModel.fiveDayTemperature = fiveDayTemperature
        weatherDataModel.fiveDayDateAndTime = fiveDayDateAndTime
        weatherDataModel.fiveDayWeatherIcon = fiveDayWeatherIcon
        
        prepareFiveDayWeatherData()
       
    }
    
    //MARK: Update Weather UI View
    func displayWeatherOnWeatherView(){
        weatherIconImage.image = UIImage(named: weatherDataModel.weatherIcon)
            cityLabel.text = weatherDataModel.city
            let displayTemp = Int(weatherDataModel.temperature - 273.15)
            temperatureLabel.text = "\(displayTemp)℃"
    }

    
    // Temperature unit select
    var unitSelectIndex = 0
    @IBAction func temperatureUnitSelect(_ sender: UISegmentedControl) {
        switch tempUnitChange.selectedSegmentIndex
        {
        case 0:
            temperatureLabel.text = "\(Int(weatherDataModel.temperature - 273.15))℃"
            unitSelectIndex = 0
        case 1:
            let kToF = weatherDataModel.temperature * ( 9 / 5 ) - 459.67
            temperatureLabel.text = "\(Int(kToF))℉"
            unitSelectIndex = 1
            
        default:
            break
        }
        displayFiveDayWeatherCollectionView.reloadData()
       
        
    }
    
    
    var date : [String] = []
    var time : [String] = []
    var temp : [Int] = []
    var icon : [String] = []
    var temporaryDate = ""
    var firstDayDateData : [String] = []
    var firstDayTimeData : [String] = []
    var firstDayTempData : [Int] = []
    var firstDayIconData : [String] = []
    var secondDayDateData : [String] = []
    var secondDayTimeData : [String] = []
    var secondDayTempData : [Int] = []
    var secondDayIconData : [String] = []
    var thirdDayDateData : [String] = []
    var thirdDayTimeData : [String] = []
    var thirdDayTempData : [Int] = []
    var thirdDayIconData : [String] = []
    var fourthDayDateData : [String] = []
    var fourthDayTimeData : [String] = []
    var fourthDayTempData : [Int] = []
    var fourthDayIconData : [String] = []
    var fifthDayDateData : [String] = []
    var fifthDayTimeData : [String] = []
    var fifthDayTempData : [Int] = []
    var fifthDayIconData : [String] = []
    var fiveDateArray : [String] = []
    func prepareFiveDayWeatherData()
    {
        date = []
        time = []
        temp = []
        icon = []
        temporaryDate = ""
        firstDayDateData = []
        firstDayTimeData = []
        firstDayTempData = []
        firstDayIconData = []
        secondDayDateData = []
        secondDayTimeData = []
        secondDayTempData = []
        secondDayIconData = []
        thirdDayDateData = []
        thirdDayTimeData = []
        thirdDayTempData = []
        thirdDayIconData = []
        fourthDayDateData = []
        fourthDayTimeData = []
        fourthDayTempData = []
        fourthDayIconData = []
        fifthDayDateData = []
        fifthDayTimeData = []
        fifthDayTempData = []
        fifthDayIconData = []
        fiveDateArray = []
        if weatherDataModel.fiveDayDateAndTime.count != 0{
        for i in 0...(weatherDataModel.fiveDayDateAndTime.count-1){
            date.append(String(weatherDataModel.fiveDayDateAndTime[i].prefix(10)))
            time.append(String(weatherDataModel.fiveDayDateAndTime[i].suffix(8).prefix(5)))
            temp.append(Int(weatherDataModel.fiveDayTemperature[i]))
            icon.append(String(weatherDataModel.fiveDayWeatherIcon[i]))
            
           
        }
        
        temporaryDate = date[0]
        fiveDateArray.append(date[0])
        var count = 0
        for i in 0...date.count-1 {
            
            if date[i] == temporaryDate {
                
                switch(count){
                case 0:
                    firstDayDateData.append(date[i])
                    firstDayTimeData.append(time[i])
                    firstDayTempData.append(temp[i])
                    firstDayIconData.append(icon[i])
                    break
                case 1:
                    secondDayDateData.append(date[i])
                    secondDayTimeData.append(time[i])
                    secondDayTempData.append(temp[i])
                    secondDayIconData.append(icon[i])
                    break
                case 2:
                    thirdDayDateData.append(date[i])
                    thirdDayTimeData.append(time[i])
                    thirdDayTempData.append(temp[i])
                    thirdDayIconData.append(icon[i])
                    break
                case 3:
                    fourthDayDateData.append(date[i])
                    fourthDayTimeData.append(time[i])
                    fourthDayTempData.append(temp[i])
                    fourthDayIconData.append(icon[i])
                    break
                case 4:
                    fifthDayDateData.append(date[i])
                    fifthDayTimeData.append(time[i])
                    fifthDayTempData.append(temp[i])
                    fifthDayIconData.append(icon[i])
                    break
                default: break
                    
                }
                
            }
            else {
                count += 1
                temporaryDate = date[i]
                fiveDateArray.append(date[i])
               
            }
            
        }
            pickDate.text = fiveDateArray[0]
            displayFiveDayWeatherCollectionView.reloadData()
        }
        else
        {
            let alert = UIAlertController(title: "Unavailable City", message: "Please enter the correct city name", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
        
        
        
    }
    
    
    // display five days weather data
    var nthDate = 0;
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch(nthDate){
        case 0:
            return firstDayDateData.count
        case 1:
           
            return secondDayDateData.count
        case 2:
           
            return thirdDayDateData.count
        case 3:
            
            return fourthDayDateData.count
        case 4:
            
            return fifthDayDateData.count
        default:

            return 1
         
            
        }
      
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fiveDayWeatherCell", for: indexPath) as! WeatherDisplayCollectionViewCell
        
        switch(nthDate){
        case 0:
            if unitSelectIndex == 0 {
                cell.fiveDaveTemperature.text = "\(Int(Double(firstDayTempData[indexPath.row]) - 273.15))℃"
            }
            else {
                cell.fiveDaveTemperature.text = "\(Int(Double(firstDayTempData[indexPath.row])  * ( 9 / 5 ) - 459.67))℉"
            }
            cell.fiveDayTime.text = "\(firstDayTimeData[indexPath.row])"
            cell.fiveDayWeatherIcon.image = UIImage(named: "\(firstDayIconData[indexPath.row])")
            break
        case 1:
            if unitSelectIndex == 0 {
                cell.fiveDaveTemperature.text = "\(Int(Double(secondDayTempData[indexPath.row]) - 273.15))℃"
            }
            else {
                cell.fiveDaveTemperature.text = "\(Int(Double(secondDayTempData[indexPath.row])  * ( 9 / 5 ) - 459.67))℉"
            }
            cell.fiveDayTime.text = "\(secondDayTimeData[indexPath.row])"
            cell.fiveDayWeatherIcon.image = UIImage(named: "\(secondDayIconData[indexPath.row])")
            break
            
        case 2:
            if unitSelectIndex == 0 {
                cell.fiveDaveTemperature.text = "\(Int(Double(thirdDayTempData[indexPath.row]) - 273.15))℃"
            }
            else {
                cell.fiveDaveTemperature.text = "\(Int(Double(thirdDayTempData[indexPath.row])  * ( 9 / 5 ) - 459.67))℉"
            }
            cell.fiveDayTime.text = "\(thirdDayTimeData[indexPath.row])"
            cell.fiveDayWeatherIcon.image = UIImage(named: "\(thirdDayIconData[indexPath.row])")
            break
           
        case 3:
            if unitSelectIndex == 0 {
                cell.fiveDaveTemperature.text = "\(Int(Double(fourthDayTempData[indexPath.row]) - 273.15))℃"
            }
            else {
                cell.fiveDaveTemperature.text = "\(Int(Double(fourthDayTempData[indexPath.row])  * ( 9 / 5 ) - 459.67))℉"
            }
            cell.fiveDayTime.text = "\(fourthDayTimeData[indexPath.row])"
            cell.fiveDayWeatherIcon.image = UIImage(named: "\(fourthDayIconData[indexPath.row])")
            break
            
        case 4:
            if unitSelectIndex == 0 {
                cell.fiveDaveTemperature.text = "\(Int(Double(fifthDayTempData[indexPath.row]) - 273.15))℃"
            }
            else {
                cell.fiveDaveTemperature.text = "\(Int(Double(fifthDayTempData[indexPath.row])  * ( 9 / 5 ) - 459.67))℉"
            }
            cell.fiveDayTime.text = "\(fourthDayTimeData[indexPath.row])"
            cell.fiveDayWeatherIcon.image = UIImage(named: "\(fourthDayIconData[indexPath.row])")
            break
           
        default:
            break
        }
        

        
        
        
        return cell
    }
    
    
    //PickerView func
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fiveDateArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        
        return fiveDateArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        pickDate.text = fiveDateArray[row]
        nthDate = row
        displayFiveDayWeatherCollectionView.reloadData()
        self.view.endEditing(true)
    }
    

}


