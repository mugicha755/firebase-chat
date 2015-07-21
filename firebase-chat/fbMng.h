//
//  fbMng.h
//  firebase-chat
//
//  Created by mugicha on 2015/07/15.
//  Copyright © 2015年 mugicha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface fbMng : NSObject

-(id)initWithId:(NSString *)userID
            bot:(NSString *)botID
       observer:(id)setObsever
       callback:(SEL)callback;

-(void)setFbValue:(id)newRecode
         withPath:(NSString *)pPath;

-(void)setFbValue:(id)newRecode;

-(void) reqMessageQuery:(SEL)callback
               observer:(id)setObsever;


@end
