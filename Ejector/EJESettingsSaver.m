//
//  EJESettingsSaver.m
//  Ejector
//
//  Created by Chris Lundie on 13/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "EJESettingsSaver.h"
#import "../Shared/CDLSchedule+Writer.h"
#import "../Shared/NSObject+CDLKVO.h"

@import Cocoa;

@interface EJESettingsSaver ()

@property (nonatomic) CDLKVOObserver *observer;

@end

@implementation EJESettingsSaver

- (instancetype)watchUserDefaults
{
  self.observer = [[NSUserDefaultsController sharedUserDefaultsController] cdl_observeKeyPaths:@[@"values.ScheduledTime"] options:0 block:^(NSString *keyPath, NSDictionary *change) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *date = [defaults objectForKey:@"ScheduledTime"];
    if (![date isKindOfClass:[NSDate class]]) {
      date = nil;
    }
    CDLSchedule *schedule = [[CDLSchedule alloc] initWithDate:date bookmarks:@[]];
    [schedule writeToSharedStorage];
  }];
  return self;
}

@end
