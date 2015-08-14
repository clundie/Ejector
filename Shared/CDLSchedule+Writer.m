//
//  CDLSchedule+Writer.m
//  Ejector
//
//  Created by Chris Lundie on 13/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "CDLSchedule+Writer.h"
#import "CDLFileContainer.h"

@implementation CDLSchedule (Writer)

- (void)writeToSharedStorage
{
  NSURL *fileURL = CDLScheduleFileURL();
  NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:self];
  [fileData writeToURL:fileURL atomically:YES];
}

@end
