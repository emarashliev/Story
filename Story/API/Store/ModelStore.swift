
import Foundation

protocol ModelStore {
    associatedtype Model: Identifiable

    func fetchByID(_ id: Model.ID) -> Model?
}

struct AnyModelStore<Model>: ModelStore where Model: Identifiable {
    
    private var models = [Model.ID: Model]()
    
    var count: Int {
        get { models.count }
    }
    
    init(_ models: [Model]) {
        self.models = models.groupingByUniqueID()
    }
    
    func fetchByID(_ id: Model.ID) -> Model? {
        models[id]
    }
    
    func first() -> Model? {
        models.first?.value
    }
    
    mutating func append(models: [Model]) {
        self.models.merge(models.groupingByUniqueID()) { old, _ in old }
    }
}
    
extension Sequence where Element: Identifiable {
    func groupingByUniqueID() -> [Element.ID: Element] {
        Dictionary(uniqueKeysWithValues: map { ($0.id, $0) })
    }
}
