//
//  ELIEjectorWorker.m
//  Ejector
//
//  Created by Chris Lundie on 18/Nov/2015.
//  Copyright © 2015 Chris Lundie. All rights reserved.
//

#import "ELIEjectorWorker.h"
#import "ELIEjectorGroup.h"
#import "../Shared/NSUserDefaults+EJESuite.h"

@import DiskArbitration;
@import IOKit;
@import IOKit.storage;

static const NSTimeInterval ejectTimerInterval = 10.0;

static CFArrayRef copyChildWholeDisks(DASessionRef session, DADiskRef parentDisk);
static DADiskRef copyRootWholeDisk(DASessionRef session, DADiskRef childDisk);
static CFArrayRef copyWholeDisks(DASessionRef session, DADiskRef disk);
static void notify(NSArray<NSError *> *errors);
static BOOL shouldNotify();

static CFArrayRef copyChildWholeDisks(DASessionRef session, DADiskRef parentDisk) {
  CFMutableArrayRef wholeDisks = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
  io_service_t parentMedia = DADiskCopyIOMedia(parentDisk);
  io_iterator_t iterator = 0;
  io_object_t nextObject = 0;
  if (KERN_SUCCESS != IORegistryEntryCreateIterator(parentMedia, kIOServicePlane, kIORegistryIterateRecursively, &iterator)) {
    goto cleanup;
  }
  if (!iterator) {
    goto cleanup;
  }
  while (1) {
    if (nextObject) {
      IOObjectRelease(nextObject);
    }
    nextObject = IOIteratorNext(iterator);
    if (nextObject) {
      if (IOObjectConformsTo(nextObject, kIOMediaClass)) {
        CFBooleanRef whole = IORegistryEntryCreateCFProperty(nextObject, CFSTR(kIOMediaWholeKey), NULL, 0);
        if (whole) {
          if (CFGetTypeID(whole) == CFBooleanGetTypeID() && CFBooleanGetValue(whole)) {
            NSLog(@"%s found whole disk", __PRETTY_FUNCTION__);
            DADiskRef wholeDisk = DADiskCreateFromIOMedia(NULL, session, nextObject);
            if (wholeDisks) {
              CFArrayAppendValue(wholeDisks, wholeDisk);
              CFRelease(wholeDisk);
            }
            CFMutableDictionaryRef dict = NULL;
            if (KERN_SUCCESS == IORegistryEntryCreateCFProperties(nextObject, &dict, NULL, 0)) {
              if (dict) {
                NSLog(@"%s %@", __PRETTY_FUNCTION__, (__bridge NSDictionary *)dict);
                CFRelease(dict);
              }
            }
          }
          CFRelease(whole);
        }
      }
    } else {
      break;
    }
  }
cleanup:
  if (nextObject) {
    IOObjectRelease(nextObject);
  }
  if (iterator) {
    IOObjectRelease(iterator);
  }
  if (parentMedia) {
    IOObjectRelease(parentMedia);
  }
  return wholeDisks;
}

static DADiskRef copyRootWholeDisk(DASessionRef session, DADiskRef childDisk) {
  DADiskRef parentDisk = NULL;
  io_registry_entry_t nextEntry = 0;
  io_service_t topMedia = DADiskCopyIOMedia(childDisk);
  if (!topMedia) {
    goto cleanup;
  }
  IOObjectRetain(topMedia);
  nextEntry = topMedia;
  while (nextEntry) {
    {
      io_registry_entry_t newNextEntry;
      if (KERN_SUCCESS != IORegistryEntryGetParentEntry(nextEntry, kIOServicePlane, &newNextEntry)) {
        break;
      }
      if (!newNextEntry) {
        break;
      }
      IOObjectRelease(nextEntry);
      nextEntry = newNextEntry;
    }
    if (IOObjectConformsTo(nextEntry, kIOMediaClass)) {
      CFBooleanRef whole = IORegistryEntryCreateCFProperty(nextEntry, CFSTR(kIOMediaWholeKey), NULL, 0);
      if (whole) {
        if (CFGetTypeID(whole) == CFBooleanGetTypeID() && CFBooleanGetValue(whole)) {
          if (topMedia) {
            IOObjectRelease(topMedia);
          }
          IOObjectRetain(nextEntry);
          topMedia = nextEntry;
        }
        CFRelease(whole);
      }
    }
  }
  if (!topMedia) {
    goto cleanup;
  }
  parentDisk = DADiskCreateFromIOMedia(NULL, session, topMedia);
cleanup:
  if (nextEntry) {
    IOObjectRelease(nextEntry);
  }
  if (topMedia) {
    IOObjectRelease(topMedia);
  }
  return parentDisk;
}

static CFArrayRef copyWholeDisks(DASessionRef session, DADiskRef disk) {
  CFMutableArrayRef wholeDisks = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
  DADiskRef root = copyRootWholeDisk(session, disk);
  if (root) {
    CFArrayAppendValue(wholeDisks, root);
    CFArrayRef children = copyChildWholeDisks(session, root);
    if (children) {
      CFArrayAppendArray(wholeDisks, children, CFRangeMake(0, CFArrayGetCount(children)));
      CFRelease(children);
    }
  }
  return wholeDisks;
}

static void notify(NSArray<NSError *> *errors) {
  NSLog(@"%s errors=%@", __PRETTY_FUNCTION__, errors);
  BOOL didSucceed = [errors count] == 0;
  NSUserNotification *notification = [[NSUserNotification alloc] init];
  notification.title = didSucceed ? @"Ejected Time Machine disk" : @"Failed to eject Time Machine disk";
  notification.informativeText = didSucceed ? nil : @"Another app may have an open file on this disk.";
  notification.identifier = @"ca.lundie.EjectorLoginItem.DefaultNotification";
  notification.hasActionButton = NO;
  NSUserNotificationCenter *nc = [NSUserNotificationCenter defaultUserNotificationCenter];
  [nc removeAllDeliveredNotifications];
  [nc deliverNotification:notification];
}

static BOOL shouldNotify() {
  return [[NSUserDefaults eje_sharedSuite] boolForKey:@"NotificationsEnabled"];
}

@interface ELIEjectorWorker ()

@property (copy) NSArray<id> *backupdObservers;
@property (strong) NSTimer *ejectTimer;
@property (copy) NSURL *volumeToEject;
@property (strong) NSMutableArray<ELIEjectorGroup *> *ejectorGroups;

@end

@implementation ELIEjectorWorker

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.ejectorGroups = [NSMutableArray array];
  }
  return self;
}

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
  id partition = nil;
  NSArray *disksToEject = nil;
  NSDictionary *partitionDescription;
  DADiskUnmountOptions unmountOptions;
  id diskSession = CFBridgingRelease(DASessionCreate(NULL));
  if (!diskSession) {
    return NO;
  }
  partition = CFBridgingRelease(DADiskCreateFromVolumePath(NULL, (__bridge DASessionRef)diskSession, (CFURLRef)volumeURL));
  if (!partition) {
    NSLog(@"%s Cannot get partition from volume=%@", __PRETTY_FUNCTION__, [volumeURL absoluteString]);
    return NO;
  }
  partitionDescription = CFBridgingRelease(DADiskCopyDescription((DADiskRef)partition));
  if ([partitionDescription[(NSString *)kDADiskDescriptionVolumeNetworkKey] boolValue]) {
    NSLog(@"%s Volume %@ is network", __PRETTY_FUNCTION__, [volumeURL absoluteString]);
    disksToEject = @[partition];
    unmountOptions = kDADiskUnmountOptionDefault;
  } else {
    unmountOptions = kDADiskUnmountOptionWhole;
    NSArray *wholeDisks = CFBridgingRelease(copyWholeDisks((__bridge DASessionRef)diskSession, (__bridge DADiskRef)partition));
    if (NSNotFound == [wholeDisks indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      return [((NSDictionary *)CFBridgingRelease(DADiskCopyDescription((DADiskRef)obj)))[(NSString *)kDADiskDescriptionDeviceInternalKey] boolValue];
    }]) {
      disksToEject = [wholeDisks copy];
    } else {
      NSLog(@"%s Volume is on an internal disk %@", __PRETTY_FUNCTION__, [volumeURL absoluteString]);
    }
  }
  NSLog(@"%s disksToEject:", __PRETTY_FUNCTION__);
  for (id diskToEject in disksToEject) {
    NSDictionary *description = CFBridgingRelease(DADiskCopyDescription((DADiskRef)diskToEject));
    NSLog(@"%@", description);
  }
  if (![disksToEject count]) {
    NSLog(@"No disks to eject from volume=%@", [volumeURL absoluteString]);
    return NO;
  }
  if (!test) {
    __weak typeof(self) weakSelf = self;
    BOOL force = [[NSUserDefaults eje_sharedSuite] boolForKey:@"ForceEject"];
    ELIEjectorGroup *group = [[ELIEjectorGroup alloc] initWithDisks:disksToEject unmountOptions:unmountOptions force:force completion:^(NSArray<NSError *> *errors, ELIEjectorGroup *ejectorGroup) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      [strongSelf.ejectorGroups removeObject:ejectorGroup];
      if (shouldNotify()) {
        notify(errors);
      }
    }];
    [self.ejectorGroups addObject:group];
    [group start];
  }
  return YES;
}

- (instancetype)start
{
  NSLog(@"Starting");
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
  for (ELIEjectorGroup *group in self.ejectorGroups) {
    [group stop];
  }
  [self.ejectorGroups removeAllObjects];
  self.ejectorGroups = nil;
  for (id backupdObserver in self.backupdObservers) {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:backupdObserver];
  }
  self.backupdObservers = nil;
  [self descheduleEject];
}

@end
