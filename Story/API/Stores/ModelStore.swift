
import Foundation
import Combine

protocol ModelStore {
    associatedtype Model: Identifiable

    func fetchByID(_ id: Model.ID) -> Model?
}

struct AnyModelStore<Model>: ModelStore where Model: Identifiable, Model: Hashable {
    
    private var models = [Model.ID: Model]()
    
    var count: Int {
        get { models.count }
    }
    
    init(_ models: [Model]) {
        self.models = Set(models).groupingByUniqueID()
    }
    
    func fetchByID(_ id: Model.ID) -> Model? {
        models[id]
    }
    
    func first() -> Model? {
        models.first?.value
    }
    
    func allModels() -> [Model]{
        Array(models.values)
    }
}
    
extension Sequence where Element: Identifiable {
    func groupingByUniqueID() -> [Element.ID: Element] {
        return Dictionary(uniqueKeysWithValues: map { ($0.id, $0) })
    }
}
