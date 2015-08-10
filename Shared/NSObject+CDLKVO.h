//
//  NSObject+CDLKVO.h
//
//  Created by Chris Lundie on 10/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

@import Foundation;

@class CDLKVOObserver;

typedef void(^CDLKVOObserverBlock)(NSDictionary *change);

@interface NSObject (CDLKVO)

- (CDLKVOObserver *)cdl_observeKeyPath:(NSString *)path options:(NSKeyValueObservingOptions)options block:(CDLKVOObserverBlock)block;

@end

@interface CDLKVOObserver : NSObject

- (void)stop;

@end
