//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Abdelaziz Elrashed on 8/10/15.
//  Copyright (c) 2015 Abdelaziz Elrashed. All rights reserved.
//

import CoreData

@objc(Photo)

class Photo : NSManagedObject{
    
    struct Keys{
        static let ID = "id"
        static let PATH = "path"
    }
    
    @NSManaged var id: NSNumber
    @NSManaged var path:String?
    @NSManaged var pin:Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dict: [String: AnyObject], context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        id = dict[Keys.ID] as! NSNumber
        path = dict[Keys.PATH] as? String
        
    }
    
}
