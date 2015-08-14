//
//  EJEAppDelegate.m
//  Ejector
//
//  Created by Chris Lundie on 08/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "EJEAppDelegate.h"
#import "EJELoginItemEnabler.h"
#import "EJESettingsSaver.h"
#import <stdio.h>
@import DiskArbitration;

static void unmountCallback(DADiskRef disk, DADissenterRef dissenter, void * context);
static void ejectCallback(DADiskRef disk, DADissenterRef dissenter, void * context);

static void unmountCallback(DADiskRef disk, DADissenterRef dissenter, void * context)
{
  if (!dissenter) {
    DADiskEject(disk, kDADiskEjectOptionDefault, ejectCallback, NULL);
  }
}

static void ejectCallback(DADiskRef disk, DADissenterRef dissenter, void * context)
{
}

@interface EJEAppDelegate ()

@property EJELoginItemEnabler *loginItemEnabler;
@property EJESettingsSaver *settingsSaver;

@end

@implementation EJEAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.loginItemEnabler = [[[EJELoginItemEnabler alloc] init] watchUserDefaults];
  self.settingsSaver = [[[EJESettingsSaver alloc] init] watchUserDefaults];
  NSArray *resourceKeys = @[NSURLEffectiveIconKey, NSURLLocalizedNameKey, NSURLNameKey];
  NSFileManager *manager = [NSFileManager defaultManager];
  NSURL *oldVolumeURL = nil;
  {
    NSData *oldVolumeBookmark = [[NSUserDefaults standardUserDefaults] dataForKey:@"VolumeBookmark"];
    if (oldVolumeBookmark && [oldVolumeBookmark length]) {
      BOOL isStale = NO;
      NSError *error = nil;
      NSDictionary *bookmarkResourceValues = [NSURL resourceValuesForKeys:resourceKeys fromBookmarkData:oldVolumeBookmark];
      NSLog(@"Bookmark resource values=%@", bookmarkResourceValues);
      oldVolumeURL = [[NSURL alloc] initByResolvingBookmarkData:oldVolumeBookmark options:(NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting) relativeToURL:nil bookmarkDataIsStale:&isStale error:&error];
      if (!oldVolumeURL) {
        NSLog(@"Cannot resolve bookmark, error=%@", error);
      }
    }
  }
  NSLog(@"oldVolumeURL=%@", [oldVolumeURL absoluteString]);
  NSArray *volumeURLs = [manager mountedVolumeURLsIncludingResourceValuesForKeys:resourceKeys options:NSVolumeEnumerationSkipHiddenVolumes];
  DASessionRef diskSession = DASessionCreate(NULL);
  DASessionSetDispatchQueue(diskSession, dispatch_get_main_queue());
  for (NSURL *volumeURL in volumeURLs) {
    DADiskRef partition = NULL;
    DADiskRef disk = NULL;
    NSDictionary *partitionDescription;
    NSDictionary *diskDescription;
    NSData *volumeBookmark;
    DADiskUnmountOptions unmountOptions;
    NSError *error = nil;
    NSDictionary *resourceValues = [volumeURL resourceValuesForKeys:resourceKeys error:&error];
    partition = DADiskCreateFromVolumePath(NULL, diskSession, (__bridge CFURLRef)volumeURL);
    if (!partition) {
      goto cleanup;
    }
    partitionDescription = CFBridgingRelease(DADiskCopyDescription(partition));
    if ([partitionDescription[(NSString *)kDADiskDescriptionVolumeNetworkKey] boolValue]) {
      disk = (DADiskRef)CFRetain(partition);
      unmountOptions = kDADiskUnmountOptionDefault;
    } else {
      disk = DADiskCopyWholeDisk(partition);
      unmountOptions = kDADiskUnmountOptionWhole;
    }
    if (!disk) {
      goto cleanup;
    }
    diskDescription = CFBridgingRelease(DADiskCopyDescription(disk));
    NSLog(@"%@\n%@", resourceValues, diskDescription);
    if (
      [diskDescription[(NSString *)kDADiskDescriptionDeviceInternalKey] boolValue]
      ) {
      NSLog(@"will not unmount %@", volumeURL);
      goto cleanup;
    }
    NSLog(@"will unmount %@", volumeURL);
    error = nil;
    volumeBookmark = [volumeURL bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile includingResourceValuesForKeys:resourceKeys relativeToURL:nil error:&error];
    if (volumeBookmark && [volumeBookmark length]) {
      [[NSUserDefaults standardUserDefaults] setObject:volumeBookmark forKey:@"VolumeBookmark"];
    }
    DADiskUnmount(disk, unmountOptions, unmountCallback, NULL);
cleanup:
    if (disk) {
      CFRelease(disk);
    }
    if (partition) {
      CFRelease(partition);
    }
  }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
  return YES;
}

@end
