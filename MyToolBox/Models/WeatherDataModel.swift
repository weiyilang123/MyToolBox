//
//  WeatherDataModel.swift
//  MyToolBox
//
//  Created by Yilang Wei on 5/18/18.
//  Copyright © 2018 Yilang Wei. All rights reserved.
//

import Foundation

class WeatherDataModel {
    
    //Current weather data
    var city : String = ""
    var temperature : Double = 0
    var weatherIcon : String = ""
    
    //five day weather data
    var fiveDayTemperature : [Double] = []
    var fiveDayDateAndTime : [String] = []
    var fiveDayWeatherIcon : [String] = []
        

    
}
