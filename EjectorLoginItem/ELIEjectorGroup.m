//
//  ELIEjectorGroup.m
//  Ejector
//
//  Created by Chris Lundie on 02/Dec/2015.
//  Copyright © 2015 Chris Lundie. All rights reserved.
//

#import "ELIEjectorGroup.h"
#import "ELIEjectorSingleUnmounter.h"
#import "ELIEjectorSingleEjector.h"
@import IOKit;
@import IOKit.storage;

static const NSTimeInterval TIMEOUT_INTERVAL = 60.0;

NSString * const ELIEjectorGroupErrorDomain = @"ELIEjectorGroupErrorDomain";
const NSInteger ELIEjectorGroupErrorTimeout = 1;

@interface ELIEjectorGroup ()

@property (copy) ELIEjectorGroupCompletion completion;
@property (copy) NSArray *disks;
@property (assign) BOOL force;
@property (assign) DADiskUnmountOptions unmountOptions;
@property (strong) NSMutableArray<ELIEjectorSingleUnmounter *> *singleUnmounters;
@property (strong) NSMutableArray<ELIEjectorSingleEjector *> *singleEjectors;
@property (strong) NSTimer *timeoutTimer;
@property (strong) NSMutableArray<NSError *> *errors;

@end

@implementation ELIEjectorGroup

- (instancetype)initWithDisks:(NSArray *)disks unmountOptions:(DADiskUnmountOptions)unmountOptions force:(BOOL)force completion:(ELIEjectorGroupCompletion)completion
{
  self = [super init];
  if (self) {
    self.completion = completion;
    self.disks = disks;
    self.unmountOptions = unmountOptions;
    self.force = force;
    self.singleUnmounters = [NSMutableArray array];
    self.singleEjectors = [NSMutableArray array];
    self.errors = [NSMutableArray array];
  }
  return self;
}

- (instancetype)stop
{
  [self.timeoutTimer invalidate];
  self.timeoutTimer = nil;
  self.completion = nil;
  for (ELIEjectorSingleUnmounter *singleUnmounter in [self.singleUnmounters copy]) {
    [singleUnmounter stop];
  }
  [self.singleUnmounters removeAllObjects];
  for (ELIEjectorSingleEjector *singleEjector in [self.singleEjectors copy]) {
    [singleEjector stop];
  }
  [self.singleEjectors removeAllObjects];
  return self;
}

- (instancetype)start
{
  __weak typeof(self) weakSelf = self;
  for (id disk in self.disks) {

    ELIEjectorSingleUnmounter *singleUnmounter = [[ELIEjectorSingleUnmounter alloc] initWithDisk:(DADiskRef)disk unmountOptions:self.unmountOptions force:self.force completion:^(NSError *unmountError, ELIEjectorSingleUnmounter *_singleUnmounter) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      ELIEjectorGroupCompletion completion = strongSelf.completion;
      if (!strongSelf || !completion) {
        return;
      }
      NSMutableArray<ELIEjectorSingleUnmounter *> *singleUnmounters = strongSelf.singleUnmounters;
      [singleUnmounters removeObject:_singleUnmounter];
      if (unmountError) {
        [strongSelf.errors addObject:[unmountError copy]];
        NSArray<NSError *> *errors = [strongSelf.errors copy];
        [strongSelf stop];
        completion(errors, strongSelf);
      } else {
        if (![singleUnmounters count]) {
          NSArray<ELIEjectorSingleEjector *> *singleEjectors = [strongSelf.singleEjectors copy];
          if ([singleEjectors count]) {
            for (ELIEjectorSingleEjector *ejector in singleEjectors) {
              [ejector start];
            }
          } else {
            NSArray<NSError *> *errors = [strongSelf.errors copy];
            [strongSelf stop];
            completion(errors, strongSelf);
          }
        }
      }
    }];
    [self.singleUnmounters addObject:singleUnmounter];

    NSDictionary<NSString *, id> *diskDescription = CFBridgingRelease(DADiskCopyDescription((DADiskRef)disk));
    BOOL isLeaf = [((NSNumber *)(diskDescription[(NSString *)kDADiskDescriptionMediaLeafKey])) boolValue];
    if (!isLeaf) {
      ELIEjectorSingleEjector *ejector = [[ELIEjectorSingleEjector alloc] initWithDisk:(DADiskRef)disk completion:^(NSError *ejectError, ELIEjectorSingleEjector *_ejector) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        ELIEjectorGroupCompletion completion = strongSelf.completion;
        if (!strongSelf || !completion) {
          return;
        }
        NSMutableArray<ELIEjectorSingleEjector *> *singleEjectors = strongSelf.singleEjectors;
        [singleEjectors removeObject:_ejector];
        if (ejectError) {
          [strongSelf.errors addObject:[ejectError copy]];
          NSArray<NSError *> *errors = [strongSelf.errors copy];
          [strongSelf stop];
          completion(errors, strongSelf);
        } else {
          if (![singleEjectors count]) {
            NSArray<NSError *> *errors = [strongSelf.errors copy];
            [strongSelf stop];
            completion(errors, strongSelf);
          }
        }
      }];
      [self.singleEjectors addObject:ejector];
    }

  }
  self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_INTERVAL target:self selector:@selector(timeoutTimerDidFire:) userInfo:nil repeats:NO];
  for (ELIEjectorSingleUnmounter *singleUnmounter in [self.singleUnmounters copy]) {
    [singleUnmounter start];
  }
  return self;
}

- (void)timeoutTimerDidFire:(NSTimer *)timer
{
  ELIEjectorGroupCompletion completion = self.completion;
  [self stop];
  if (!completion) {
    return;
  }
  completion(@[[NSError errorWithDomain:ELIEjectorGroupErrorDomain code:ELIEjectorGroupErrorTimeout userInfo:@{NSLocalizedDescriptionKey: @"Timed out"}]], self);
}

@end
