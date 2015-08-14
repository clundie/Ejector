//
//  CDLSchedule+Reader.m
//  Ejector
//
//  Created by Chris Lundie on 13/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "CDLSchedule+Reader.h"
#import "CDLFileContainer.h"

@implementation CDLSchedule (Reader)

+ (instancetype)scheduleWithSharedStorage
{
  NSURL *fileURL = CDLScheduleFileURL();
  NSError *error = nil;
  NSData *fileData = [[NSData alloc] initWithContentsOfURL:fileURL options:0 error:&error];
  if (![fileData length]) {
    return nil;
  }
  @try
  {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:fileData];
    @try
    {
      unarchiver.requiresSecureCoding = YES;
      return [unarchiver decodeObjectOfClass:[CDLSchedule class] forKey:NSKeyedArchiveRootObjectKey];
    }
    @finally
    {
      [unarchiver finishDecoding];
    }
  }
  @catch (NSException *exception)
  {
    return nil;
  }
}

@end
