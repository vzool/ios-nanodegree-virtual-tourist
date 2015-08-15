//
//  DFM.swift
//  Virtual Tourist
//
//  Created by Abdelaziz Elrashed on 8/15/15.
//  Copyright (c) 2015 Abdelaziz Elrashed. All rights reserved.
//

/*=================================================================================================*/
/*===================================== Document File Managment ===================================*/
/*=================================================================================================*/

import Foundation
import UIKit

class DFM{
    
    static internal func saveImageToDocument(image: UIImage, fileName: String) -> String{
        
        let fileManager = NSFileManager.defaultManager()
        
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        
        var filePathToWrite = "\(paths)/\(fileName)"
        
        var imageData: NSData = UIImageJPEGRepresentation(image, 1.0)
        
        fileManager.createFileAtPath(filePathToWrite, contents: imageData, attributes: nil)
        
        var getImagePath = paths.stringByAppendingPathComponent(fileName)
        
        return getImagePath
    }
    
    static internal func loadImageFromDocument(imagePath: String) -> UIImage? {
        
        if file_exists(imagePath){
            return UIImage(contentsOfFile: imagePath)!
        }else{
            return nil
        }
    }
    
    static internal func deleteImageFromDocument(imagePath: String){
        
        let fileManager = NSFileManager.defaultManager()
        
        if (fileManager.fileExistsAtPath(imagePath)){
            
            var error:NSError?
            fileManager.removeItemAtPath(imagePath, error: &error)
            
            if let error = error{
                println("Delete Error: \(error)")
            }
        }
    }
    
    static internal func file_exists(imagePath: String) -> Bool{
        let fileManager = NSFileManager.defaultManager()
        return fileManager.fileExistsAtPath(imagePath)
    }
}
