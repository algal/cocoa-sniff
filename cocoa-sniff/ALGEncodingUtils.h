//
//  ALGUtilities.h
//  OHI
//
//  Created by Alexis Gallagher on 2011-12-29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

void ALGPrintString(NSString * s);
void ALGPrintLnString(NSString * s);

@interface ALGEncodingUtils : NSObject

// encoding
+(NSStringEncoding)encodingForIANACharSetName:(NSString*)theIANAName;
+(NSString*)IANACharSetNameOfEncoding:(NSStringEncoding) encoding;


+(NSString*)stringWithContentsOfFile:(NSString*)filepath
              tryingIANACharSetNames:(NSArray*)theIANACharSetNames
             printAttemptedDecodings:(BOOL)printing;
@end
