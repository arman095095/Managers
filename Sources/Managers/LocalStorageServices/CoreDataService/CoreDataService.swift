//
//  File.swift
//  
//
//  Created by Арман Чархчян on 25.04.2022.
//

import CoreData
import UIKit

public protocol CoreDataServiceProtocol {
    func create<T: NSManagedObject>(type: T.Type, completion: (T) -> Void)
    func removeObjects<T: NSManagedObject>(type: T.Type)
    func getObject<T: NSManagedObject>(type: T.Type, predicate: NSPredicate) -> T?
    func getObject<T: NSManagedObject>(type: T.Type, id: NSManagedObjectID) -> T?
    func getObjects<T: NSManagedObject>(type: T.Type,
                                        keySort: String?,
                                        ascending: Bool?) -> [T]
    func removeObject<T: NSManagedObject>(object: T)
    func saveContext()
}

public final class CoreDataService {
    
    private let fileName: String
    
    public init(fileName: String) {
        self.fileName = fileName
    }
    
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: fileName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    public func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

extension CoreDataService: CoreDataServiceProtocol {
    
    public func create<T: NSManagedObject>(type: T.Type, completion: (T) -> Void) {
        guard let entity = NSEntityDescription.entity(forEntityName: String(describing: type.self), in: context) else { return }
        let object = T(entity: entity, insertInto: context)
        completion(object)
        saveContext()
    }

    public func getObject<T: NSManagedObject>(type: T.Type, id: NSManagedObjectID) -> T? {
        let result = context.object(with: id)
        return result as? T
    }
    
    public func removeObjects<T: NSManagedObject>(type: T.Type) {
        let objects = getObjects(type: type)
        for object in objects {
            context.delete(object)
        }
        saveContext()
    }
    
    public func getObjects<T: NSManagedObject>(type: T.Type,
                                        keySort: String? = nil,
                                        ascending: Bool? = nil) -> [T] {
        let fetchRequest = type.fetchRequest()
        if let key = keySort, let ascending = ascending {
            let sortDescriptor = NSSortDescriptor(key: key, ascending: ascending)
            fetchRequest.sortDescriptors = [sortDescriptor] }
        return (try? context.fetch(fetchRequest) as? [T]) ?? []
    }
    
    public func getObject<T: NSManagedObject>(type: T.Type,
                                              predicate: NSPredicate) -> T? {
        let fetchRequest = type.fetchRequest()
        fetchRequest.predicate = predicate
        guard let results =  try? context.fetch(fetchRequest) as? [T] else { return nil }
        return results.first
    }
    
    public func removeObject<T: NSManagedObject>(object: T) {
        context.delete(object)
        saveContext()
    }
}
