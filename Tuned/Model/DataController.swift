//
//  DataController.swift
//  Tuned
//
//  Created by Ravikiran Pathade on 4/2/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import Foundation
import CoreData

class DataController{
    let persistentContainer: NSPersistentContainer
    
    var viewContext:NSManagedObjectContext{
        return persistentContainer.viewContext
    }
    
    init(modelName:String){
        persistentContainer = NSPersistentContainer(name:modelName)
    }
    
    func load(completion:(()-> Void)? = nil){
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else{
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
}
