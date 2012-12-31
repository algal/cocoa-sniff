#import "NSArray+functional.h"

@implementation NSArray (functional)

- (NSArray *)mapUsingBlock:(id (^)(id obj))block {
  NSMutableArray *output = [NSMutableArray array];
  for (id obj in self) {
    [output addObject:block(obj)];
  }
  return [NSArray arrayWithArray:output];
}

- (NSArray *)filteredArrayUsingBlock:(BOOL (^)(id obj))block {
  NSMutableArray *output = [NSMutableArray array];
  for (id obj in self) {
    if( block(obj) ) {
      [output addObject:obj];
    }
  }
  return [NSArray arrayWithArray:output];
}

- (BOOL)everyElementPasses:(BOOL (^)(id obj))block
{
  for ( id obj in self ) {
    if ( block(obj) == NO ) {
      return NO;
    }
  }
  
  return YES;
}

@end
