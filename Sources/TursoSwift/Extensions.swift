//
//  File.swift
//  
//
//  Created by Matt Linder on 8/3/24.
//

import Foundation

extension Dictionary where Value: Equatable {
    func key(forValue value: Value) -> Key? {
        return first { $0.1 == value }?.0
    }
}

func getPropertyNames<T>(of instance: T) -> [String] {
    return Mirror(reflecting: instance).children.compactMap { $0.label }
}

protocol AnyArray {}

extension Array: AnyArray {}

extension NSArray: AnyArray {}

func isArray<T>(_ type: T.Type) -> Bool {
    return type.self is AnyArray.Type
}