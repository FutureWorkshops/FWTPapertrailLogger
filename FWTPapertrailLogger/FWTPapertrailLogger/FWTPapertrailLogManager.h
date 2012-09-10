//
//  FWTPapertrailLogManager.h
//  FWTPapertrailLogger
//
//  Created by Matt Brooke-Smith on 10/09/2012.
//  Copyright (c) 2012 Matt Brooke-Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FWTPapertrailLogManager : NSObject{
    NSPipe *pipe;
    NSFileHandle *stderrWriteFileHandle;
    NSFileHandle *stderrReadFileHandle;
}

@property (nonatomic, assign) NSInteger port;

+ (FWTPapertrailLogManager *) sharedManager;
- (void) start;

@end
