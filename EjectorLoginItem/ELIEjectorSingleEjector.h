//
//  ELIEjectorSingleEjector.h
//  Ejector
//
//  Created by Chris Lundie on 05/Dec/2015.
//  Copyright © 2015 Chris Lundie. All rights reserved.
//

@class ELIEjectorSingleEjector;

@import Foundation;
@import DiskArbitration;

typedef void(^ELIEjectorSingleEjectorCompletion)(NSError *, ELIEjectorSingleEjector *);

@interface ELIEjectorSingleEjector : NSObject

- (instancetype)initWithDisk:(DADiskRef)disk completion:(ELIEjectorSingleEjectorCompletion)completion;
- (instancetype)start;
- (instancetype)stop;

@end
