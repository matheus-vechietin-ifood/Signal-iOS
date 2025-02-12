//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "TSInvalidIdentityKeyReceivingErrorMessage.h"
#import "OWSFingerprint.h"
#import "OWSIdentityManager.h"
#import "OWSMessageManager.h"
#import "OWSMessageReceiver.h"
#import "OWSPrimaryStorage+SessionStore.h"
#import "OWSPrimaryStorage.h"
#import "SSKEnvironment.h"
#import "TSContactThread.h"
#import "TSDatabaseView.h"
#import "TSErrorMessage_privateConstructor.h"
#import <AxolotlKit/NSData+keyVersionByte.h>
#import <AxolotlKit/PreKeyWhisperMessage.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>
#import <YapDatabase/YapDatabaseTransaction.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((deprecated)) @interface TSInvalidIdentityKeyReceivingErrorMessage()

@property (nonatomic, readonly, copy) NSString *authorId;

@property (atomic, nullable) NSData *envelopeData;

@end

#pragma mark -

@implementation TSInvalidIdentityKeyReceivingErrorMessage {
    // Not using a property declaration in order to exclude from DB serialization
    SSKProtoEnvelope *_Nullable _envelope;
}

#ifdef DEBUG
// We no longer create these messages, but they might exist on legacy clients so it's useful to be able to
// create them with the debug UI
+ (nullable instancetype)untrustedKeyWithEnvelope:(SSKProtoEnvelope *)envelope
                                  withTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    TSContactThread *contactThread =
    [TSContactThread getOrCreateThreadWithContactId:envelope.source transaction:transaction];

    // Legit usage of senderTimestamp, references message which failed to decrypt
    TSInvalidIdentityKeyReceivingErrorMessage *errorMessage =
        [[self alloc] initForUnknownIdentityKeyWithTimestamp:envelope.timestamp
                                                    inThread:contactThread
                                            incomingEnvelope:envelope];
    return errorMessage;
}

- (nullable instancetype)initForUnknownIdentityKeyWithTimestamp:(uint64_t)timestamp
                                                       inThread:(TSThread *)thread
                                               incomingEnvelope:(SSKProtoEnvelope *)envelope
{
    self = [self initWithTimestamp:timestamp inThread:thread failedMessageType:TSErrorMessageWrongTrustedIdentityKey];
    if (!self) {
        return self;
    }
    
    NSError *error;
    _envelopeData = [envelope serializedDataAndReturnError:&error];
    if (!_envelopeData || error != nil) {
        OWSFailDebug(@"failure: envelope data failed with error: %@", error);
        return nil;
    }
    
    _authorId = envelope.source;
    
    return self;
}
#endif

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithUniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
                   attachmentIds:(NSArray<NSString *> *)attachmentIds
                            body:(nullable NSString *)body
                    contactShare:(nullable OWSContact *)contactShare
                 expireStartedAt:(uint64_t)expireStartedAt
                       expiresAt:(uint64_t)expiresAt
                expiresInSeconds:(unsigned int)expiresInSeconds
                     linkPreview:(nullable OWSLinkPreview *)linkPreview
                  messageSticker:(nullable MessageSticker *)messageSticker
                   quotedMessage:(nullable TSQuotedMessage *)quotedMessage
                   schemaVersion:(NSUInteger)schemaVersion
       errorMessageSchemaVersion:(NSUInteger)errorMessageSchemaVersion
                       errorType:(TSErrorMessageType)errorType
                            read:(BOOL)read
                     recipientId:(nullable NSString *)recipientId
                        authorId:(NSString *)authorId
                    envelopeData:(nullable NSData *)envelopeData
{
    self = [super initWithUniqueId:uniqueId
               receivedAtTimestamp:receivedAtTimestamp
                            sortId:sortId
                         timestamp:timestamp
                    uniqueThreadId:uniqueThreadId
                     attachmentIds:attachmentIds
                              body:body
                      contactShare:contactShare
                   expireStartedAt:expireStartedAt
                         expiresAt:expiresAt
                  expiresInSeconds:expiresInSeconds
                       linkPreview:linkPreview
                    messageSticker:messageSticker
                     quotedMessage:quotedMessage
                     schemaVersion:schemaVersion
         errorMessageSchemaVersion:errorMessageSchemaVersion
                         errorType:errorType
                              read:read
                       recipientId:recipientId];

    if (!self) {
        return self;
    }

    _authorId = authorId;
    _envelopeData = envelopeData;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

- (nullable SSKProtoEnvelope *)envelope
{
    if (!_envelope) {
        NSError *error;
        SSKProtoEnvelope *_Nullable envelope = [SSKProtoEnvelope parseData:self.envelopeData error:&error];
        if (error || envelope == nil) {
            OWSFailDebug(@"Could not parse proto: %@", error);
        } else {
            _envelope = envelope;
        }
    }
    return _envelope;
}

- (void)throws_acceptNewIdentityKey
{
    OWSAssertIsOnMainThread();

    if (self.errorType != TSErrorMessageWrongTrustedIdentityKey) {
        OWSLogError(@"Refusing to accept identity key for anything but a Key error.");
        return;
    }

    NSData *_Nullable newKey = [self throws_newIdentityKey];
    if (!newKey) {
        OWSFailDebug(@"Couldn't extract identity key to accept");
        return;
    }

    [[OWSIdentityManager sharedManager] saveRemoteIdentity:newKey recipientId:self.envelope.source];

    // Decrypt this and any old messages for the newly accepted key
    NSArray<TSInvalidIdentityKeyReceivingErrorMessage *> *messagesToDecrypt =
        [self.thread receivedMessagesForInvalidKey:newKey];

    for (TSInvalidIdentityKeyReceivingErrorMessage *errorMessage in messagesToDecrypt) {
        [SSKEnvironment.shared.messageReceiver handleReceivedEnvelopeData:errorMessage.envelopeData];

        // Here we remove the existing error message because handleReceivedEnvelope will either
        //  1.) succeed and create a new successful message in the thread or...
        //  2.) fail and create a new identical error message in the thread.
        [errorMessage remove];
    }
}

- (nullable NSData *)throws_newIdentityKey
{
    if (!self.envelope) {
        OWSLogError(@"Error message had no envelope data to extract key from");
        return nil;
    }

    if (self.envelope.type != SSKProtoEnvelopeTypePrekeyBundle) {
        OWSLogError(@"Refusing to attempt key extraction from an envelope which isn't a prekey bundle");
        return nil;
    }

    NSData *pkwmData = self.envelope.content;
    if (!pkwmData) {
        OWSLogError(@"Ignoring acceptNewIdentityKey for empty message");
        return nil;
    }

    PreKeyWhisperMessage *message = [[PreKeyWhisperMessage alloc] init_throws_withData:pkwmData];
    return [message.identityKey throws_removeKeyType];
}

- (NSString *)theirSignalId
{
    if (self.authorId) {
        return self.authorId;
    } else {
        // for existing messages before we were storing author id.
        return self.envelope.source;
    }
}

@end

NS_ASSUME_NONNULL_END
