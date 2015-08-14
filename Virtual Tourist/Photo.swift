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
    }
    
    @NSManaged var path:String?
    @NSManaged var pin:Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(_path: String, context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        path = _path
    }
}
