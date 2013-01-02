//
//  ALGUtilities.h
//  OHI
//
//  Created by Alexis Gallagher on 2011-12-29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

void PrintString(NSString * s);
void PrintLnString(NSString * s);

@interface ALGUtilities : NSObject



// encoding
+(NSStringEncoding)encodingForIANACharSetName:(NSString*)theIANAName;
+(NSString*)IANACharSetNameOfEncoding:(NSStringEncoding) encoding;
+(NSString*)stringWithContentsOfFile:(NSString*)filepath
              tryingIANACharSetNames:(NSArray*)theIANACharSetNames
             printAttemptedDecodings:(BOOL)printing;
+(BOOL) fileIsUTF8Encoded:(NSString*)theFilepath;

@end
