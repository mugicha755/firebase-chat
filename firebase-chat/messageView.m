//
//  messageView.m
//  firebase-chat
//
//  Created by mugicha on 2015/07/17.
//  Copyright © 2015年 mugicha. All rights reserved.
//

#import "messageView.h"
#import "fbMng.h"

#define kMessageViewUserID      @"message user id"
#define kMessageViewBotID       @"message bot id"


@interface messageView () {

    NSMutableArray *_messageList;
    
    NSString *_botID;
    NSString *_userID;
    
    JSQMessagesBubbleImage *_incomingBubble;
    JSQMessagesBubbleImage *_outgoingBubble;
    JSQMessagesAvatarImage *_incomingAvatar;
    JSQMessagesAvatarImage *_outgoingAvatar;
    
    fbMng *_fbMng;
}


@end

@implementation messageView

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initUser];
    
    // firebase manager初期化
    _fbMng = [[fbMng alloc] initWithId:_userID bot:_botID observer:self callback:@selector(reqMessage)];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)initUser {
    
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    // firebaseに登録するユーザ情報とローカルの情報を一致させるため
    // 先にIDの生成と永続化(とその読み出し)を行う
    
    // ID読み出し
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    
    _botID = [userDef stringForKey:kMessageViewBotID];
    _userID = [userDef stringForKey:kMessageViewUserID];
    
    // 未生成判定
    if(( nil == _botID ) || ( nil == _userID )){
        
        // ID生成
        _botID = [NSUUID UUID].UUIDString;
        _userID = [NSUUID UUID].UUIDString;
        [userDef setObject:_botID forKey:kMessageViewBotID];
        [userDef setObject:_userID forKey:kMessageViewUserID];
        [userDef synchronize];
    }

    
    // user設定 : senderID(firebase上のuser_hashを利用)
    self.senderId = _userID;
    // user設定 : 画面上の名前
    self.senderDisplayName = @"mugicha";
    
    // 吹き出し
    JSQMessagesBubbleImageFactory *bubbleFactory = [JSQMessagesBubbleImageFactory new];
    // 吹き出し設定 : 受信
    _incomingBubble = [bubbleFactory  incomingMessagesBubbleImageWithColor:[UIColor lightGrayColor]];
    // 吹き出し設定 : 送信
    _outgoingBubble = [bubbleFactory  outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
    
    // アイコン設定 : 受信
    _incomingAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"ava_bot.png"] diameter:64];
    // アイコン設定 : 送信
    _outgoingAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"ava_mugicha.png"] diameter:64];
    
    _messageList = [NSMutableArray array];
}


#pragma mark - JSQMessagesViewController delegate

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date {
    // 送信サウンド
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    // メッセージオブジェクト生成(id + name + 日付 + テキスト)
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    [_messageList addObject:message];
    
    // 送信
    [self finishSendingMessageAnimated:YES];
    
    [_fbMng setFbValue:@{@"user_id" : senderId,
                         @"message" : text,
                         @"time_stamp" : [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
                          }];
    
    [self sendBotMessage];
}

// 参照するメッセージオブジェクト
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView
       messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [_messageList objectAtIndex:indexPath.item];
}


// メッセージ毎のmessage bubble(背景)
- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
             messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    JSQMessage *message = [_messageList objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return _outgoingBubble;
    }
    return _incomingBubble;
}

// メッセージ毎のavatar(アイコン)
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
                    avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    JSQMessage *message = [_messageList objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return _outgoingAvatar;
    }
    return _incomingAvatar;
}



// メッセージ数
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    
    return _messageList.count;
}


// 参照するメッセージオブジェクトのタイムスタンプ
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView
attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    // 無条件設定
    // 無条件のため、すべてのメッセージにタイムスタンプが表示されるので、本来は条件を設定すべき...
    JSQMessage *message = [_messageList objectAtIndex:indexPath.item];
    return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
}


// 参照するメッセージの送信者名
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    JSQMessage *message = [_messageList objectAtIndex:indexPath.item];

    // 自身の送信したメッセージは表示対象外
    if( [message.senderId isEqualToString:self.senderId] ){
        return nil;
    }
    
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

// タイムスタンプ表示の高さ
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {

    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}


- (void)sendBotMessage {
    [NSTimer scheduledTimerWithTimeInterval:0.25F
                                     target:self
                                   selector:@selector(didFinishMessageTimer:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)didFinishMessageTimer:(NSTimer*)timer {
    // 送信サウンド
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    // メッセージオブジェクト生成
    JSQMessage *pMessage = [[JSQMessage alloc] initWithSenderId:_botID
                                              senderDisplayName:@"bot"
                                                           date:[NSDate date]
                                                           text:@"bot message"];
    
    
    [_messageList addObject:pMessage];
    [self finishReceivingMessageAnimated:YES];

}


-(void)reqMessage {
    
    // メッセージ情報をQuery
    [_fbMng reqMessageQuery:@selector(resultQuery:) observer:self];
}



-(void)resultQuery:(NSNotification*)userInfo {
    
    FDataSnapshot *snapshot = (FDataSnapshot*)userInfo.userInfo;
    
    NSEnumerator *enumerator = snapshot.children;
    FDataSnapshot* obj;
    
    while( obj = [enumerator nextObject] ) {

        // firebase格納のメッセージの取り出し
        NSDictionary *messageVal = obj.value;
        
        // メッセージオブジェクト生成(id + name + 日付 + テキスト)
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:[messageVal valueForKey:@"user_id"]
                                                 senderDisplayName:@"mugicha"
                                                              date:[NSDate dateWithTimeIntervalSince1970:[[messageVal valueForKey:@"time_stamp"] intValue]]
                                                              text:[messageVal objectForKey:@"message"]];
        [_messageList addObject:message];
        
        // 送信
        [self finishSendingMessageAnimated:YES];
        
    }
    
    
}




@end


