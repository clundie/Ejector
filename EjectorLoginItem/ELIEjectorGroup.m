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

@interface ELIEjectorGroup ()

@property (copy) ELIEjectorGroupCompletion completion;
@property (copy) NSArray *disks;
@property (assign) BOOL force;
@property (assign) DADiskUnmountOptions unmountOptions;
@property (strong) NSMutableArray<ELIEjectorSingleUnmounter *> *singleUnmounters;
@property (strong) NSMutableArray<ELIEjectorSingleEjector *> *singleEjectors;
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
  for (id disk in self.disks) {
    NSDictionary *diskDescription = CFBridgingRelease(DADiskCopyDescription((DADiskRef)disk));
    BOOL isLeaf = [((NSNumber *)(diskDescription[(NSString *)kDADiskDescriptionMediaLeafKey])) boolValue];
    if (!isLeaf) {
      __weak typeof(self) weakSelf = self;
      ELIEjectorSingleEjector *ejector = [[ELIEjectorSingleEjector alloc] initWithDisk:(DADiskRef)disk completion:^(NSError *error, ELIEjectorSingleEjector *_ejector) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        ELIEjectorGroupCompletion completion = strongSelf.completion;
        if (!strongSelf || !completion) {
          return;
        }
        if (error) {
          [strongSelf.errors addObject:[error copy]];
        }
        NSMutableArray *singleEjectors = strongSelf.singleEjectors;
        NSArray<NSError *> *errors = [strongSelf.errors copy];
        [singleEjectors removeObject:_ejector];
        if (![singleEjectors count]) {
          [strongSelf stop];
          completion(errors, strongSelf);
        }
      }];
      [self.singleEjectors addObject:ejector];
    }
    __weak typeof(self) weakSelf = self;
    ELIEjectorSingleUnmounter *singleUnmounter = [[ELIEjectorSingleUnmounter alloc] initWithDisk:(DADiskRef)disk unmountOptions:self.unmountOptions force:self.force completion:^(NSError *error, ELIEjectorSingleUnmounter *_singleUnmounter) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      ELIEjectorGroupCompletion completion = strongSelf.completion;
      if (!strongSelf || !completion) {
        return;
      }
      if (error) {
        [strongSelf.errors addObject:[error copy]];
      }
      NSMutableArray *singleUnmounters = strongSelf.singleUnmounters;
      NSArray<NSError *> *errors = [strongSelf.errors copy];
      [singleUnmounters removeObject:_singleUnmounter];
      if (![singleUnmounters count]) {
        if ([self.singleEjectors count]) {
          for (ELIEjectorSingleEjector *ejector in [self.singleEjectors copy]) {
            [ejector start];
          }
        } else {
          [strongSelf stop];
          completion(errors, strongSelf);
        }
      }
    }];
    [self.singleUnmounters addObject:singleUnmounter];
  }
  for (ELIEjectorSingleUnmounter *singleUnmounter in [self.singleUnmounters copy]) {
    [singleUnmounter start];
  }
  return self;
}

@end
