//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import <YapDatabase/YapDatabase.h>

@class ECKeyPair;
@class PreKeyRecord;
@class SignedPreKeyRecord;
@class YapDatabaseAutoViewTransaction;
@class YapDatabaseFullTextSearchTransaction;
@class YapDatabaseSecondaryIndexTransaction;
@class YapDatabaseViewTransaction;

NS_ASSUME_NONNULL_BEGIN

@interface YapDatabaseReadTransaction (OWS)

- (BOOL)boolForKey:(NSString *)key inCollection:(NSString *)collection defaultValue:(BOOL)defaultValue;
- (int)intForKey:(NSString *)key inCollection:(NSString *)collection;
- (nullable NSDate *)dateForKey:(NSString *)key inCollection:(NSString *)collection;
- (nullable NSDictionary *)dictionaryForKey:(NSString *)key inCollection:(NSString *)collection;
- (nullable NSString *)stringForKey:(NSString *)key inCollection:(NSString *)collection;
- (nullable NSData *)dataForKey:(NSString *)key inCollection:(NSString *)collection;
- (nullable ECKeyPair *)keyPairForKey:(NSString *)key inCollection:(NSString *)collection;
- (nullable PreKeyRecord *)preKeyRecordForKey:(NSString *)key inCollection:(NSString *)collection;
- (nullable SignedPreKeyRecord *)signedPreKeyRecordForKey:(NSString *)key inCollection:(NSString *)collection;

#pragma mark - Extensions

- (nullable YapDatabaseViewTransaction *)safeViewTransaction:(NSString *)extensionName NS_SWIFT_NAME(safeViewTransaction(_:));
- (nullable YapDatabaseAutoViewTransaction *)safeAutoViewTransaction:(NSString *)extensionName NS_SWIFT_NAME(safeAutoViewTransaction(_:));
- (nullable YapDatabaseSecondaryIndexTransaction *)safeSecondaryIndexTransaction:(NSString *)extensionName NS_SWIFT_NAME(safeSecondaryIndexTransaction(_:));
- (nullable YapDatabaseFullTextSearchTransaction *)safeFullTextSearchTransaction:(NSString *)extensionName NS_SWIFT_NAME(safeFullTextSearchTransaction(_:));

@end

#pragma mark -

@interface YapDatabaseReadWriteTransaction (OWS)

#pragma mark - Debug

#if DEBUG
- (void)snapshotCollection:(NSString *)collection snapshotFilePath:(NSString *)snapshotFilePath;
- (void)restoreSnapshotOfCollection:(NSString *)collection snapshotFilePath:(NSString *)snapshotFilePath;
#endif

- (void)setBool:(BOOL)value forKey:(NSString *)key inCollection:(NSString *)collection;
- (void)setDate:(NSDate *)value forKey:(NSString *)key inCollection:(NSString *)collection;

@end

NS_ASSUME_NONNULL_END
