//
//  CDLSchedule.m
//  Ejector
//
//  Created by Chris Lundie on 13/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "CDLSchedule.h"

@interface CDLSchedule ()

@property (copy, readwrite) NSDate *date;
@property (copy, readwrite) NSArray *bookmarks;

@end

@implementation CDLSchedule

- (instancetype)initWithDate:(NSDate *)date bookmarks:(NSArray *)bookmarks
{
  self = [super init];
  if (self) {
    self.date = date;
    self.bookmarks = bookmarks;
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  return [[CDLSchedule alloc] initWithDate:self.date bookmarks:self.bookmarks];
}

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:self.date forKey:@"date"];
  [aCoder encodeObject:self.bookmarks forKey:@"bookmarks"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  return [self
    initWithDate:[aDecoder decodeObjectOfClass:[NSDate class] forKey:@"date"]
    bookmarks:[aDecoder decodeObjectOfClass:[NSArray class] forKey:@"bookmarks"]
  ];
}

@end
