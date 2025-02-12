//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import GRDBCipher
import SignalCoreKit

// NOTE: This file is generated by /Scripts/sds_codegen/sds_generate.py.
// Do not manually edit it, instead run `sds_codegen.sh`.

// MARK: - Record

public struct JobRecordRecord: Codable, FetchableRecord, PersistableRecord, TableRecord {
    public static let databaseTableName: String = SSKJobRecordSerializer.table.tableName

    public let id: UInt64

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    public let recordType: SDSRecordType
    public let uniqueId: String

    // Base class properties
    public let failureCount: UInt
    public let label: String
    public let status: SSKJobRecordStatus

    // Subclass properties
    public let contactThreadId: String?
    public let invisibleMessage: Data?
    public let messageId: String?
    public let removeMessageAfterSending: Bool?
    public let threadId: String?

    public enum CodingKeys: String, CodingKey, ColumnExpression, CaseIterable {
        case id
        case recordType
        case uniqueId
        case failureCount
        case label
        case status
        case contactThreadId
        case invisibleMessage
        case messageId
        case removeMessageAfterSending
        case threadId
    }

    public static func columnName(_ column: JobRecordRecord.CodingKeys, fullyQualified: Bool = false) -> String {
        return fullyQualified ? "\(databaseTableName).\(column.rawValue)" : column.rawValue
    }

}

// MARK: - StringInterpolation

public extension String.StringInterpolation {
    mutating func appendInterpolation(jobRecordColumn column: JobRecordRecord.CodingKeys) {
        appendLiteral(JobRecordRecord.columnName(column))
    }
    mutating func appendInterpolation(jobRecordColumnFullyQualified column: JobRecordRecord.CodingKeys) {
        appendLiteral(JobRecordRecord.columnName(column, fullyQualified: true))
    }
}

// MARK: - Deserialization

// TODO: Remove the other Deserialization extension.
// TODO: SDSDeserializer.
// TODO: Rework metadata to not include, for example, columns, column indices.
extension SSKJobRecord {
    // This method defines how to deserialize a model, given a
    // database row.  The recordType column is used to determine
    // the corresponding model class.
    class func fromRecord(_ record: JobRecordRecord) throws -> SSKJobRecord {

        switch record.recordType {
        case .sessionResetJobRecord:

            let uniqueId: String = record.uniqueId
            let failureCount: UInt = record.failureCount
            let label: String = record.label
            let sortId: UInt64 = record.id
            let status: SSKJobRecordStatus = record.status
            let contactThreadId: String = try SDSDeserialization.required(record.contactThreadId, name: "contactThreadId")

            return OWSSessionResetJobRecord(uniqueId: uniqueId,
                                            failureCount: failureCount,
                                            label: label,
                                            sortId: sortId,
                                            status: status,
                                            contactThreadId: contactThreadId)

        case .jobRecord:

            let uniqueId: String = record.uniqueId
            let failureCount: UInt = record.failureCount
            let label: String = record.label
            let sortId: UInt64 = record.id
            let status: SSKJobRecordStatus = record.status

            return SSKJobRecord(uniqueId: uniqueId,
                                failureCount: failureCount,
                                label: label,
                                sortId: sortId,
                                status: status)

        case .messageSenderJobRecord:

            let uniqueId: String = record.uniqueId
            let failureCount: UInt = record.failureCount
            let label: String = record.label
            let sortId: UInt64 = record.id
            let status: SSKJobRecordStatus = record.status
            let invisibleMessageSerialized: Data? = record.invisibleMessage
            let invisibleMessage: TSOutgoingMessage? = try SDSDeserialization.optionalUnarchive(invisibleMessageSerialized, name: "invisibleMessage")
            let messageId: String? = record.messageId
            let removeMessageAfterSending: Bool = try SDSDeserialization.required(record.removeMessageAfterSending, name: "removeMessageAfterSending")
            let threadId: String? = record.threadId

            return SSKMessageSenderJobRecord(uniqueId: uniqueId,
                                             failureCount: failureCount,
                                             label: label,
                                             sortId: sortId,
                                             status: status,
                                             invisibleMessage: invisibleMessage,
                                             messageId: messageId,
                                             removeMessageAfterSending: removeMessageAfterSending,
                                             threadId: threadId)

        default:
            owsFailDebug("Unexpected record type: \(record.recordType)")
            throw SDSError.invalidValue
        }
    }
}

// MARK: - SDSSerializable

extension SSKJobRecord: SDSSerializable {
    public var serializer: SDSSerializer {
        // Any subclass can be cast to it's superclass,
        // so the order of this switch statement matters.
        // We need to do a "depth first" search by type.
        switch self {
        case let model as SSKMessageSenderJobRecord:
            assert(type(of: model) == SSKMessageSenderJobRecord.self)
            return SSKMessageSenderJobRecordSerializer(model: model)
        case let model as OWSSessionResetJobRecord:
            assert(type(of: model) == OWSSessionResetJobRecord.self)
            return OWSSessionResetJobRecordSerializer(model: model)
        default:
            return SSKJobRecordSerializer(model: self)
        }
    }
}

// MARK: - Table Metadata

extension SSKJobRecordSerializer {

    // This defines all of the columns used in the table
    // where this model (and any subclasses) are persisted.
    static let recordTypeColumn = SDSColumnMetadata(columnName: "recordType", columnType: .int, columnIndex: 0)
    static let idColumn = SDSColumnMetadata(columnName: "id", columnType: .primaryKey, columnIndex: 1)
    static let uniqueIdColumn = SDSColumnMetadata(columnName: "uniqueId", columnType: .unicodeString, columnIndex: 2)
    // Base class properties
    static let failureCountColumn = SDSColumnMetadata(columnName: "failureCount", columnType: .int64, columnIndex: 3)
    static let labelColumn = SDSColumnMetadata(columnName: "label", columnType: .unicodeString, columnIndex: 4)
    static let statusColumn = SDSColumnMetadata(columnName: "status", columnType: .int, columnIndex: 5)
    // Subclass properties
    static let contactThreadIdColumn = SDSColumnMetadata(columnName: "contactThreadId", columnType: .unicodeString, isOptional: true, columnIndex: 6)
    static let invisibleMessageColumn = SDSColumnMetadata(columnName: "invisibleMessage", columnType: .blob, isOptional: true, columnIndex: 7)
    static let messageIdColumn = SDSColumnMetadata(columnName: "messageId", columnType: .unicodeString, isOptional: true, columnIndex: 8)
    static let removeMessageAfterSendingColumn = SDSColumnMetadata(columnName: "removeMessageAfterSending", columnType: .int, isOptional: true, columnIndex: 9)
    static let threadIdColumn = SDSColumnMetadata(columnName: "threadId", columnType: .unicodeString, isOptional: true, columnIndex: 10)

    // TODO: We should decide on a naming convention for
    //       tables that store models.
    public static let table = SDSTableMetadata(tableName: "model_SSKJobRecord", columns: [
        recordTypeColumn,
        idColumn,
        uniqueIdColumn,
        failureCountColumn,
        labelColumn,
        statusColumn,
        contactThreadIdColumn,
        invisibleMessageColumn,
        messageIdColumn,
        removeMessageAfterSendingColumn,
        threadIdColumn
        ])

}

// MARK: - Deserialization

extension SSKJobRecordSerializer {
    // This method defines how to deserialize a model, given a
    // database row.  The recordType column is used to determine
    // the corresponding model class.
    class func sdsDeserialize(statement: SelectStatement) throws -> SSKJobRecord {

        if OWSIsDebugBuild() {
            guard statement.columnNames == table.selectColumnNames else {
                owsFailDebug("Unexpected columns: \(statement.columnNames) != \(table.selectColumnNames)")
                throw SDSError.invalidResult
            }
        }

        // SDSDeserializer is used to convert column values into Swift values.
        let deserializer = SDSDeserializer(sqliteStatement: statement.sqliteStatement)
        let recordTypeValue = try deserializer.int(at: 0)
        guard let recordType = SDSRecordType(rawValue: UInt(recordTypeValue)) else {
            owsFailDebug("Invalid recordType: \(recordTypeValue)")
            throw SDSError.invalidResult
        }
        switch recordType {
        case .sessionResetJobRecord:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)
            let failureCount = UInt(try deserializer.int64(at: failureCountColumn.columnIndex))
            let label = try deserializer.string(at: labelColumn.columnIndex)
            let sortId = try deserializer.uint64(at: idColumn.columnIndex)
            let statusRaw = UInt(try deserializer.int(at: statusColumn.columnIndex))
            guard let status = SSKJobRecordStatus(rawValue: statusRaw) else {
               throw SDSError.invalidValue
            }
            let contactThreadId = try deserializer.string(at: contactThreadIdColumn.columnIndex)

            return OWSSessionResetJobRecord(uniqueId: uniqueId,
                                            failureCount: failureCount,
                                            label: label,
                                            sortId: sortId,
                                            status: status,
                                            contactThreadId: contactThreadId)

        case .jobRecord:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)
            let failureCount = UInt(try deserializer.int64(at: failureCountColumn.columnIndex))
            let label = try deserializer.string(at: labelColumn.columnIndex)
            let sortId = try deserializer.uint64(at: idColumn.columnIndex)
            let statusRaw = UInt(try deserializer.int(at: statusColumn.columnIndex))
            guard let status = SSKJobRecordStatus(rawValue: statusRaw) else {
               throw SDSError.invalidValue
            }

            return SSKJobRecord(uniqueId: uniqueId,
                                failureCount: failureCount,
                                label: label,
                                sortId: sortId,
                                status: status)

        case .messageSenderJobRecord:

            let uniqueId = try deserializer.string(at: uniqueIdColumn.columnIndex)
            let failureCount = UInt(try deserializer.int64(at: failureCountColumn.columnIndex))
            let label = try deserializer.string(at: labelColumn.columnIndex)
            let sortId = try deserializer.uint64(at: idColumn.columnIndex)
            let statusRaw = UInt(try deserializer.int(at: statusColumn.columnIndex))
            guard let status = SSKJobRecordStatus(rawValue: statusRaw) else {
               throw SDSError.invalidValue
            }
            let invisibleMessageSerialized: Data? = try deserializer.optionalBlob(at: invisibleMessageColumn.columnIndex)
            let invisibleMessage: TSOutgoingMessage? = try SDSDeserializer.optionalUnarchive(invisibleMessageSerialized)
            let messageId = try deserializer.optionalString(at: messageIdColumn.columnIndex)
            let removeMessageAfterSending = try deserializer.bool(at: removeMessageAfterSendingColumn.columnIndex)
            let threadId = try deserializer.optionalString(at: threadIdColumn.columnIndex)

            return SSKMessageSenderJobRecord(uniqueId: uniqueId,
                                             failureCount: failureCount,
                                             label: label,
                                             sortId: sortId,
                                             status: status,
                                             invisibleMessage: invisibleMessage,
                                             messageId: messageId,
                                             removeMessageAfterSending: removeMessageAfterSending,
                                             threadId: threadId)

        default:
            owsFail("Invalid record type \(recordType)")
        }
    }
}

// MARK: - Save/Remove/Update

@objc
extension SSKJobRecord {
    public func anySave(transaction: SDSAnyWriteTransaction) {
        switch transaction.writeTransaction {
        case .yapWrite(let ydbTransaction):
            save(with: ydbTransaction)
        case .grdbWrite(let grdbTransaction):
            SDSSerialization.save(entity: self, transaction: grdbTransaction)
        }
    }

    // This method is used by "updateWith..." methods.
    //
    // This model may be updated from many threads. We don't want to save
    // our local copy (this instance) since it may be out of date.  We also
    // want to avoid re-saving a model that has been deleted.  Therefore, we
    // use "updateWith..." methods to:
    //
    // a) Update a property of this instance.
    // b) If a copy of this model exists in the database, load an up-to-date copy,
    //    and update and save that copy.
    // b) If a copy of this model _DOES NOT_ exist in the database, do _NOT_ save
    //    this local instance.
    //
    // After "updateWith...":
    //
    // a) Any copy of this model in the database will have been updated.
    // b) The local property on this instance will always have been updated.
    // c) Other properties on this instance may be out of date.
    //
    // All mutable properties of this class have been made read-only to
    // prevent accidentally modifying them directly.
    //
    // This isn't a perfect arrangement, but in practice this will prevent
    // data loss and will resolve all known issues.
    public func anyUpdateWith(transaction: SDSAnyWriteTransaction, block: (SSKJobRecord) -> Void) {
        guard let uniqueId = uniqueId else {
            owsFailDebug("Missing uniqueId.")
            return
        }

        guard let dbCopy = type(of: self).anyFetch(uniqueId: uniqueId,
                                                   transaction: transaction) else {
            return
        }

        block(self)
        block(dbCopy)

        dbCopy.anySave(transaction: transaction)
    }

    public func anyRemove(transaction: SDSAnyWriteTransaction) {
        switch transaction.writeTransaction {
        case .yapWrite(let ydbTransaction):
            remove(with: ydbTransaction)
        case .grdbWrite(let grdbTransaction):
            SDSSerialization.delete(entity: self, transaction: grdbTransaction)
        }
    }
}

// MARK: - SSKJobRecordCursor

@objc
public class SSKJobRecordCursor: NSObject {
    private let cursor: SDSCursor<SSKJobRecord>

    init(cursor: SDSCursor<SSKJobRecord>) {
        self.cursor = cursor
    }

    // TODO: Revisit error handling in this class.
    public func next() throws -> SSKJobRecord? {
        return try cursor.next()
    }

    public func all() throws -> [SSKJobRecord] {
        return try cursor.all()
    }
}

// MARK: - Obj-C Fetch

// TODO: We may eventually want to define some combination of:
//
// * fetchCursor, fetchOne, fetchAll, etc. (ala GRDB)
// * Optional "where clause" parameters for filtering.
// * Async flavors with completions.
//
// TODO: I've defined flavors that take a read transaction.
//       Or we might take a "connection" if we end up having that class.
@objc
extension SSKJobRecord {
    public class func grdbFetchCursor(transaction: GRDBReadTransaction) -> SSKJobRecordCursor {
        return SSKJobRecordCursor(cursor: SDSSerialization.fetchCursor(tableMetadata: SSKJobRecordSerializer.table,
                                                                   transaction: transaction,
                                                                   deserialize: SSKJobRecordSerializer.sdsDeserialize))
    }

    // Fetches a single model by "unique id".
    public class func anyFetch(uniqueId: String,
                               transaction: SDSAnyReadTransaction) -> SSKJobRecord? {
        assert(uniqueId.count > 0)

        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            return SSKJobRecord.fetch(uniqueId: uniqueId, transaction: ydbTransaction)
        case .grdbRead(let grdbTransaction):
            let sql = "SELECT * FROM \(JobRecordRecord.databaseTableName) WHERE \(jobRecordColumn: .uniqueId) = ?"
            return grdbFetchOne(sql: sql, arguments: [uniqueId], transaction: grdbTransaction)
        }
    }

    // Traverses all records.
    // Records are not visited in any particular order.
    // Traversal aborts if the visitor returns false.
    public class func anyVisitAll(transaction: SDSAnyReadTransaction, visitor: @escaping (SSKJobRecord) -> Bool) {
        switch transaction.readTransaction {
        case .yapRead(let ydbTransaction):
            SSKJobRecord.enumerateCollectionObjects(with: ydbTransaction) { (object, stop) in
                guard let value = object as? SSKJobRecord else {
                    owsFailDebug("unexpected object: \(type(of: object))")
                    return
                }
                guard visitor(value) else {
                    stop.pointee = true
                    return
                }
            }
        case .grdbRead(let grdbTransaction):
            do {
                let cursor = SSKJobRecord.grdbFetchCursor(transaction: grdbTransaction)
                while let value = try cursor.next() {
                    guard visitor(value) else {
                        return
                    }
                }
            } catch let error as NSError {
                owsFailDebug("Couldn't fetch models: \(error)")
            }
        }
    }

    // Does not order the results.
    public class func anyFetchAll(transaction: SDSAnyReadTransaction) -> [SSKJobRecord] {
        var result = [SSKJobRecord]()
        anyVisitAll(transaction: transaction) { (model) in
            result.append(model)
            return true
        }
        return result
    }
}

// MARK: - Swift Fetch

extension SSKJobRecord {
    public class func grdbFetchCursor(sql: String,
                                      arguments: [DatabaseValueConvertible]?,
                                      transaction: GRDBReadTransaction) -> SSKJobRecordCursor {
        var statementArguments: StatementArguments?
        if let arguments = arguments {
            guard let statementArgs = StatementArguments(arguments) else {
                owsFail("Could not convert arguments.")
            }
            statementArguments = statementArgs
        }
        return SSKJobRecordCursor(cursor: SDSSerialization.fetchCursor(sql: sql,
                                                             arguments: statementArguments,
                                                             transaction: transaction,
                                                                   deserialize: SSKJobRecordSerializer.sdsDeserialize))
    }

    public class func grdbFetchOne(sql: String,
                                   arguments: StatementArguments,
                                   transaction: GRDBReadTransaction) -> SSKJobRecord? {
        assert(sql.count > 0)

        do {
            guard let record = try JobRecordRecord.fetchOne(transaction.database, sql: sql, arguments: arguments) else {
                return nil
            }

            return try SSKJobRecord.fromRecord(record)
        } catch {
            owsFailDebug("error: \(error)")
            return nil
        }
    }
}

// MARK: - SDSSerializer

// The SDSSerializer protocol specifies how to insert and update the
// row that corresponds to this model.
class SSKJobRecordSerializer: SDSSerializer {

    private let model: SSKJobRecord
    public required init(model: SSKJobRecord) {
        self.model = model
    }

    public func serializableColumnTableMetadata() -> SDSTableMetadata {
        return SSKJobRecordSerializer.table
    }

    public func insertColumnNames() -> [String] {
        // When we insert a new row, we include the following columns:
        //
        // * "record type"
        // * "unique id"
        // * ...all columns that we set when updating.
        return [
            SSKJobRecordSerializer.recordTypeColumn.columnName,
            uniqueIdColumnName()
            ] + updateColumnNames()

    }

    public func insertColumnValues() -> [DatabaseValueConvertible] {
        let result: [DatabaseValueConvertible] = [
            SDSRecordType.jobRecord.rawValue
            ] + [uniqueIdColumnValue()] + updateColumnValues()
        if OWSIsDebugBuild() {
            if result.count != insertColumnNames().count {
                owsFailDebug("Update mismatch: \(result.count) != \(insertColumnNames().count)")
            }
        }
        return result
    }

    public func updateColumnNames() -> [String] {
        return [
            SSKJobRecordSerializer.failureCountColumn,
            SSKJobRecordSerializer.labelColumn,
            SSKJobRecordSerializer.statusColumn
            ].map { $0.columnName }
    }

    public func updateColumnValues() -> [DatabaseValueConvertible] {
        let result: [DatabaseValueConvertible] = [
            self.model.failureCount,
            self.model.label,
            self.model.status.rawValue

        ]
        if OWSIsDebugBuild() {
            if result.count != updateColumnNames().count {
                owsFailDebug("Update mismatch: \(result.count) != \(updateColumnNames().count)")
            }
        }
        return result
    }

    public func uniqueIdColumnName() -> String {
        return SSKJobRecordSerializer.uniqueIdColumn.columnName
    }

    // TODO: uniqueId is currently an optional on our models.
    //       We should probably make the return type here String?
    public func uniqueIdColumnValue() -> DatabaseValueConvertible {
        // FIXME remove force unwrap
        return model.uniqueId!
    }
}
