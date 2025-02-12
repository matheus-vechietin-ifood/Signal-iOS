//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

#import "OWSMessageCell.h"
#import "OWSContactAvatarBuilder.h"
#import "OWSMessageBubbleView.h"
#import "OWSMessageHeaderView.h"
#import "OWSMessageStickerView.h"
#import "Signal-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSMessageCell ()

// The nullable properties are created as needed.
// The non-nullable properties are so frequently used that it's easier
// to always keep one around.

@property (nonatomic) OWSMessageHeaderView *headerView;
@property (nonatomic) OWSMessageBubbleView *messageBubbleView;
@property (nonatomic) OWSMessageStickerView *messageStickerView;
@property (nonatomic) AvatarImageView *avatarView;
@property (nonatomic, nullable) UIImageView *sendFailureBadgeView;

@property (nonatomic, nullable) NSMutableArray<NSLayoutConstraint *> *viewConstraints;
@property (nonatomic) BOOL isPresentingMenuController;

@end

#pragma mark -

@implementation OWSMessageCell

// `[UIView init]` invokes `[self initWithFrame:...]`.
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commontInit];
    }

    return self;
}

- (void)commontInit
{
    // Ensure only called once.
    OWSAssertDebug(!self.messageBubbleView);

    self.layoutMargins = UIEdgeInsetsZero;
    self.contentView.layoutMargins = UIEdgeInsetsZero;

    _viewConstraints = [NSMutableArray new];

    self.messageBubbleView = [OWSMessageBubbleView new];
    self.messageStickerView = [OWSMessageStickerView new];

    self.headerView = [OWSMessageHeaderView new];

    self.avatarView = [[AvatarImageView alloc] init];
    [self.avatarView autoSetDimension:ALDimensionWidth toSize:self.avatarSize];
    [self.avatarView autoSetDimension:ALDimensionHeight toSize:self.avatarSize];

    self.contentView.userInteractionEnabled = YES;

    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self addGestureRecognizer:tap];

    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self.contentView addGestureRecognizer:longPress];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setConversationStyle:(nullable ConversationStyle *)conversationStyle
{
    [super setConversationStyle:conversationStyle];

    self.messageBubbleView.conversationStyle = conversationStyle;
    self.messageStickerView.conversationStyle = conversationStyle;
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

#pragma mark - Convenience Accessors

- (OWSMessageCellType)cellType
{
    return self.viewItem.messageCellType;
}

- (TSMessage *)message
{
    OWSAssertDebug([self.viewItem.interaction isKindOfClass:[TSMessage class]]);

    return (TSMessage *)self.viewItem.interaction;
}

- (BOOL)isIncoming
{
    return self.viewItem.interaction.interactionType == OWSInteractionType_IncomingMessage;
}

- (BOOL)isOutgoing
{
    return self.viewItem.interaction.interactionType == OWSInteractionType_OutgoingMessage;
}

- (BOOL)shouldHaveSendFailureBadge
{
    if (![self.viewItem.interaction isKindOfClass:[TSOutgoingMessage class]]) {
        return NO;
    }
    TSOutgoingMessage *outgoingMessage = (TSOutgoingMessage *)self.viewItem.interaction;
    return outgoingMessage.messageState == TSOutgoingMessageStateFailed;
}

- (OWSMessageView *)messageView
{
    if (self.cellType == OWSMessageCellType_StickerMessage) {
        return self.messageStickerView;
    } else {
        return self.messageBubbleView;
    }
}

#pragma mark - Load

- (void)loadForDisplay
{
    OWSAssertDebug(self.conversationStyle);
    OWSAssertDebug(self.viewItem);
    OWSAssertDebug(self.viewItem.interaction);
    OWSAssertDebug([self.viewItem.interaction isKindOfClass:[TSMessage class]]);
    OWSAssertDebug(self.messageBubbleView);
    OWSAssertDebug(self.messageStickerView);

    OWSMessageView *messageView = self.messageView;
    messageView.viewItem = self.viewItem;
    messageView.cellMediaCache = self.delegate.cellMediaCache;
    [messageView configureViews];
    [messageView loadContent];
    [self.contentView addSubview:messageView];
    [messageView autoPinBottomToSuperviewMarginWithInset:0];

    if (self.viewItem.hasCellHeader) {
        CGFloat headerHeight =
            [self.headerView measureWithConversationViewItem:self.viewItem conversationStyle:self.conversationStyle]
                .height;
        [self.headerView loadForDisplayWithViewItem:self.viewItem conversationStyle:self.conversationStyle];
        [self.contentView addSubview:self.headerView];
        [self.viewConstraints addObjectsFromArray:@[
            [self.headerView autoSetDimension:ALDimensionHeight toSize:headerHeight],
            [self.headerView autoPinEdgeToSuperviewEdge:ALEdgeLeading],
            [self.headerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing],
            [self.headerView autoPinEdgeToSuperviewEdge:ALEdgeTop],
            [messageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.headerView],
        ]];
    } else {
        [self.viewConstraints addObjectsFromArray:@[
            [messageView autoPinEdgeToSuperviewEdge:ALEdgeTop],
        ]];
    }

    if (self.isIncoming) {
        [self.viewConstraints addObjectsFromArray:@[
            [messageView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:self.conversationStyle.gutterLeading],
            [messageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing
                                          withInset:self.conversationStyle.gutterTrailing
                                           relation:NSLayoutRelationGreaterThanOrEqual],
        ]];
    } else {
        if (self.shouldHaveSendFailureBadge) {
            self.sendFailureBadgeView = [UIImageView new];
            self.sendFailureBadgeView.image =
                [self.sendFailureBadge imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            self.sendFailureBadgeView.tintColor = [UIColor ows_destructiveRedColor];
            [self.contentView addSubview:self.sendFailureBadgeView];

            CGFloat sendFailureBadgeBottomMargin
                = round(self.conversationStyle.lastTextLineAxis - self.sendFailureBadgeSize * 0.5f);
            [self.viewConstraints addObjectsFromArray:@[
                [messageView autoPinEdgeToSuperviewEdge:ALEdgeLeading
                                              withInset:self.conversationStyle.gutterLeading
                                               relation:NSLayoutRelationGreaterThanOrEqual],
                [self.sendFailureBadgeView autoPinLeadingToTrailingEdgeOfView:messageView
                                                                       offset:self.sendFailureBadgeSpacing],
                // V-align the "send failure" badge with the
                // last line of the text (if any, or where it
                // would be).
                [messageView autoPinEdge:ALEdgeBottom
                                  toEdge:ALEdgeBottom
                                  ofView:self.sendFailureBadgeView
                              withOffset:sendFailureBadgeBottomMargin],
                [self.sendFailureBadgeView autoPinEdgeToSuperviewEdge:ALEdgeTrailing
                                                            withInset:self.conversationStyle.errorGutterTrailing],
                [self.sendFailureBadgeView autoSetDimension:ALDimensionWidth toSize:self.sendFailureBadgeSize],
                [self.sendFailureBadgeView autoSetDimension:ALDimensionHeight toSize:self.sendFailureBadgeSize],
            ]];
        } else {
            [self.viewConstraints addObjectsFromArray:@[
                [messageView autoPinEdgeToSuperviewEdge:ALEdgeLeading
                                              withInset:self.conversationStyle.gutterLeading
                                               relation:NSLayoutRelationGreaterThanOrEqual],
                [messageView autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:self.conversationStyle.gutterTrailing],
            ]];
        }
    }

    if ([self updateAvatarView]) {
        [self.viewConstraints addObjectsFromArray:@[
            // V-align the "group sender" avatar with the
            // last line of the text (if any, or where it
            // would be).
            [messageView autoPinLeadingToTrailingEdgeOfView:self.avatarView offset:8],
            [messageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.avatarView],
        ]];
    }
}

- (UIImage *)sendFailureBadge
{
    UIImage *image = [UIImage imageNamed:@"message_status_failed_large"];
    OWSAssertDebug(image);
    OWSAssertDebug(image.size.width == self.sendFailureBadgeSize && image.size.height == self.sendFailureBadgeSize);
    return image;
}

- (CGFloat)sendFailureBadgeSize
{
    return 20.f;
}

- (CGFloat)sendFailureBadgeSpacing
{
    return 8.f;
}

// * If cell is visible, lazy-load (expensive) view contents.
// * If cell is not visible, eagerly unload view contents.
- (void)ensureMediaLoadState
{
    OWSAssertDebug(self.messageView);

    if (!self.isCellVisible) {
        [self.messageView unloadContent];
    } else {
        [self.messageView loadContent];
    }
}

#pragma mark - Avatar

// Returns YES IFF the avatar view is appropriate and configured.
- (BOOL)updateAvatarView
{
    if (!self.viewItem.shouldShowSenderAvatar) {
        return NO;
    }
    if (!self.viewItem.isGroupThread) {
        OWSFailDebug(@"not a group thread.");
        return NO;
    }
    if (self.viewItem.interaction.interactionType != OWSInteractionType_IncomingMessage) {
        OWSFailDebug(@"not an incoming message.");
        return NO;
    }
    OWSAssertDebug(self.viewItem.authorConversationColorName != nil);

    TSIncomingMessage *incomingMessage = (TSIncomingMessage *)self.viewItem.interaction;
    UIImage *_Nullable authorAvatarImage =
        [[[OWSContactAvatarBuilder alloc] initWithSignalId:incomingMessage.authorId
                                                 colorName:self.viewItem.authorConversationColorName
                                                  diameter:self.avatarSize] build];
    self.avatarView.image = authorAvatarImage;
    [self.contentView addSubview:self.avatarView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(otherUsersProfileDidChange:)
                                                 name:kNSNotificationName_OtherUsersProfileDidChange
                                               object:nil];

    return YES;
}

- (NSUInteger)avatarSize
{
    return 36.f;
}

- (void)otherUsersProfileDidChange:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    if (!self.viewItem.shouldShowSenderAvatar) {
        return;
    }
    if (!self.viewItem.isGroupThread) {
        OWSFailDebug(@"not a group thread.");
        return;
    }
    if (self.viewItem.interaction.interactionType != OWSInteractionType_IncomingMessage) {
        OWSFailDebug(@"not an incoming message.");
        return;
    }

    NSString *recipientId = notification.userInfo[kNSNotificationKey_ProfileRecipientId];
    if (recipientId.length == 0) {
        return;
    }
    TSIncomingMessage *incomingMessage = (TSIncomingMessage *)self.viewItem.interaction;

    if (![incomingMessage.authorId isEqualToString:recipientId]) {
        return;
    }

    [self updateAvatarView];
}

#pragma mark - Measurement

- (CGSize)cellSize
{
    OWSAssertDebug(self.conversationStyle);
    OWSAssertDebug(self.conversationStyle.viewWidth > 0);
    OWSAssertDebug(self.viewItem);
    OWSAssertDebug([self.viewItem.interaction isKindOfClass:[TSMessage class]]);
    OWSAssertDebug(self.messageView);

    self.messageView.viewItem = self.viewItem;
    self.messageView.cellMediaCache = self.delegate.cellMediaCache;
    CGSize messageSize = [self.messageView measureSize];

    CGSize cellSize = messageSize;

    OWSAssertDebug(cellSize.width > 0 && cellSize.height > 0);

    if (self.viewItem.hasCellHeader) {
        cellSize.height +=
            [self.headerView measureWithConversationViewItem:self.viewItem conversationStyle:self.conversationStyle]
                .height;
    }

    if (self.shouldHaveSendFailureBadge) {
        cellSize.width += self.sendFailureBadgeSize + self.sendFailureBadgeSpacing;
    }

    cellSize = CGSizeCeil(cellSize);

    return cellSize;
}

#pragma mark - Reuse

- (void)prepareForReuse
{
    [super prepareForReuse];

    [NSLayoutConstraint deactivateConstraints:self.viewConstraints];
    self.viewConstraints = [NSMutableArray new];

    [self.messageBubbleView prepareForReuse];
    [self.messageBubbleView unloadContent];
    [self.messageBubbleView removeFromSuperview];
    [self.messageStickerView prepareForReuse];
    [self.messageStickerView unloadContent];
    [self.messageStickerView removeFromSuperview];

    [self.headerView removeFromSuperview];

    self.avatarView.image = nil;
    [self.avatarView removeFromSuperview];

    [self.sendFailureBadgeView removeFromSuperview];
    self.sendFailureBadgeView = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)setIsCellVisible:(BOOL)isCellVisible {
    BOOL didChange = self.isCellVisible != isCellVisible;

    [super setIsCellVisible:isCellVisible];

    if (!didChange) {
        return;
    }

    [self ensureMediaLoadState];
}

#pragma mark - Gesture recognizers

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    OWSAssertDebug(self.delegate);

    if (sender.state != UIGestureRecognizerStateRecognized) {
        OWSLogVerbose(@"Ignoring tap on message: %@", self.viewItem.interaction.debugDescription);
        return;
    }

    if ([self isGestureInCellHeader:sender]) {
        return;
    }

    if (self.viewItem.interaction.interactionType == OWSInteractionType_OutgoingMessage) {
        TSOutgoingMessage *outgoingMessage = (TSOutgoingMessage *)self.viewItem.interaction;
        if (outgoingMessage.messageState == TSOutgoingMessageStateFailed) {
            [self.delegate didTapFailedOutgoingMessage:outgoingMessage];
            return;
        } else if (outgoingMessage.messageState == TSOutgoingMessageStateSending) {
            // Ignore taps on outgoing messages being sent.
            return;
        }
    }

    [self.messageView handleTapGesture:sender];
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender
{
    OWSAssertDebug(self.delegate);

    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }

    if ([self isGestureInCellHeader:sender]) {
        return;
    }

    BOOL shouldAllowReply = YES;
    if (self.viewItem.interaction.interactionType == OWSInteractionType_OutgoingMessage) {
        TSOutgoingMessage *outgoingMessage = (TSOutgoingMessage *)self.viewItem.interaction;
        if (outgoingMessage.messageState == TSOutgoingMessageStateFailed) {
            // Don't allow "delete" or "reply" on "failed" outgoing messages.
            shouldAllowReply = NO;
        } else if (outgoingMessage.messageState == TSOutgoingMessageStateSending) {
            // Don't allow "delete" or "reply" on "sending" outgoing messages.
            shouldAllowReply = NO;
        }
    }

    // TODO:
    CGPoint locationInMessageBubble = [sender locationInView:self.messageView];
    switch ([self.messageView gestureLocationForLocation:locationInMessageBubble]) {
        case OWSMessageGestureLocation_Default:
        case OWSMessageGestureLocation_OversizeText:
        case OWSMessageGestureLocation_LinkPreview: {
            [self.delegate conversationCell:self
                           shouldAllowReply:shouldAllowReply
                   didLongpressTextViewItem:self.viewItem];
            break;
        }
        case OWSMessageGestureLocation_Media: {
            [self.delegate conversationCell:self
                           shouldAllowReply:shouldAllowReply
                  didLongpressMediaViewItem:self.viewItem];
            break;
        }
        case OWSMessageGestureLocation_QuotedReply: {
            [self.delegate conversationCell:self
                           shouldAllowReply:shouldAllowReply
                  didLongpressQuoteViewItem:self.viewItem];
            break;
        }
        case OWSMessageGestureLocation_Sticker:
            OWSAssertDebug(self.viewItem.stickerInfo != nil);
            [self.delegate conversationCell:self didLongpressSticker:self.viewItem];
            break;
    }
}

- (BOOL)isGestureInCellHeader:(UIGestureRecognizer *)sender
{
    OWSAssertDebug(self.viewItem);

    if (!self.viewItem.hasCellHeader) {
        return NO;
    }

    CGPoint location = [sender locationInView:self];
    CGPoint headerBottom = [self convertPoint:CGPointMake(0, self.headerView.height) fromView:self.headerView];
    return location.y <= headerBottom.y;
}

@end

NS_ASSUME_NONNULL_END
