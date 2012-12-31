#import <Foundation/Foundation.h>

@interface NSArray (functional)
- (NSArray *)mapUsingBlock:(id (^)(id obj))block;
- (NSArray *)filteredArrayUsingBlock:(BOOL (^)(id obj))block;
- (BOOL)everyElementPasses:(BOOL (^)(id obj))block;
@end
