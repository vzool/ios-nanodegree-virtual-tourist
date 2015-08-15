//
//  PinImagesViewController.swift
//  Virtual Tourist
//
//  Created by Abdelaziz Elrashed on 8/12/15.
//  Copyright (c) 2015 Abdelaziz Elrashed. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PinImagesViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate{
    
    var pin:Pin!
    let searchRadius: CLLocationDistance = 2000
    
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationItem.title = "Loading..."
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.setRegion(MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: pin.lat.toDouble()!, longitude: pin.lon.toDouble()!), searchRadius * 10.0, searchRadius * 10.0), animated: true)
        
        addPinToMapView(pin)
        
        if pin.current_page == 1{
            
            if !pin.is_images_saved{
                
                newCollection()
                
            }else{
                
                navigationItem.title = "Page: \(pin.current_page.integerValue) / \(pin.total_page_count.integerValue)"
            }
            
        }else{
            navigationItem.title = "Page: \(pin.current_page.integerValue) / \(pin.total_page_count.integerValue)"
        }
    }
    
    func addPinToMapView(pin:Pin) {

        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.lat.toDouble()!, longitude: pin.lon.toDouble()!)
        
        mapView.addAnnotation(annotation)
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ImageCollectionCell
        
        let photo = pin.photos[indexPath.item]
        
        if photo.path != nil{
            
            println("# READ IMAGE FROM CACHE #")
            
            cell.imageView.image = DFM.loadImageFromDocument(photo.path!)
            
        }else{
            
            println("# DOWNLOAD IMAGE FROM WWW #")
            
            getDataFromUrl(NSURL(string: photo.url!)!) { data in
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    if let data = data {
                        
                        var imageUrl = NSURL(fileURLWithPath: photo.url!)
                        var fileName = imageUrl?.lastPathComponent
                        
                        let image = UIImage(data: data)
                        
                        let imagePath = DFM.saveImageToDocument(image!, fileName: fileName!)
                        photo.path = imagePath
                        
                        cell.imageView.image = image
                        
                        photo.is_saved = true
                        
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                    }else{
                        
                        self.sharedContext.deleteObject(photo)
                    }
                }
            }
        }
        
        cell.indicator.stopAnimating()
        cell.indicator.hidden = true

        return cell
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ImageCollectionCell
        cell.indicator.startAnimating()
        cell.indicator.hidden = false
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let photo = pin.photos[indexPath.item]
        
        var alert = UIAlertController(title: "Alert", message: "Do you want to delete this image?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { action in
            switch action.style{
            case .Default:
                
                DFM.deleteImageFromDocument(photo.path!)
                
                self.sharedContext.deleteObject(photo)
                
                CoreDataStackManager.sharedInstance().saveContext()
                
                self.collectionView.reloadData()
                
            case .Cancel:
                return
                
            case .Destructive:
                return
            }
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func getDataFromUrl(urL:NSURL, completion: ((data: NSData?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(urL) { (data, response, error) in
            completion(data: data)
        }.resume()
    }
    
    func newCollection(){
        
        for photo in pin.photos{
            if photo.path != nil{
                DFM.deleteImageFromDocument(photo.path!)
            }
            
            sharedContext.deleteObject(photo)
        }
        
        if pin.total_page_count.integerValue == 0{
            navigationItem.title = "No Images"
        }else{
            navigationItem.title = "Page: \(pin.current_page.integerValue) / \(pin.total_page_count.integerValue)"
        }
        
        if(pin.current_page.integerValue < pin.total_page_count.integerValue){
            
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "bbox": Flickr.createBoundingBoxString(pin.lat.toDouble()!, longitude: pin.lon.toDouble()!),
                "safe_search": SAFE_SEARCH,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK,
                "per_page": "\(Flickr.ImagesPerPage)"
            ]
            
            Flickr.getImagesByGeo(methodArguments, pageNumber: pin.current_page.integerValue, view: self)
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            collectionView.reloadData()
        }
    }
    
    @IBAction func requestNewCollection(sender: AnyObject) {
        
        if(pin.current_page.integerValue < pin.total_page_count.integerValue){
            pin.current_page = NSNumber(integer: pin.current_page.integerValue + 1)
            CoreDataStackManager.sharedInstance().saveContext()
        }else if pin.current_page.integerValue == pin.total_page_count.integerValue{
            pin.current_page = NSNumber(integer: 1)
            CoreDataStackManager.sharedInstance().saveContext()
        }
        newCollection()
    }
    
    func networkActivityGotResponse(photos:NSArray){
        
        for photo in photos{
            
            if let url_m = photo["url_m"] as? String{
                
                var p = Photo(_url: url_m, context: sharedContext)
                p.pin = pin
                
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
        
        var word = "image"
        word += photos.count > 1 ? "s" : ""
        
        if photos.count <= 0{
            word = "No \(word)s"
        }else{
            word = "\(photos.count) \(word)"
        }
        
        collectionView.reloadData()
        
        if pin.total_page_count.integerValue == 0{
            navigationItem.title = "No Images"
        }else{
            navigationItem.title = "Page: \(pin.current_page.integerValue) / \(pin.total_page_count.integerValue)"
        }
        
        newCollectionButton.enabled = true
    }
    
    func networkActivityStart(){
        newCollectionButton.enabled = false
        navigationItem.title = "Loading..."
    }
    
    func networkActivityError(error:String){
        
        var alert = UIAlertController(title: "Alert", message: error, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
