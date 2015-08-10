//
//  EJEViewController.m
//  Ejector
//
//  Created by Chris Lundie on 08/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "EJEViewController.h"
@import DiskArbitration;

static void diskAppearedCallback(DADiskRef disk, void *context);
void stopDiskSession(DASessionRef diskSession, void *context);
static void diskDisappearedCallback(DADiskRef disk, void *context);
static void diskDescriptionChangedCallback(DADiskRef disk, CFArrayRef keys, void *context);

static void diskAppearedCallback(DADiskRef disk, void *context)
{
  NSDictionary *diskDescription = CFBridgingRelease(DADiskCopyDescription(disk));
  NSLog(@"%s\n%@", __PRETTY_FUNCTION__, diskDescription);
}

static void diskDisappearedCallback(DADiskRef disk, void *context)
{
  NSLog(@"%s", __PRETTY_FUNCTION__);
}

static void diskDescriptionChangedCallback(DADiskRef disk, CFArrayRef keys, void *context)
{
  NSLog(@"%s", __PRETTY_FUNCTION__);
}

void stopDiskSession(DASessionRef diskSession, void *context)
{
  if (!diskSession) {
    return;
  }
  DAUnregisterCallback(diskSession, diskAppearedCallback, context);
  DAUnregisterCallback(diskSession, diskDisappearedCallback, context);
  DASessionSetDispatchQueue(diskSession, NULL);
  CFRelease(diskSession);
}

@interface EJEViewController ()

@property (assign) DASessionRef diskSession;

@end

@implementation EJEViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)setRepresentedObject:(id)representedObject
{
  [super setRepresentedObject:representedObject];
  // Update the view, if already loaded.
}

- (void)viewDidAppear
{
  [super viewDidAppear];
  if (!self.diskSession) {
    DASessionRef diskSession = DASessionCreate(NULL);
    self.diskSession = diskSession;
    DASessionScheduleWithRunLoop(diskSession, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    DASessionSetDispatchQueue(diskSession, dispatch_get_main_queue());
    NSDictionary *diskFilter = @{
      (NSString *)kDADiskDescriptionMediaWholeKey: @NO,
      (NSString *)kDADiskDescriptionDeviceInternalKey: @NO,
      (NSString *)kDADiskDescriptionVolumeNetworkKey: @NO,
    };
    NSArray *diskWatch = @[
      (NSString *)kDADiskDescriptionDeviceInternalKey,
      (NSString *)kDADiskDescriptionVolumeNetworkKey,
      (NSString *)kDADiskDescriptionVolumeNameKey,
      (NSString *)kDADiskDescriptionMediaIconKey,
      (NSString *)kDADiskDescriptionMediaNameKey,
      (NSString *)kDADiskDescriptionMediaPathKey,
    ];
    DARegisterDiskAppearedCallback(diskSession, (__bridge CFDictionaryRef)(diskFilter), diskAppearedCallback, (__bridge void *)(self));
    DARegisterDiskDisappearedCallback(diskSession, (__bridge CFDictionaryRef)(diskFilter), diskDisappearedCallback, (__bridge void *)(self));
    DARegisterDiskDescriptionChangedCallback(diskSession, (__bridge CFDictionaryRef)(diskFilter), (__bridge CFArrayRef)(diskWatch), diskDescriptionChangedCallback, (__bridge void *)(self));
  }
}

- (void)viewWillDisappear
{
  DASessionRef diskSession = self.diskSession;
  self.diskSession = NULL;
  stopDiskSession(diskSession, (__bridge void *)(self));
}

@end
