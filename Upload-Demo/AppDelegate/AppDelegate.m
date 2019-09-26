//
//  AppDelegate.m
//  Upload-Demo
//
//  Created by Shrejas Chandel on 25/09/19.
//  Copyright © 2019 Shrejas Chandel. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Setup DropBox
    [DBClientsManager setupWithAppKey:dropBoxAppKey];
    
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    DBOAuthResult *authResult = [DBClientsManager handleRedirectURL:url];
    if (authResult != nil) {
        BOOL isLoggedIn = NO;
        if ([authResult isSuccess])
        {
            isLoggedIn = YES;
            NSLog(@"Success! User is logged into Dropbox.");
        }
        else if ([authResult isCancel])
        {
            isLoggedIn = NO;
            NSLog(@"Authorization flow was manually canceled by user!");
        }
        else if ([authResult isError])
        {
            isLoggedIn = NO;
            NSLog(@"Error: %@", authResult);
        }
        
        // Check if user logged into dropbox successfully and save it to locally
        [[NSUserDefaults standardUserDefaults] setBool:isLoggedIn forKey:iSUserLoggedIn];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:iSUserLoggedIn
                                                            object:nil];
    }
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Block to run code on main thread

void runOnMainThreadWithoutDeadlocking(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end
