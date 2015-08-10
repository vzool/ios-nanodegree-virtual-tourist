//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Abdelaziz Elrashed on 8/10/15.
//  Copyright (c) 2015 Abdelaziz Elrashed. All rights reserved.
//

import CoreData

@objc(Pin)

class Pin : NSManagedObject{
    
    struct Keys {
        static let ID = "id"
        static let X = "x"
        static let Y = "y"
        static let CreatedDate = "created_date"
    }
    
    @NSManaged var id: NSNumber
    @NSManaged var x: NSNumber
    @NSManaged var y: NSNumber
    @NSManaged var createdDate:NSDate?
    @NSManaged var photos:[Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dict: [String: AnyObject], context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        id = dict[Keys.ID] as! NSNumber
        x = dict[Keys.X] as! NSNumber
        y = dict[Keys.Y] as! NSNumber
        
        createdDate = NSDate()
    }
}
