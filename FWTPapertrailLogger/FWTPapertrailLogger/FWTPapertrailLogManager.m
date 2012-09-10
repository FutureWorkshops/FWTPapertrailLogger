//
//  FWTPapertrailLogManager.m
//  FWTPapertrailLogger
//
//  Created by Matt Brooke-Smith on 10/09/2012.
//  Copyright (c) 2012 Matt Brooke-Smith. All rights reserved.
//

#import "FWTPapertrailLogManager.h"
#import <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>

static FWTPapertrailLogManager *sharedManager = nil;

@interface FWTPapertrailLogManager ()

@property (nonatomic, retain) NSMutableArray *logLines;
@property (nonatomic, retain) NSObject *lock;

@end

@implementation FWTPapertrailLogManager

+ (FWTPapertrailLogManager *) sharedManager
{
    if (!sharedManager){
        sharedManager = [[FWTPapertrailLogManager alloc] init];
    }
    return sharedManager;
}

- (void)dealloc
{
    [self stop];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.logLines = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        self.lock = [[[NSObject alloc] init] autorelease];
    }
    return self;
}

- (void) didReceiveMemoryWarning:(NSNotification *)notification {
    @synchronized(self.lock){
        [self.logLines removeAllObjects];
    }
}

- (void) start
{
    pipe = [NSPipe pipe];
    stderrWriteFileHandle = [pipe fileHandleForWriting];
    stderrReadFileHandle = [pipe fileHandleForReading];
    
    dup2([stderrWriteFileHandle fileDescriptor], STDERR_FILENO);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:NSFileHandleReadCompletionNotification object:stderrReadFileHandle];
    [stderrReadFileHandle readInBackgroundAndNotify];
}

- (void) stop
{
    [pipe release];
    pipe = nil;
    [stderrWriteFileHandle release];
    stderrWriteFileHandle = nil;
    [stderrReadFileHandle release];
    stderrReadFileHandle = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    @synchronized(self.lock){
        [self.logLines removeAllObjects];
    }
}

- (void)notificationReceived:(NSNotification *)notification
{
    [stderrReadFileHandle readInBackgroundAndNotify];
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSString *logMessage = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSUTF8StringEncoding];
    logMessage = [applicationName stringByAppendingFormat:@" %@", logMessage];
    
    @synchronized(self.lock){
        [self.logLines addObject:logMessage];
        
        //create the socket
        CFSocketRef socket;
        socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, 0, NULL, NULL);
        
        //convert logs.papertrailapp.com to an IP address
        struct hostent *hostname_to_ip = gethostbyname("logs.papertrailapp.com");
        
        if (hostname_to_ip != NULL){
            //create the sockaddr_in struct
            struct sockaddr_in addr;
            memset(&addr, 0, sizeof(addr));
            addr.sin_len = sizeof(addr);
            addr.sin_family = AF_INET;
            addr.sin_port = htons(self.port);
            
            //the following line is probably contrived but I am a C noob. sorry.
            inet_aton(inet_ntoa(* (struct in_addr *)hostname_to_ip->h_addr_list[0]), &addr.sin_addr);
            
            //convert the struct to a NSData object
            NSData *addrData = [NSData dataWithBytes:&addr length:sizeof(addr)];
            
            while ([self.logLines count] > 0){
                NSString *nextMessage = [self.logLines lastObject];
                int err = CFSocketSendData(socket, (CFDataRef)addrData, (CFDataRef)[nextMessage dataUsingEncoding:NSUTF8StringEncoding], 0);
                if (err)
                {
                    //handle the error
                }
                [self.logLines removeObject:nextMessage];
            }

        }
    }
    

}

@end
