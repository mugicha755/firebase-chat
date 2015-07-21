//
//  fbMng.m
//  firebase-chat
//
//  Created by mugicha on 2015/07/15.
//  Copyright © 2015年 mugicha. All rights reserved.
//

#import "fbMng.h"

#define FB_ROOT_URL         @"https://{your application}.firebaseio.com/"
#define FB_USER_LIST_URL    @"https://{your application}.firebaseio.com/user_list/"
#define FB_ROOM_LIST_URL    @"https://{your application}.firebaseio.com/room_list/"
#define FB_MESSAGE_LIST_URL @"https://{your application}.firebaseio.com/message_list/"

#define kChatRoomId         @"chat room id"
#define kQueryMessage       @"query message_list"
#define kCreateRoom         @"create room"

@interface fbMng() {
    // blocksで操作するためblock修飾子を追加
    __block Firebase *_fbRoot;
    __block Firebase *_fbUserListMng;
    __block Firebase *_fbRoomListMng;
    __block Firebase *_fbMessageListMng;
    
    __block NSString *_fbBotID;
    __block NSString *_fbUserID;
}

@end


@implementation fbMng

// 初期化
-(id)initWithId:(NSString *)userID
            bot:(NSString *)botID
       observer:(id)setObsever
       callback:(SEL)callback {
    
    // notification center登録
    // chat room生成完了を通知するための配慮
    NSNotificationCenter *pNotificationCenter = [NSNotificationCenter defaultCenter];
    [pNotificationCenter addObserver:setObsever
                            selector:callback
                                name:kCreateRoom
                              object:nil];
    
    // ID保存
    _fbBotID = botID;
    _fbUserID = userID;
    
    // Firebase初期設定
    [self initFb];
    return self;
}


-(void)initFb {
    _fbRoot = [[Firebase alloc] initWithUrl:FB_ROOT_URL];
    _fbUserListMng = [[Firebase alloc] initWithUrl:FB_USER_LIST_URL];
    _fbRoomListMng = [[Firebase alloc] initWithUrl:FB_ROOM_LIST_URL];
    [self reqEventFromRoot];
}


-(void)reqEventFromRoot
{
    [_fbRoot observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        // 子要素なし判定
        if( snapshot.childrenCount == 0 ) {
            // 子要素の初期設定
            NSLog(@"%s",__func__);
            
            //room id
            NSString *roomID = [NSUUID UUID].UUIDString;
            
            //room list
            NSDictionary *roomList = @{
                                        roomID :   @{
                                                @"room_name" : @"mugi_room",
                                                @"create_at" : [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
                                                }
                                        };
            
            //user list
            NSDictionary *userList = @{
                                        _fbUserID :   @{
                                                @"room_name" : @"mugicha",
                                                @"create_at" : [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
                                                },
                                        _fbBotID :   @{
                                                @"room_name" : @"bot",
                                                @"create_at" : [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
                                                }
                                        };

            // RoomID永続化
            NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
            [userDef setObject:roomID forKey:kChatRoomId];
            [userDef synchronize];
            
            // 初期データ設定
            [[_fbRoot childByAppendingPath:@"room_list"] setValue:roomList];
            [[_fbRoot childByAppendingPath:@"user_list"] setValue:userList];
            
            // message list用URL
            NSString *messageURL = [NSString stringWithFormat:@"%@%@/",FB_MESSAGE_LIST_URL,roomID];
            _fbMessageListMng = [[Firebase alloc] initWithUrl:messageURL];

        }
        else {
            // 永続化した情報の読み出し
            NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
            NSString *roomIdFromUserDef = [userDef stringForKey:kChatRoomId];
            
            // message list用URL
            NSString *messageURL = [NSString stringWithFormat:@"%@%@/",FB_MESSAGE_LIST_URL,roomIdFromUserDef];
            _fbMessageListMng = [[Firebase alloc] initWithUrl:messageURL];
        }
        
        // post
        [NSNotification notificationWithName:kQueryMessage object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCreateRoom
                                                            object:self
                                                          userInfo:nil];
    }];
}


-(void)setFbValue:(id)newRecode
         withPath:(NSString *)pPath {
    
    [[_fbMessageListMng childByAppendingPath:pPath] setValue:newRecode];
}

-(void)setFbValue:(id)newRecode {
    
    [[_fbMessageListMng childByAutoId] setValue:newRecode];
}

- (void) reqMessageQuery:(SEL)callback
                observer:(id)setObsever
{
    // notification center登録
    NSNotificationCenter *pNotificationCenter = [NSNotificationCenter defaultCenter];
    [pNotificationCenter addObserver:setObsever
                            selector:callback
                                name:kQueryMessage
                              object:nil];
    
    [[_fbMessageListMng queryOrderedByValue] observeSingleEventOfType:FEventTypeValue
                                                            withBlock:^(FDataSnapshot *snapshot) {
                                                                
                                                                // post
                                                                [NSNotification notificationWithName:kQueryMessage object:self];
                                                                [[NSNotificationCenter defaultCenter] postNotificationName:kQueryMessage
                                                                                                                    object:self
                                                                                                                  userInfo:(NSDictionary*)snapshot];
                                                                
                                                            }
                                                      withCancelBlock:^(NSError *error) {
                                                          NSLog(@"error %@",error);
                                                      }];
}




@end
