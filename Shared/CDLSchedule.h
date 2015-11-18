//
//  CDLSchedule.h
//  Ejector
//
//  Created by Chris Lundie on 13/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

@class CDLSchedule;

@import Foundation;

@interface CDLSchedule : NSObject <NSSecureCoding, NSCopying>

- (instancetype)initWithDate:(NSDate *)date bookmarks:(NSArray *)bookmarks;

@property (copy, readonly) NSDate *date;
@property (copy, readonly) NSArray *bookmarks;

@end
