//
//  ELIEjectorSingleUnmounter.m
//  Ejector
//
//  Created by Chris Lundie on 04/Dec/2015.
//  Copyright © 2015 Chris Lundie. All rights reserved.
//

#import "ELIEjectorSingleUnmounter.h"
@import IOKit;

@interface ELIEjectorSingleUnmounter ()

@property (copy) ELIEjectorSingleUnmounterCompletion completion;
@property (strong) id disk;
@property (assign) BOOL force;
@property (assign) DADiskUnmountOptions unmountOptions;
@property (strong) id session;

@end

static void unmountCallback(DADiskRef disk, DADissenterRef dissenter, void *context);

static void unmountCallback(DADiskRef disk, DADissenterRef dissenter, void *context)
{
  ELIEjectorSingleUnmounter *singleUnmounter = (__bridge ELIEjectorSingleUnmounter *)(context);
  id session = singleUnmounter.session;
  ELIEjectorSingleUnmounterCompletion completion = singleUnmounter.completion;
  [singleUnmounter stop];
  if (!session || !completion) {
    return;
  }
  const char *diskName = DADiskGetBSDName(disk);
  if (!dissenter || (DADissenterGetStatus(dissenter) == kDAReturnSuccess)) {
    NSLog(@"%s Unmounted disk %s", __PRETTY_FUNCTION__, diskName);
    completion(nil, singleUnmounter);
  } else {
    NSString *errorMessage = (__bridge NSString *)DADissenterGetStatusString(dissenter);
    DAReturn status = DADissenterGetStatus(dissenter);
    NSLog(@"%s Cannot unmount disk %s; status=%x; errorMessage=%@", __PRETTY_FUNCTION__, diskName, status, errorMessage);
    completion([NSError errorWithDomain:@"" code:0 userInfo:@{}], singleUnmounter);
  }
}

@implementation ELIEjectorSingleUnmounter

- (instancetype)initWithDisk:(DADiskRef)disk unmountOptions:(DADiskUnmountOptions)unmountOptions force:(BOOL)force completion:(ELIEjectorSingleUnmounterCompletion)completion
{
  self = [super init];
  if (self) {
    io_service_t media = DADiskCopyIOMedia(disk);
    if (!media) {
      return nil;
    }
    id session = CFBridgingRelease(DASessionCreate(NULL));
    id diskCopy = CFBridgingRelease(DADiskCreateFromIOMedia(NULL, (DASessionRef)session, media));
    IOObjectRelease(media);
    if (!diskCopy) {
      return nil;
    }
    self.session = session;
    self.disk = diskCopy;
    self.unmountOptions = unmountOptions;
    self.force = force;
    self.completion = completion;
    DASessionSetDispatchQueue((DASessionRef)session, dispatch_get_main_queue());
  }
  return self;
}

- (void)dealloc
{
  id session = _session;
  if (session) {
    DASessionSetDispatchQueue((DASessionRef)session, NULL);
  }
}

- (instancetype)start
{
  DADiskUnmount((DADiskRef)self.disk, self.unmountOptions | (self.force ? kDADiskUnmountOptionForce : 0), unmountCallback, (__bridge void *)(self));
  return self;
}

- (instancetype)stop
{
  id session = self.session;
  self.session = nil;
  if (session) {
    DASessionSetDispatchQueue((DASessionRef)session, NULL);
  }
  self.completion = nil;
  return self;
}

@end
