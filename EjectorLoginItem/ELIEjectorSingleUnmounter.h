//
//  ELIEjectorSingleUnmounter.h
//  Ejector
//
//  Created by Chris Lundie on 04/Dec/2015.
//  Copyright © 2015 Chris Lundie. All rights reserved.
//

@class ELIEjectorSingleUnmounter;

@import Foundation;
@import DiskArbitration;

typedef void(^ELIEjectorSingleUnmounterCompletion)(NSError *, ELIEjectorSingleUnmounter *);

@interface ELIEjectorSingleUnmounter : NSObject

- (instancetype)initWithDisk:(DADiskRef)disk unmountOptions:(DADiskUnmountOptions)unmountOptions force:(BOOL)force completion:(ELIEjectorSingleUnmounterCompletion)completion;
- (instancetype)start;
- (instancetype)stop;

@end
