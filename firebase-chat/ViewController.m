//
//  ViewController.m
//  firebase-chat
//
//  Created by mugicha on 2015/07/15.
//  Copyright © 2015年 mugicha. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    messageView * _messageView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _messageView = [[messageView alloc] init];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:_messageView.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
