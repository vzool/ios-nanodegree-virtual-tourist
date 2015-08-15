//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Abdelaziz Elrashed on 8/10/15.
//  Copyright (c) 2015 Abdelaziz Elrashed. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)

class Photo : NSManagedObject{
    
    struct Keys{
        static let PATH = "path"
        static let IsSaved = "is_saved"
        static let URL = "url"
    }
    
    @NSManaged var path:String?
    @NSManaged var pin:Pin?
    
    @NSManaged var is_saved:Bool
    @NSManaged var url:String?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(_url: String, context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        url = _url
        
        is_saved = false
    }
}
