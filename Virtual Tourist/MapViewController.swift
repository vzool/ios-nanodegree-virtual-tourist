//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Abdelaziz Elrashed on 8/10/15.
//  Copyright (c) 2015 Abdelaziz Elrashed. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var lpgr: UILongPressGestureRecognizer!
    
    var selected_pin:Pin!
    var selected_annotation:MapPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        restoreMapRegion(false)
        
        lpgr = UILongPressGestureRecognizer(target: self, action: "gestureHandler:")
        lpgr.minimumPressDuration = 1.0
        
        mapView.addGestureRecognizer(lpgr)
        
        fetchedResultsController.delegate = self

        fetchedResultsController.performFetch(nil)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Stop, target: self, action: "exitApp")
        navigationItem.title = "Virtual Tourist Map"
        
        showIndicator(true)
        
        loadPins()
    }
    
    func exitApp(){
        exit(0)
    }
    
    var long_pressed_once = false
    
    func gestureHandler(gestureRecognizer:UIGestureRecognizer){
        
        if !long_pressed_once{
            
            let touchPoint = gestureRecognizer.locationInView(mapView)
            
            var newCoord:CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            println("\(newCoord.latitude), \(newCoord.longitude)")
            
            let dict = [
                Pin.Keys.LAT: "\(newCoord.latitude)",
                Pin.Keys.LON: "\(newCoord.longitude)"
            ]
            
            let pin = Pin(dict: dict, context: sharedContext)
            pin.current_page = 1
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "bbox": Flickr.createBoundingBoxString(newCoord.latitude, longitude: newCoord.longitude),
                "safe_search": SAFE_SEARCH,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK,
                "per_page": "\(Flickr.ImagesPerPage)"
            ]
            
            Flickr.getImagesTotalPageFromFlickr(methodArguments, view: self)
            
            selected_pin = pin
            
            var newAnotation = MapPoint()
            newAnotation.pin = pin
            newAnotation.coordinate = newCoord
            selected_annotation = newAnotation
        }
        
        long_pressed_once = !long_pressed_once
    }
    
    func networkActivitySaveTotalPages(count:Int, totalImages: Int){
        
        selected_pin.total_page_count = count
        selected_pin.total_images = totalImages
        CoreDataStackManager.sharedInstance().saveContext()
        showIndicator(false)
        
        var word = "image"
        word += totalImages > 1 ? "s" : ""
        
        if totalImages <= 0{
            word = "No \(word)s"
        }else{
            word = "\(totalImages) \(word)"
        }
        
        selected_annotation.title = word
        
        mapView.addAnnotation(selected_annotation)
        
        performSegueWithIdentifier("show_images", sender: self)
    }
    
    func showIndicator(state:Bool){
        
        indicator.hidden = !state
        navigationItem.leftBarButtonItem?.enabled = !state
        lpgr.enabled = !state
        
        if state{
            indicator.startAnimating()
        }else{
            indicator.stopAnimating()
        }
    }
    
    func networkActivityStart(){
        showIndicator(true)
    }
    
    func networkActivityError(error:NSError){
        
        var alert = UIAlertController(title: "Alert", message: "\(error)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        showIndicator(false)
    }
    
    func networkActivityEnd(){
        showIndicator(false)
    }
    
    /*=========================================================================*/
    /*============================= MapView ===================================*/
    /*=========================================================================*/
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .Red
            pinView!.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
            
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView!) {
        showIndicator(false)
    }
    
    func mapView(mapView: MKMapView!, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == annotationView.rightCalloutAccessoryView {
            if let pin = annotationView.annotation as? MapPoint{
                println("\(pin.pin.lat), \(pin.pin.lon)")
                
                selected_pin = pin.pin

                var saved_correctly = true
                for photo in pin.pin.photos{
                    saved_correctly = saved_correctly && photo.is_saved
                }
                
                if saved_correctly{
                    pin.pin.is_images_saved = saved_correctly
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                
                performSegueWithIdentifier("show_images", sender: self)
            }
        }
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "show_images"{
            let vc = segue.destinationViewController as! PinImagesViewController
            vc.pin = selected_pin
        }
    }
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            println("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    /*==========================================================================*/
    /*============================= CoreData ===================================*/
    /*==========================================================================*/
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Pin.Keys.CreatedDate, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    func loadPins(){
        
        mapView.removeAnnotations(mapView.annotations)
        
        if let info = fetchedResultsController.sections![0] as? NSFetchedResultsSectionInfo{
            
            var annotations = [MKPointAnnotation]()
            
            for(var i = 0; i < info.numberOfObjects; i++){
                
                let pin = fetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! Pin
                
                let lat = CLLocationDegrees(pin.lat.toDouble()!)
                let long = CLLocationDegrees(pin.lon.toDouble()!)
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                var annotation = MapPoint()
                annotation.coordinate = coordinate
                
                let image_count = pin.total_images.integerValue
                
                var word = "image"
                word += image_count > 1 ? "s" : ""
                
                if image_count <= 0{
                    word = "No \(word)s"
                }else{
                    word = "\(image_count) \(word)"
                }
                
                annotation.title = word
                
                annotation.pin = pin

                annotations.append(annotation)
            }
            
            mapView.addAnnotations(annotations)
        }
    }
}

