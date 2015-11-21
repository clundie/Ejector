//
//  EJELoginItemEnabler.m
//  Ejector
//
//  Created by Chris Lundie on 10/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "EJELoginItemEnabler.h"
#import "../Shared/NSObject+CDLKVO.h"

@import Cocoa;
@import ServiceManagement;

@interface EJELoginItemEnabler()

@property (nonatomic) CDLKVOObserver *observer;

@end

@implementation EJELoginItemEnabler

- (instancetype)watchUserDefaults
{
  static NSString * const keyPath = @"values.LoginItemEnabled";
  self.observer = [[NSUserDefaultsController sharedUserDefaultsController] cdl_observeKeyPaths:@[keyPath] options:0 block:^(NSString *_, NSDictionary *change) {
    id value = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:keyPath];
    BOOL loginItemEnabled = [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
    SMLoginItemSetEnabled(CFSTR("ca.lundie.EjectorLoginItem"), loginItemEnabled ? true : false);
  }];
  return self;
}

@end
