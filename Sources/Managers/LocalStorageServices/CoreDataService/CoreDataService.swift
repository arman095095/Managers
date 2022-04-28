//
//  CoreDataService.swift
//
//
//  Created by Арман Чархчян on 25.04.2022.
//

import CoreData

public protocol CoreDataServiceProtocol {
    @discardableResult
    func initModel<T: NSManagedObject>(_ type: T.Type,
                                       initHandler: (T) -> Void) -> T
    
    @discardableResult
    func update<T: NSManagedObject>(_ model: T,
                                    editHandler: (T) -> Void) -> T
    
    func removeAll<T: NSManagedObject>(_ type: T.Type)
    
    func models<T: NSManagedObject>(_ type: T.Type,
                                    keySort: String?,
                                    ascending: Bool?) -> [T]
    
    func model<T: NSManagedObject>(_ type: T.Type,
                                   id: String) -> T?
    
    func model<T: NSManagedObject>(_ type: T.Type,
                                   predicate: NSPredicate) -> T?
    
    func remove<T: NSManagedObject>(_ model: T)
}

public final class CoreDataService {
    
    public enum Info {
        case project(fileName: String)
        case package(fileName: String, fileExtension: String = ".momd")
    }
    
    private let info: Info
    
    public init(info: Info) {
        self.info = info
    }
    
    public lazy var persistentContainer: NSPersistentContainer = {
        var container: NSPersistentContainer
        switch info {
        case .project(let fileName):
            container = NSPersistentContainer(name: fileName)
        case .package(let fileName, let fileExtension):
            guard let modelURL = Bundle.module.url(forResource: fileName,
                                                   withExtension: fileExtension) else {
                fatalError(Error.fileNotFound.localizedDescription)
            }
            guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
                fatalError(Error.objectModelNotInitiated.localizedDescription)
            }
            container = NSPersistentContainer(name: fileName, managedObjectModel: model)
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
        })
        return container
    }()
}

extension CoreDataService: CoreDataServiceProtocol {
    
    @discardableResult
    public func initModel<T: NSManagedObject>(_ type: T.Type,
                                              initHandler: (T) -> Void) -> T {
        guard let entity = NSEntityDescription.entity(forEntityName: String(describing: type.self),
                                                      in: context) else {
            fatalError(Error.entityNotFound.localizedDescription)
        }
        let model = T(entity: entity, insertInto: context)
        initHandler(model)
        saveContext()
        return model
    }
    
    @discardableResult
    public func update<T: NSManagedObject>(_ model: T,
                                           editHandler: (T) -> Void) -> T {
        editHandler(model)
        saveContext()
        return model
    }
    
    public func removeAll<T: NSManagedObject>(_ type: T.Type) {
        let objects = models(type)
        for object in objects {
            context.delete(object)
        }
        saveContext()
    }
    
    public func models<T: NSManagedObject>(_ type: T.Type,
                                           keySort: String? = nil,
                                           ascending: Bool? = nil) -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type.self))
        if let key = keySort, let ascending = ascending {
            let sortDescriptor = NSSortDescriptor(key: key, ascending: ascending)
            fetchRequest.sortDescriptors = [sortDescriptor] }
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    public func model<T: NSManagedObject>(_ type: T.Type,
                                          id: String) -> T? {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type.self))
        fetchRequest.predicate = NSPredicate(format: "SELF.id == %@", "\(id)")
        guard let results = try? context.fetch(fetchRequest) else { return nil }
        return results.first
    }
    
    public func model<T: NSManagedObject>(_ type: T.Type,
                                          predicate: NSPredicate) -> T? {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type.self))
        fetchRequest.predicate = predicate
        guard let results = try? context.fetch(fetchRequest) else { return nil }
        return results.first
    }
    
    public func remove<T: NSManagedObject>(_ model: T) {
        context.delete(model)
        saveContext()
    }
}

private extension CoreDataService {
    
    enum Error: LocalizedError {
        case fileNotFound
        case objectModelNotInitiated
        case entityNotFound
    }
    
    func saveContext() {
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
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
}

