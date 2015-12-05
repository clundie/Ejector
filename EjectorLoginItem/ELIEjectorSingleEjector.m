//
//  ELIEjectorSingleEjector.m
//  Ejector
//
//  Created by Chris Lundie on 05/Dec/2015.
//  Copyright © 2015 Chris Lundie. All rights reserved.
//

#import "ELIEjectorSingleEjector.h"
@import IOKit;

@interface ELIEjectorSingleEjector ()

@property (copy) ELIEjectorSingleEjectorCompletion completion;
@property (strong) id disk;
@property (strong) id session;

@end

static void ejectCallback(DADiskRef disk, DADissenterRef dissenter, void *context);

static void ejectCallback(DADiskRef disk, DADissenterRef dissenter, void *context)
{
  ELIEjectorSingleEjector *singleEjector = (__bridge ELIEjectorSingleEjector *)(context);
  id session = singleEjector.session;
  ELIEjectorSingleEjectorCompletion completion = singleEjector.completion;
  [singleEjector stop];
  if (!session || !completion) {
    return;
  }
  const char *diskName = DADiskGetBSDName(disk);
  if (!dissenter || (DADissenterGetStatus(dissenter) == kDAReturnSuccess)) {
    NSLog(@"%s Ejected disk %s", __PRETTY_FUNCTION__, diskName);
    completion(nil, singleEjector);
  } else {
    NSString *errorMessage = (__bridge NSString *)DADissenterGetStatusString(dissenter);
    DAReturn status = DADissenterGetStatus(dissenter);
    NSLog(@"%s Cannot eject disk %s; status=%x; errorMessage=%@", __PRETTY_FUNCTION__, diskName, status, errorMessage);
    completion([NSError errorWithDomain:@"" code:0 userInfo:@{}], singleEjector);
  }
}

@implementation ELIEjectorSingleEjector

- (instancetype)initWithDisk:(DADiskRef)disk completion:(ELIEjectorSingleEjectorCompletion)completion
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
  DADiskEject((DADiskRef)self.disk, kDADiskEjectOptionDefault, ejectCallback, (__bridge void *)self);
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
