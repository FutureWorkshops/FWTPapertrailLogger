//
//  FWTAppDelegate.m
//  FWTPapertrailLogger
//
//  Created by Matt Brooke-Smith on 10/09/2012.
//  Copyright (c) 2012 Matt Brooke-Smith. All rights reserved.
//

#import "FWTAppDelegate.h"
#import "FWTPapertrailLogManager.h"

@implementation FWTAppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [[FWTPapertrailLogManager sharedManager] setPort:64499];
    [[FWTPapertrailLogManager sharedManager] start];
    
   
    
    return YES;
}

- (void) applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"applicationDidBecomeActive"); 
}

@end
