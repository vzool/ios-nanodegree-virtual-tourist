//
//  Flicker.swift
//  Virtual Tourist
//
//  Created by Abdelaziz Elrashed on 8/10/15.
//  Copyright (c) 2015 Abdelaziz Elrashed. All rights reserved.
//

import Foundation
import CoreData
import UIKit

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "bc2532f8a799b16a94e4a64fb71346ed"
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}

class Flickr{
    
    static internal let ImagesPerPage = 10
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    static internal func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    static internal func createBoundingBoxString(latitude: NSNumber, longitude:NSNumber) -> String {
        
        let lat = latitude.doubleValue
        let lon = longitude.doubleValue
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(lon - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(lat - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(lon + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(lat + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    static internal func getImagesTotalPageFromFlickr(methodArguments: [String : AnyObject], view: UIViewController) {
        
        dispatch_async(dispatch_get_main_queue()){
            (view as? MapViewController)!.networkActivityStart()
        }
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                
                println("Could not complete the request \(error)")
                
                dispatch_async(dispatch_get_main_queue()){
                    (view as? MapViewController)!.networkActivityError("\(error)")
                }
                
            } else {
                
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    if let totalPages = photosDictionary["pages"] as? Int {
                        
                        println("# Total Pages: \(totalPages)")
                        
                        if let totalImages = photosDictionary["total"] as? String{
                            
                            println("# Total Images: \(totalImages.toInt())")
                            
                            dispatch_async(dispatch_get_main_queue()){
                                (view as? MapViewController)!.networkActivitySaveTotalPages(totalPages, totalImages: totalImages.toInt()!)
                            }
                        }
                        
                    } else {
                        
                        println("Cant find key 'pages' in \(photosDictionary)")
                        
                        dispatch_async(dispatch_get_main_queue()){
                            (view as? MapViewController)!.networkActivityError("Cant find key 'pages' in \(photosDictionary)")
                        }
                    }
                    
                } else {
                    
                    println("Cant find key 'photos' in \(parsedResult)")
                    
                    dispatch_async(dispatch_get_main_queue()){
                        (view as? MapViewController)!.networkActivityError("Cant find key 'photos' in \(parsedResult)")
                    }
                }
            }
        }
        
        task.resume()
    }
    
    static internal func getImagesByGeo(methodArguments: [String : AnyObject], pageNumber: Int, view: UIViewController) {
        
        dispatch_async(dispatch_get_main_queue()){
            (view as? PinImagesViewController)!.networkActivityStart()
        }
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                
                println("Could not complete the request \(error)")
                
                dispatch_async(dispatch_get_main_queue()){
                    (view as? PinImagesViewController)!.networkActivityError("\(error)")
                }
                
            } else {

                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    if let photos = photosDictionary["photo"] as? NSArray{
                        
                        dispatch_async(dispatch_get_main_queue()){
                            (view as? PinImagesViewController)!.networkActivityGotResponse(photos)
                        }
                    }
                    
                } else {
                    
                    println("Cant find key 'photos' in \(parsedResult)")
                    
                    dispatch_async(dispatch_get_main_queue()){
                        (view as? PinImagesViewController)!.networkActivityError("Cant find key 'photos' in \(parsedResult)")
                    }
                    
                }
            }
        }
        
        task.resume()
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
}