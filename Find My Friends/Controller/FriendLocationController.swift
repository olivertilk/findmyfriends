//
//  FriendLocationController.swift
//  FirstTest
//
//  Created by Oliver Tilk on 7/8/19.
//  Copyright © 2019 Oliver Tilk. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SystemConfiguration

class FriendLocationController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var meView: UIView!
    @IBOutlet var addBarButton: UIBarButtonItem!
    @IBOutlet var editBarButton: UIBarButtonItem!
    @IBOutlet weak var mapHeight: NSLayoutConstraint!

    private let locationManager: CLLocationManager = CLLocationManager()
    private let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com")
    
    let apiURL = "https://join.develop.humanics.com/RnJpZW5kTG9jYXRpb246dlRzTm40eU1lb3RvcmU5WURyTXQ4eUc4d2FxNnByOGI="
    
    let session = URLSession.shared
    
    let friendLocationDataModel = FriendLocationDataModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFriendLocationData()
        addUserLocation()
        setUpUserInterface()
        
        _ = Timer.scheduledTimer(timeInterval: 5,
                                 target: self,
                                 selector: #selector(getFriendLocationData),
                                 userInfo: nil,
                                 repeats: true)
    }
    
    
    // MARK: - API calls
    
    @objc func getFriendLocationData() {
        if networkIsReachable() {
            let url = URL(string: apiURL)!
            let task = session.dataTask(with: url, completionHandler: { dataOptional, response, error in
                do {
                    guard let data = dataOptional else {
                        return
                    }
                    
                    let newData = try JSONDecoder().decode([Friend].self, from: data)
                    
                    DispatchQueue.main.async {
                        self.friendLocationDataModel.updateData(data: newData)
                        self.updateAnnotations(newData: newData)
                        self.tableView.reloadData()
                    }
                } catch {
                    print("JSON error: \(error)")
                }
            })
            task.resume()
        } else {
            print("Network not reachable")
        }
    }
    
    func networkIsReachable() -> Bool {
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(self.reachability!, &flags)
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
    
    
    // MARK: - Navigation
    
    @IBAction func mapSingleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            showMapOnEntireScreen()
        }
    }
    
    @objc func showMapOnEntireScreen() {
        tableView.isHidden = true
        mapHeight.constant = 750
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItem = nil
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(showFriends))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func showFriends() {
        tableView.isHidden = false
        mapHeight.constant = 280
        navigationItem.rightBarButtonItem = addBarButton
        navigationItem.leftBarButtonItem = editBarButton
    }
    
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    @IBAction func unwindWithSegue(_ segue: UIStoryboardSegue) {
        
    }
    
    
    // MARK: - User interface
    
    func setUpUserInterface() {
        meView.layer.borderWidth = 0.25
        meView.layer.borderColor = UIColor.gray.cgColor
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        mapView.isUserInteractionEnabled = true
    }
    
    
    // MARK: - Map
    
    func setMapRegion(lat: Float, long: Float) {
        let location = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(long))
        let region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
    
    func updateAnnotations(newData: [Friend]) {
        for friend in newData {
            //Remove old map annotation if it exists
            let fullName = friend.firstname + " " + friend.lastname
            if self.friendLocationDataModel.friendAnnotationExists(fullName: fullName) {
                let oldFriendAnnotation = self.friendLocationDataModel.getFriendAnnotation(fullName: fullName)
                self.mapView.removeAnnotation(oldFriendAnnotation)
            }
            
            //Add new map annotation
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(friend.location.lat), longitude: CLLocationDegrees(friend.location.long))
            let friendLocationAnnotation = MKPointAnnotation()
            friendLocationAnnotation.title = String(friend.firstname.prefix(1)) + String(friend.lastname.prefix(1))
            friendLocationAnnotation.coordinate = coordinate
            self.friendLocationDataModel.updateAnnotation(newAnnotation: friendLocationAnnotation, fullName: fullName)
            self.mapView.addAnnotation(friendLocationAnnotation)
        }
    }
    
    func addUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
    }
    
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendLocationDataModel.getLength()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendLocationCell", for: indexPath) as! FriendLocationCell
        
        //Display the friend's name
        let fullName = friendLocationDataModel.nameArray[indexPath.row]
        cell.nameLabel.text = fullName
        
        if friendLocationDataModel.friendExists(fullName: fullName) {
            let friend = friendLocationDataModel.getFriend(fullName: fullName)
            
            //Display the friend's city
            cell.cityLabel.text = friend.location.city + ", " + friend.location.state
            
            //If user location is available, update the friend's distance to you
            if let userLocation = locationManager.location {
                let friendLat = friend.location.lat
                let friendLong = friend.location.long
                let friendLocation = CLLocation(latitude: CLLocationDegrees(friendLat), longitude: CLLocationDegrees(friendLong))
                
                let friendDistance = userLocation.distance(from: friendLocation)
                let friendDistanceMiles = Int(round(friendDistance / 1000 / 1.609))
                
                cell.distanceLabel.text = String(friendDistanceMiles) + " mi"
            }
        }
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let fullName = friendLocationDataModel.nameArray[indexPath.row]
        if friendLocationDataModel.friendExists(fullName: fullName) {
            let friend = friendLocationDataModel.getFriend(fullName: fullName)            
            let lat = friend.location.lat
            let long = friend.location.long
            setMapRegion(lat: lat, long: long)
        }
    }
}
