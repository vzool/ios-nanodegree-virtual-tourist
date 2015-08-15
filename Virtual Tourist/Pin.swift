//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Abdelaziz Elrashed on 8/10/15.
//  Copyright (c) 2015 Abdelaziz Elrashed. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)

class Pin : NSManagedObject{
    
    struct Keys {
        static let LAT = "lat"
        static let LON = "lon"
        static let CreatedDate = "created_date"
        
        static let TotalPageCount = "total_page_count"
        static let CurrentPage = "current_page"
        static let TotalImages = "total_images"
        
        static let IsImagesSaved = "is_images_saved"
    }
    
    @NSManaged var lat: String
    @NSManaged var lon: String
    @NSManaged var created_date:NSDate?
    @NSManaged var photos:[Photo]
    
    @NSManaged var total_page_count:NSNumber
    @NSManaged var current_page:NSNumber
    @NSManaged var total_images:NSNumber
    
    @NSManaged var is_images_saved:Bool
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dict: [String: AnyObject], context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        lat = dict[Keys.LAT] as! String
        lon = dict[Keys.LON] as! String
        
        created_date = NSDate()
        
        is_images_saved = false
    }
}


