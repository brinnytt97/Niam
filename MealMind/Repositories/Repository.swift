import Foundation
import SwiftData

/// Generic repository protocol for data access abstraction.
/// When migrating to a cloud backend, implement a new conforming type
/// without changing any View or ViewModel code.
protocol Repository<T> {
    associatedtype T: PersistentModel

    func fetchAll() throws -> [T]
    func fetch(_ predicate: Predicate<T>?, sortBy: [SortDescriptor<T>]) throws -> [T]
    func add(_ item: T) throws
    func delete(_ item: T) throws
    func save() throws
}

/// Default SwiftData implementation
final class SwiftDataRepository<T: PersistentModel>: Repository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try context.fetch(descriptor)
    }

    func fetch(_ predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) throws -> [T] {
        var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        descriptor.fetchLimit = nil
        return try context.fetch(descriptor)
    }

    func add(_ item: T) throws {
        context.insert(item)
        try save()
    }

    func delete(_ item: T) throws {
        context.delete(item)
        try save()
    }

    func save() throws {
        try context.save()
    }
}
