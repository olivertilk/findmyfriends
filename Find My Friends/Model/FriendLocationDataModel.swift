//
//  FriendLocationDataModel.swift
//  FirstTest
//
//  Created by Oliver Tilk on 7/6/19.
//  Copyright © 2019 Oliver Tilk. All rights reserved.
//

import UIKit
import MapKit

struct Friend: Codable {
    let lastname: String
    var location: FriendLocation
    let firstname: String
}

struct FriendLocation: Codable {
    let city: String
    let state: String
    let lat: Float
    let long: Float
}

class FriendLocationDataModel {
    
    var dataDictionary: [String : Friend] = [:]
    var annotationDictionary: [String : MKPointAnnotation] = [:]
    var nameArray = [String]()
    
    func updateData(data: [Friend]) {
        
        for friend in data {
            let fullName = friend.firstname + " " + friend.lastname
            
            if dataDictionary[fullName] == nil {
                nameArray.append(fullName)
            }

            dataDictionary.updateValue(friend, forKey: fullName)
        }
    }
    
    func updateAnnotation(newAnnotation: MKPointAnnotation, fullName: String) {
        annotationDictionary.updateValue(newAnnotation, forKey: fullName)
    }
    
    func friendExists(fullName: String) -> Bool {
        if dataDictionary[fullName] != nil {
            return true
        } else {
            return false
        }
    }
    
    func getFriend(fullName: String) -> Friend {
        return dataDictionary[fullName]!
    }
    
    func friendAnnotationExists(fullName: String) -> Bool {
        if annotationDictionary[fullName] != nil {
            return true
        } else {
            return false
        }
    }
    
    func getFriendAnnotation(fullName: String) -> MKPointAnnotation {
        return annotationDictionary[fullName]!
    }
    
    func getLength() -> Int {
        return nameArray.count
    }
}



