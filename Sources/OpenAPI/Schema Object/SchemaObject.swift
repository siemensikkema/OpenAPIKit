//
//  SchemaObject.swift
//  OpenAPI
//
//  Created by Mathew Polzin on 6/22/19.
//

import Foundation
import AnyCodable

public protocol JSONSchemaObjectContext {
    var required: Bool { get }
}

public enum JSONSchemaObject: Equatable {
    case boolean(Context<JSONTypeFormat.BooleanFormat>)
    indirect case object(Context<JSONTypeFormat.ObjectFormat>, ObjectContext)
    indirect case array(Context<JSONTypeFormat.ArrayFormat>, ArrayContext)
    case number(Context<JSONTypeFormat.NumberFormat>, NumericContext)
    case integer(Context<JSONTypeFormat.IntegerFormat>, NumericContext)
    case string(Context<JSONTypeFormat.StringFormat>, StringContext)
    indirect case all(of: [JSONSchemaObject])
    indirect case one(of: [JSONSchemaObject])
    indirect case any(of: [JSONSchemaObject])
    indirect case not(JSONSchemaObject)
    case reference(JSONReference<OpenAPIComponents, JSONSchemaObject>)

    public var jsonTypeFormat: JSONTypeFormat? {
        switch self {
        case .boolean(let context):
            return .boolean(context.format)
        case .object(let context, _):
            return .object(context.format)
        case .array(let context, _):
            return .array(context.format)
        case .number(let context, _):
            return .number(context.format)
        case .integer(let context, _):
            return .integer(context.format)
        case .string(let context, _):
            return .string(context.format)
        case .all, .one, .any, .not, .reference:
            return nil
        }
    }

    public var required: Bool {
        switch self {
        case .boolean(let context as JSONSchemaObjectContext),
             .object(let context as JSONSchemaObjectContext, _),
             .array(let context as JSONSchemaObjectContext, _),
             .number(let context as JSONSchemaObjectContext, _),
             .integer(let context as JSONSchemaObjectContext, _),
             .string(let context as JSONSchemaObjectContext, _):
            return context.required
        case .all, .one, .any, .not, .reference:
            return true
        }
    }
}

// MARK: - Transformations
extension JSONSchemaObject {
    /// Return the optional version of this `JSONSchemaObject`
    public func optionalSchemaObject() -> JSONSchemaObject {
        switch self {
        case .boolean(let context):
            return .boolean(context.optionalContext())
        case .object(let contextA, let contextB):
            return .object(contextA.optionalContext(), contextB)
        case .array(let contextA, let contextB):
            return .array(contextA.optionalContext(), contextB)
        case .number(let context, let contextB):
            return .number(context.optionalContext(), contextB)
        case .integer(let context, let contextB):
            return .integer(context.optionalContext(), contextB)
        case .string(let context, let contextB):
            return .string(context.optionalContext(), contextB)
        case .all, .one, .any, .not, .reference:
            return self
        }
    }

    /// Return the required version of this `JSONSchemaObject`
    public func requiredSchemaObject() -> JSONSchemaObject {
        switch self {
        case .boolean(let context):
            return .boolean(context.requiredContext())
        case .object(let contextA, let contextB):
            return .object(contextA.requiredContext(), contextB)
        case .array(let contextA, let contextB):
            return .array(contextA.requiredContext(), contextB)
        case .number(let context, let contextB):
            return .number(context.requiredContext(), contextB)
        case .integer(let context, let contextB):
            return .integer(context.requiredContext(), contextB)
        case .string(let context, let contextB):
            return .string(context.requiredContext(), contextB)
        case .all, .one, .any, .not, .reference:
            return self
        }
    }

    /// Return the nullable version of this `JSONSchemaObject`
    public func nullableSchemaObject() -> JSONSchemaObject {
        switch self {
        case .boolean(let context):
            return .boolean(context.nullableContext())
        case .object(let contextA, let contextB):
            return .object(contextA.nullableContext(), contextB)
        case .array(let contextA, let contextB):
            return .array(contextA.nullableContext(), contextB)
        case .number(let context, let contextB):
            return .number(context.nullableContext(), contextB)
        case .integer(let context, let contextB):
            return .integer(context.nullableContext(), contextB)
        case .string(let context, let contextB):
            return .string(context.nullableContext(), contextB)
        case .all, .one, .any, .not, .reference:
            return self
        }
    }

    /// Return a version of this `JSONSchemaObject` that only allows the given
    /// values.
    public func with(allowedValues: [AnyCodable]) throws -> JSONSchemaObject {

        switch self {
        case .boolean(let context):
            return .boolean(context.with(allowedValues: allowedValues))
        case .object(let contextA, let contextB):
            return .object(contextA.with(allowedValues: allowedValues), contextB)
        case .array(let contextA, let contextB):
            return .array(contextA.with(allowedValues: allowedValues), contextB)
        case .number(let context, let contextB):
            return .number(context.with(allowedValues: allowedValues), contextB)
        case .integer(let context, let contextB):
            return .integer(context.with(allowedValues: allowedValues), contextB)
        case .string(let context, let contextB):
            return .string(context.with(allowedValues: allowedValues), contextB)
        case .all, .one, .any, .not, .reference:
            return self
        }
    }

    public func with<T: Encodable>(example codableExample: T,
                                   using encoder: JSONEncoder) throws -> JSONSchemaObject {
        let example: AnyCodable
        if let goodToGo = codableExample as? AnyCodable {
            example = goodToGo
        } else {
            example = AnyCodable(try JSONSerialization.jsonObject(with: encoder.encode(codableExample), options: []))
        }

        switch self {
        case .boolean(let context):
            return .boolean(context.with(example: example, using: encoder))
        case .object(let contextA, let contextB):
            return .object(contextA.with(example: example, using: encoder), contextB)
        case .array(let contextA, let contextB):
            return .array(contextA.with(example: example, using: encoder), contextB)
        case .number(let context, let contextB):
            return .number(context.with(example: example, using: encoder), contextB)
        case .integer(let context, let contextB):
            return .integer(context.with(example: example, using: encoder), contextB)
        case .string(let context, let contextB):
            return .string(context.with(example: example, using: encoder), contextB)
        case .all, .one, .any, .not, .reference:
            return self
        }
    }
}

// MARK: - Codable

extension JSONSchemaObject: Encodable {

    private enum SubschemaCodingKeys: String, CodingKey {
        case allOf
        case oneOf
        case anyOf
        case not
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .boolean(let context):
            try context.encode(to: encoder)

        case .object(let contextA as Encodable, let contextB as Encodable),
             .array(let contextA as Encodable, let contextB as Encodable),
             .number(let contextA as Encodable, let contextB as Encodable),
             .integer(let contextA as Encodable, let contextB as Encodable),
             .string(let contextA as Encodable, let contextB as Encodable):
            try contextA.encode(to: encoder)
            try contextB.encode(to: encoder)

        case .all(of: let nodes):
            var container = encoder.container(keyedBy: SubschemaCodingKeys.self)

            try container.encode(nodes, forKey: .allOf)

        case .one(of: let nodes):
            var container = encoder.container(keyedBy: SubschemaCodingKeys.self)

            try container.encode(nodes, forKey: .oneOf)

        case .any(of: let nodes):
            var container = encoder.container(keyedBy: SubschemaCodingKeys.self)

            try container.encode(nodes, forKey: .anyOf)

        case .not(let node):
            var container = encoder.container(keyedBy: SubschemaCodingKeys.self)

            try container.encode(node, forKey: .not)

        case .reference(let reference):
            var container = encoder.singleValueContainer()

            try container.encode(reference)
        }
    }
}
