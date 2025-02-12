//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "OWSStickerPackSyncMessage.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSStickerPackSyncMessage ()

@property (nonatomic, readonly) NSArray<StickerPackInfo *> *packs;
@property (nonatomic, readonly) StickerPackOperationType operationType;

@end

#pragma mark -

@implementation OWSStickerPackSyncMessage

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

- (instancetype)initWithPacks:(NSArray<StickerPackInfo *> *)packs operationType:(StickerPackOperationType)operationType
{
    self = [super init];
    if (!self) {
        return self;
    }

    _packs = packs;
    _operationType = operationType;

    return self;
}

- (nullable SSKProtoSyncMessageBuilder *)syncMessageBuilder
{
    SSKProtoSyncMessageStickerPackOperationType operationType;
    switch (self.operationType) {
        case StickerPackOperationType_Install:
            operationType = SSKProtoSyncMessageStickerPackOperationTypeInstall;
            break;
        case StickerPackOperationType_Remove:
            operationType = SSKProtoSyncMessageStickerPackOperationTypeRemove;
            break;
    }

    SSKProtoSyncMessageBuilder *syncMessageBuilder = [SSKProtoSyncMessage builder];

    for (StickerPackInfo *pack in self.packs) {
        SSKProtoSyncMessageStickerPackOperationBuilder *packOperationBuilder =
            [SSKProtoSyncMessageStickerPackOperation builderWithPackID:pack.packId
                                                               packKey:pack.packKey
                                                                  type:operationType];

        NSError *error;
        SSKProtoSyncMessageStickerPackOperation *_Nullable packOperationProto =
            [packOperationBuilder buildAndReturnError:&error];
        if (error || !packOperationProto) {
            OWSFailDebug(@"could not build protobuf: %@", error);
            return nil;
        }
        [syncMessageBuilder addStickerPackOperation:packOperationProto];
    }

    return syncMessageBuilder;
}

@end

NS_ASSUME_NONNULL_END
