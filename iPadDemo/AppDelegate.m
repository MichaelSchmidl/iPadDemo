//
//  AppDelegate.m
//  iPadDemo
//
//  Created by Michael Schmidl on 23.09.14.
//  Copyright (c) 2014 Michael Schmidl. All rights reserved.
//

#import "AppDelegate.h"
#import "TestFlight.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // start of your application:didFinishLaunchingWithOptions // ...
    [TestFlight takeOff:@"a76da106-1507-4365-ac94-e773e20d8c42"];
    
    // be sure these defaults are consistant of what is defined in the PLIST as defaults
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"ON",                              @"ON_command_preference",
                                 @"OFF",                             @"OFF_command_preference",
                                 @"13",                              @"EOL_character_preference",
                                 @"Reader is ACTIVE",                @"ReaderPower_ON_preference",
                                 @"Reader is OFF",                   @"ReaderPower_OFF_preference",
                                 @"-- no reader connected --",       @"NoReader_preference",
                                 @"k1",                              @"HIDON_command_preference",
                                 @"k0",                              @"HIDOFF_command_preference",
                                 @"Keyboard Wedge (81 Series Mode)", @"HID_ON_preference",
                                 @"SDK (82 Series Mode)",            @"HID_OFF_preference",
                                 @"GI",                              @"GI_command_preference",
                                 
                                 nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    // register to be notified if the settings change
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(defaultsChanged:)
                   name:NSUserDefaultsDidChangeNotification
                 object:nil];
    
    // at startup handle all default values as if they have changed
    [self defaultsChanged:application];

    // now set the actual app version and buildnr into the settings menu
    NSString *buildnr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *appVersion = [NSString stringWithFormat:@"%@.%@", version, buildnr];
    NSLog(@"AppVersion=%@", appVersion);
    [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"AppVersion_preference"];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// called at initial startup or when defaults get changed by the user
- (void) defaultsChanged:(UIApplication *)application
{
    UIApplication *thisApp = [UIApplication sharedApplication];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"disable_screen_saver_preference"])
    {
        NSLog(@"disable screen saver");
        thisApp.idleTimerDisabled = YES;
    }
    else
    {
        NSLog(@"enable screen saver");
        thisApp.idleTimerDisabled = NO;
    }
    
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"OFF_command_preference"]);
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"ON_command_preference"]);
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"EOL_character_preference"]);
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"ReaderPower_ON_preference"]);
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"ReaderPower_OFF_preference"]);
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"NoReader_preference"]);
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"HIDON_command_preference"]);
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"HIDOFF_command_preference"]);
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"HID_ON_preference"]);
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"HID_OFF_preference"]);
}

@end
