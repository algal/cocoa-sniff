//
//  PSLog.h
//  PSFoundation
//
//  Created by Charles Gamble on 21/10/2008.
//  Copyright 2008 Charles Gamble. All rights reserved.
//

#import <Foundation/Foundation.h>


// If we're not in a debug build, remove the PSLog statements. This
// makes calls to PSLog "compile out" of Release builds
#ifdef DEBUG

#define PSLogDebug(...)		NSLog(@"[%@] DEBUG: %s %@", ([[NSThread currentThread] isMainThread] ? @"Main Thread" : [NSString stringWithFormat:@"Thread %p", [NSThread currentThread]]), __func__, [NSString stringWithFormat:__VA_ARGS__])
#define PSLog(...)			NSLog(@"[%@] INFO: %s %@", ([[NSThread currentThread] isMainThread] ? @"Main Thread" : [NSString stringWithFormat:@"Thread %p", [NSThread currentThread]]), __func__, [NSString stringWithFormat:__VA_ARGS__])
#define PSLogInfo(...)		NSLog(@"[%@] INFO: %s %@", ([[NSThread currentThread] isMainThread] ? @"Main Thread" : [NSString stringWithFormat:@"Thread %p", [NSThread currentThread]]), __func__, [NSString stringWithFormat:__VA_ARGS__])

#else

#undef PSLogDebug
#undef PSLog
#undef PSLogInfo
#define PSLogDebug(...) do {} while(0)
#define PSLog(...) do {} while(0)
#define PSLogInfo(...) do {} while(0)

#endif


// We always want these enabled.
#define PSLogWarning(...)				NSLog(@"[%@] WARNING: %s %@", ([[NSThread currentThread] isMainThread] ? @"Main Thread" : [NSString stringWithFormat:@"Thread %p", [NSThread currentThread]]), __func__, [NSString stringWithFormat:__VA_ARGS__])
#define PSLogError(...)					NSLog(@"[%@] ERROR: %s %@", ([[NSThread currentThread] isMainThread] ? @"Main Thread" : [NSString stringWithFormat:@"Thread %p", [NSThread currentThread]]), __func__, [NSString stringWithFormat:__VA_ARGS__])
#define PSLogException(...)				NSLog(@"[%@] EXCEPTION: %s %@", ([[NSThread currentThread] isMainThread] ? @"Main Thread" : [NSString stringWithFormat:@"Thread %p", [NSThread currentThread]]), __func__, [NSString stringWithFormat:__VA_ARGS__])
#define PSLogRelease(...)				NSLog(@"[%@] INFO: %s %@", ([[NSThread currentThread] isMainThread] ? @"Main Thread" : [NSString stringWithFormat:@"Thread %p", [NSThread currentThread]]), __func__, [NSString stringWithFormat:__VA_ARGS__])
#define PSLogIntervalSince(msg,since)	NSLog(@"[%@] TIMING: %@ took %fs", ([[NSThread currentThread] isMainThread] ? @"Main Thread" : [NSString stringWithFormat:@"Thread %p", [NSThread currentThread]]), (msg), [[NSDate date] timeIntervalSinceDate:(since)])
#define PSLogElapsedTime(msg,elapsed)	NSLog(@"[%@] TIMING: %@ took %fs", ([[NSThread currentThread] isMainThread] ? @"Main Thread" : [NSString stringWithFormat:@"Thread %p", [NSThread currentThread]]), (msg), (elapsed))
