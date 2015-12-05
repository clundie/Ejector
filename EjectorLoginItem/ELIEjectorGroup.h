//
//  ELIEjectorGroup.h
//  Ejector
//
//  Created by Chris Lundie on 02/Dec/2015.
//  Copyright © 2015 Chris Lundie. All rights reserved.
//

@class ELIEjectorGroup;

@import Foundation;
@import DiskArbitration;

typedef void(^ELIEjectorGroupCompletion)(NSArray<NSError *> *, ELIEjectorGroup *);

@interface ELIEjectorGroup : NSObject

- (instancetype)initWithDisks:(NSArray *)disks unmountOptions:(DADiskUnmountOptions)unmountOptions force:(BOOL)force completion:(ELIEjectorGroupCompletion)completion;
- (instancetype)start;
- (instancetype)stop;

@end
