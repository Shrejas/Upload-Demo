//
//  AppDelegate.h
//  Upload-Demo
//
//  Created by Shrejas Chandel on 24/09/19.
//  Copyright © 2019 Shrejas Chandel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

void runOnMainThreadWithoutDeadlocking(void (^block)(void));

@end

