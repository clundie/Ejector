//
//  NSUserDefaultsController+EJESuite.m
//  Ejector
//
//  Created by Chris Lundie on 20/Nov/2015.
//  Copyright © 2015 Chris Lundie. All rights reserved.
//

#import "NSUserDefaultsController+EJESuite.h"
#import "NSUserDefaults+EJESuite.h"

static NSUserDefaultsController *_sharedInstance;

@implementation NSUserDefaultsController (EJESuite)

+ (instancetype)eje_sharedSuite
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[NSUserDefaultsController alloc] initWithDefaults:[NSUserDefaults eje_sharedSuite] initialValues:nil];
  });
  return _sharedInstance;
}

@end
