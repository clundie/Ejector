//
//  ELIEjectorWorker.m
//  Ejector
//
//  Created by Chris Lundie on 18/Nov/2015.
//  Copyright © 2015 Chris Lundie. All rights reserved.
//

#import "ELIEjectorWorker.h"

@import DiskArbitration;

typedef __attribute__((NSObject)) DASessionRef RetainedDASessionRef;

static const NSTimeInterval ejectTimerInterval = 10.0;

static void ejectCallback(DADiskRef disk, DADissenterRef dissenter, void *context);
static void unmountCallback(DADiskRef disk, DADissenterRef dissenter, void *context);

static void ejectCallback(DADiskRef disk, DADissenterRef dissenter, void *context)
{
  const char *diskName = DADiskGetBSDName(disk);
  if (!dissenter || (DADissenterGetStatus(dissenter) == kDAReturnSuccess)) {
    NSLog(@"Ejected disk %s", diskName);
  } else {
    NSString *errorMessage = (__bridge NSString *)DADissenterGetStatusString(dissenter);
    DAReturn status = DADissenterGetStatus(dissenter);
    NSLog(@"Cannot eject disk %s; status=%x; errorMessage=%@", diskName, status, errorMessage);
  }
}

static void unmountCallback(DADiskRef disk, DADissenterRef dissenter, void *context)
{
  const char *diskName = DADiskGetBSDName(disk);
  if (!dissenter || (DADissenterGetStatus(dissenter) == kDAReturnSuccess)) {
    NSLog(@"Unmounted disk %s; trying to eject", diskName);
    DADiskEject(disk, kDADiskEjectOptionDefault, ejectCallback, NULL);
  } else {
    NSString *errorMessage = (__bridge NSString *)DADissenterGetStatusString(dissenter);
    DAReturn status = DADissenterGetStatus(dissenter);
    NSLog(@"Cannot unmount disk %s; status=%x; errorMessage=%@", diskName, status, errorMessage);
  }
}

@interface ELIEjectorWorker ()

@property (copy) NSArray<id> *backupdObservers;
@property (strong) RetainedDASessionRef diskSession;
@property (strong) NSTimer *ejectTimer;
@property (copy) NSURL *volumeToEject;

@end

@implementation ELIEjectorWorker

- (void)scheduleEject
{
  [self descheduleEject];
  self.ejectTimer = [NSTimer scheduledTimerWithTimeInterval:ejectTimerInterval target:self selector:@selector(ejectTimerDidFire:) userInfo:nil repeats:NO];
}

- (void)descheduleEject
{
  [self.ejectTimer invalidate];
  self.ejectTimer = nil;
}

- (void)ejectTimerDidFire:(NSTimer *)timer
{
  self.ejectTimer = nil;
  NSURL *volumeToEject = self.volumeToEject;
  self.volumeToEject = nil;
  if (volumeToEject) {
    [self ejectVolume:volumeToEject test:NO];
  }
}

- (BOOL)ejectVolume:(NSURL *)volumeURL test:(BOOL)test
{
  BOOL willEject = NO;
  DADiskRef partition = NULL;
  DADiskRef disk = NULL;
  NSDictionary *partitionDescription;
  NSDictionary *diskDescription;
  DADiskUnmountOptions unmountOptions;
  RetainedDASessionRef diskSession = self.diskSession;
  if (!diskSession) {
    goto cleanup;
  }
  partition = DADiskCreateFromVolumePath(NULL, diskSession, (__bridge CFURLRef)volumeURL);
  if (!partition) {
    NSLog(@"Cannot get partition from volume=%@", [volumeURL absoluteString]);
    goto cleanup;
  }
  partitionDescription = CFBridgingRelease(DADiskCopyDescription(partition));
  if ([partitionDescription[(NSString *)kDADiskDescriptionVolumeNetworkKey] boolValue]) {
    NSLog(@"Volume %@ is network", [volumeURL absoluteString]);
    disk = (DADiskRef)CFRetain(partition);
    unmountOptions = kDADiskUnmountOptionDefault;
  } else {
    disk = DADiskCopyWholeDisk(partition);
    unmountOptions = kDADiskUnmountOptionWhole;
  }
  if (!disk) {
    NSLog(@"Cannot get disk from volume=%@", [volumeURL absoluteString]);
    goto cleanup;
  }
  diskDescription = CFBridgingRelease(DADiskCopyDescription(disk));
  if (
      [diskDescription[(NSString *)kDADiskDescriptionDeviceInternalKey] boolValue]
      ) {
    NSLog(@"Disk %@ is internal; will not eject", [volumeURL absoluteString]);
    goto cleanup;
  }
  willEject = YES;
  if (!test) {
    NSLog(@"Trying to unmount %@", [volumeURL absoluteString]);
    DADiskUnmount(disk, unmountOptions, unmountCallback, NULL);
  }
  cleanup:
  if (disk) {
    CFRelease(disk);
  }
  if (partition) {
    CFRelease(partition);
  }
  return willEject;
}

- (instancetype)start
{
  NSLog(@"Starting");
  DASessionRef diskSession = DASessionCreate(NULL);
  self.diskSession = diskSession;
  DASessionSetDispatchQueue(diskSession, dispatch_get_main_queue());
  CFRelease(diskSession);
  // com.apple.backupd.DestinationMountNotification
  // DestinationMountPoint = "/Volumes/{XXX}"
  // When: backup starts.

  // com.apple.backupd.NewSystemBackupAvailableNotification
  // LatestBackupPath = "/Volumes/{XXX}/Backups.backupdb/x/x"
  // When: immediately after backup completes but before thinning.

  // com.apple.backupd.thinningbackup
  // BackupPath = "/Volumes/{XXX}/Backups.backupdb/x/x.inProgress"
  // When: "cleaning up" starts. Usually immediately after backup completes.
  // We don't want to eject while thinning is in progress.

  // com.apple.backupd.thinningbackupended
  // BackupPath = "/Volumes/{XXX}/Backups.backupdb/x/x.inProgress"
  // Error = 0
  // When: "cleaning up" ends. It should be safe to eject.
  NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
  NSString *object = @"com.apple.backupd";
  self.backupdObservers = @[
    [dnc addObserverForName:@"com.apple.backupd.NewSystemBackupAvailableNotification" object:object queue:nil usingBlock:^(NSNotification * _Nonnull note) {
      NSLog(@"Backup completed; determining if its disk should be ejected");
      NSString *path = [note userInfo][@"LatestBackupPath"];
      if ([path isKindOfClass:[NSString class]]) {
        NSError *error = nil;
        NSURL *volumeURL = nil;
        if ([[[NSURL alloc] initFileURLWithPath:path] getResourceValue:&volumeURL forKey:NSURLVolumeURLKey error:&error]) {
          NSLog(@"Backup volume=%@", [volumeURL absoluteString]);
          if ([self ejectVolume:volumeURL test:YES]) {
            NSLog(@"Scheduling eject of volume=%@", [volumeURL absoluteString]);
            self.volumeToEject = volumeURL;
            [self scheduleEject];
          }
        } else {
          NSLog(@"Ignoring backup; cannot get volume from path=%@", path);
        }
      } else {
        NSLog(@"Ignoring backup; cannot get path");
      }
    }],

    [dnc addObserverForName:@"com.apple.backupd.thinningbackup" object:object queue:nil usingBlock:^(NSNotification * _Nonnull note) {
      if (self.ejectTimer) {
        NSLog(@"Backup is thinning; will wait to eject");
        [self descheduleEject];
      }
    }],

    [dnc addObserverForName:@"com.apple.backupd.thinningbackupended" object:object queue:nil usingBlock:^(NSNotification * _Nonnull note) {
      if (self.volumeToEject) {
        NSLog(@"Backup thinning complete; scheduling eject of volume=%@", [self.volumeToEject absoluteString]);
        [self scheduleEject];
      }
    }],
  ];
  return self;
}

- (void)stop
{
  NSLog(@"Stopping");
  for (id backupdObserver in self.backupdObservers) {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:backupdObserver];
  }
  self.backupdObservers = nil;
  [self descheduleEject];
  RetainedDASessionRef diskSession = self.diskSession;
  if (diskSession) {
    DASessionSetDispatchQueue(diskSession, NULL);
  }
  self.diskSession = nil;
}

@end
