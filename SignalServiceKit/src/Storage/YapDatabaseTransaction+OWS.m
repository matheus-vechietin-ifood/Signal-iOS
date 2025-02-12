//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "YapDatabaseTransaction+OWS.h"
#import <AxolotlKit/PreKeyRecord.h>
#import <AxolotlKit/SignedPrekeyRecord.h>
#import <Curve25519Kit/Curve25519.h>
#import <SignalServiceKit/OWSPrimaryStorage.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation YapDatabaseReadTransaction (OWS)

- (nullable id)objectForKey:(NSString *)key inCollection:(NSString *)collection ofExpectedType:(Class) class {
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    id _Nullable value = [self objectForKey:key inCollection:collection];
    OWSAssertDebug(!value || [value isKindOfClass:class]);
    return value;
}

    - (nullable NSDictionary *)dictionaryForKey : (NSString *)key inCollection : (NSString *)collection
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    return [self objectForKey:key inCollection:collection ofExpectedType:[NSDictionary class]];
}

- (nullable NSString *)stringForKey:(NSString *)key inCollection:(NSString *)collection
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    return [self objectForKey:key inCollection:collection ofExpectedType:[NSString class]];
}

- (BOOL)boolForKey:(NSString *)key inCollection:(NSString *)collection defaultValue:(BOOL)defaultValue
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    NSNumber *_Nullable value = [self objectForKey:key inCollection:collection ofExpectedType:[NSNumber class]];
    return value ? [value boolValue] : defaultValue;
}

- (nullable NSData *)dataForKey:(NSString *)key inCollection:(NSString *)collection
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    return [self objectForKey:key inCollection:collection ofExpectedType:[NSData class]];
}

- (nullable ECKeyPair *)keyPairForKey:(NSString *)key inCollection:(NSString *)collection
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    return [self objectForKey:key inCollection:collection ofExpectedType:[ECKeyPair class]];
}

- (nullable PreKeyRecord *)preKeyRecordForKey:(NSString *)key inCollection:(NSString *)collection
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    return [self objectForKey:key inCollection:collection ofExpectedType:[PreKeyRecord class]];
}

- (nullable SignedPreKeyRecord *)signedPreKeyRecordForKey:(NSString *)key inCollection:(NSString *)collection
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    return [self objectForKey:key inCollection:collection ofExpectedType:[SignedPreKeyRecord class]];
}

- (int)intForKey:(NSString *)key inCollection:(NSString *)collection
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    NSNumber *_Nullable number = [self objectForKey:key inCollection:collection ofExpectedType:[NSNumber class]];
    return [number intValue];
}

- (nullable NSDate *)dateForKey:(NSString *)key inCollection:(NSString *)collection
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    NSNumber *_Nullable value = [self objectForKey:key inCollection:collection ofExpectedType:[NSNumber class]];
    if (value) {
        return [NSDate dateWithTimeIntervalSince1970:value.doubleValue];
    } else {
        return nil;
    }
}

#pragma mark - Extensions

- (nullable id)safe_extension:(NSString *)extensionName
                        clazz:(Class)clazz {
    id _Nullable result = [self extension:extensionName];
    
    if (![result isKindOfClass:clazz]) {
        [OWSPrimaryStorage incrementVersionOfDatabaseExtension:extensionName];

        if (SSKFeatureFlags.strictYDBExtensions) {
            OWSFail(@"Couldn't load database extension: %@.", extensionName);
        } else {
            LogStackTrace();
            OWSFailDebug(@"Couldn't load database extension: %@.", extensionName);
        }
        return nil;
    }
    return result;
}

- (nullable YapDatabaseViewTransaction *)safeViewTransaction:(NSString *)extensionName {
    return [self safe_extension:extensionName clazz:[YapDatabaseViewTransaction class]];
}

- (nullable YapDatabaseAutoViewTransaction *)safeAutoViewTransaction:(NSString *)extensionName {
    return [self safe_extension:extensionName clazz:[YapDatabaseAutoViewTransaction class]];
}

- (nullable YapDatabaseSecondaryIndexTransaction *)safeSecondaryIndexTransaction:(NSString *)extensionName {
    return [self safe_extension:extensionName clazz:[YapDatabaseSecondaryIndexTransaction class]];
}

- (nullable YapDatabaseFullTextSearchTransaction *)safeFullTextSearchTransaction:(NSString *)extensionName {
    return [self safe_extension:extensionName clazz:[YapDatabaseFullTextSearchTransaction class]];
}

@end

#pragma mark -

@implementation YapDatabaseReadWriteTransaction (OWS)

#pragma mark - Debug

#if DEBUG
- (void)snapshotCollection:(NSString *)collection snapshotFilePath:(NSString *)snapshotFilePath
{
    OWSAssertDebug(collection.length > 0);
    OWSAssertDebug(snapshotFilePath.length > 0);

    NSMutableDictionary<NSString *, id> *snapshot = [NSMutableDictionary new];
    [self enumerateKeysAndObjectsInCollection:collection
                                   usingBlock:^(NSString *_Nonnull key, id _Nonnull value, BOOL *_Nonnull stop) {
                                       snapshot[key] = value;
                                   }];
    NSData *_Nullable data = [NSKeyedArchiver archivedDataWithRootObject:snapshot];
    OWSAssertDebug(data);
    BOOL success = [data writeToFile:snapshotFilePath atomically:YES];
    OWSAssertDebug(success);
}

- (void)restoreSnapshotOfCollection:(NSString *)collection snapshotFilePath:(NSString *)snapshotFilePath
{
    OWSAssertDebug(collection.length > 0);
    OWSAssertDebug(snapshotFilePath.length > 0);

    NSData *_Nullable data = [NSData dataWithContentsOfFile:snapshotFilePath];
    OWSAssertDebug(data);
    NSMutableDictionary<NSString *, id> *_Nullable snapshot = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    OWSAssertDebug(snapshot);

    [self removeAllObjectsInCollection:collection];
    [snapshot enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, id _Nonnull value, BOOL *_Nonnull stop) {
        [self setObject:value forKey:key inCollection:collection];
    }];
}
#endif

- (void)setBool:(BOOL)value forKey:(NSString *)key inCollection:(NSString *)collection
{
    OWSAssertDebug(key.length > 0);
    OWSAssertDebug(collection.length > 0);

    NSNumber *_Nullable oldValue = [self objectForKey:key inCollection:collection ofExpectedType:[NSNumber class]];
    if (oldValue && [@(value) isEqual:oldValue]) {
        // Skip redundant writes.
        return;
    }

    [self setObject:@(value) forKey:key inCollection:collection];
}

- (void)setDate:(NSDate *)value forKey:(NSString *)key inCollection:(NSString *)collection
{
    [self setObject:@(value.timeIntervalSince1970) forKey:key inCollection:collection];
}

@end

NS_ASSUME_NONNULL_END
