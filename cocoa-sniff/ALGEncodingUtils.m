//
//  ALGUtilities.m
//  OHI
//
//  Created by Alexis Gallagher on 2011-12-29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ALGEncodingUtils.h"
#import "PSLog.h"
#import "NSArray+functional.h"

#define NUMBER_OF_COLUMNS 22 // (a hint for perf)

void PrintString(NSString * s)
{
  printf("%s",[s UTF8String]);
}
void PrintLnString(NSString * s)
{
  printf("%s\n",[s UTF8String]);
}

@implementation ALGEncodingUtils

#define UNRECOGNIZED_NSSTRING_ENCODING 0 // is unused by Apple's enum, so seems ok as a flag

+(NSStringEncoding)encodingForIANACharSetName:(NSString*)theIANAName
{
  CFStringRef theIANANameCF = CFBridgingRetain(theIANAName) ;
  CFStringEncoding encodingCF = CFStringConvertIANACharSetNameToEncoding(theIANANameCF);
  CFRelease(theIANANameCF);
  if (encodingCF == kCFStringEncodingInvalidId) {
    return UNRECOGNIZED_NSSTRING_ENCODING;
  }
  NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(encodingCF);
  return encoding;
}


+(NSString*)IANACharSetNameOfEncoding:(NSStringEncoding) encoding
{
  CFStringEncoding guessedEncodingCF = CFStringConvertNSStringEncodingToEncoding(encoding);
  /* guessedEncodingNameCF is not owned by me, since it was returned by a CoreFoundation
   function which did not include the word "Create" or "Copy. Also, it could
   theoretically be mutable. */
  CFStringRef guessedEncodingNameCF = CFStringConvertEncodingToIANACharSetName(guessedEncodingCF);
  if (!guessedEncodingNameCF) {
    PSLogWarning(@"Unable to find a IANA charset name for the encoding with NSStringEncoding=%lu, CFStringEncoding=%u",
                 encoding,guessedEncodingCF);
    return @"";
  }
  
  /** 
   This creates a copy which I own (b/c the function is a "Create" function),
   and which is guaranteed to be immutable (according to the function's docs)
   */
  CFStringRef myCopy = CFStringCreateCopy(NULL, guessedEncodingNameCF);
  // bridge it from CoreFoundation to Cocoa
  NSString * guessedEncodingName = CFBridgingRelease(myCopy);
  return guessedEncodingName;
}


/** tries to read filepath successively using IANA CharSet Names. 
 If a name is an empty, tries to guess. */
+(NSString*)stringWithContentsOfFile:(NSString*)filepath
              tryingIANACharSetNames:(NSArray*)theIANACharSetNames
             printAttemptedDecodings:(BOOL)printing
{
  NSStringEncoding encoding;
  NSError * error = nil;
  NSString * readData = nil;
  
  for (NSString * IANACharSetName in theIANACharSetNames) {
    error = nil;
    if ([IANACharSetName isEqualToString:@""] ) {
      // sniff the encoding
      if ( printing)
          PrintString(@"\tTrying to sniff encoding. ");
      readData = [NSString stringWithContentsOfFile:filepath usedEncoding:&encoding error:&error];
      if ( ! readData ) {
        if ( printing)
            PrintLnString([NSString stringWithFormat:@"\tfailed. Got error:%@",[error localizedDescription]]);
        continue;
      } 
      else {
        if ( printing)
            PrintLnString([NSString stringWithFormat:@"\tsucceeded. Sniffed IANACharSet:%@",[ALGEncodingUtils IANACharSetNameOfEncoding:encoding]]);
        break;
      }
    } 
    // try a given encoding
    else {
      if ( printing)
          PrintString([NSString stringWithFormat:@"\tTrying iana-encoding=%@. ",IANACharSetName]);
      encoding = [ALGEncodingUtils encodingForIANACharSetName:IANACharSetName];
      if (encoding == UNRECOGNIZED_NSSTRING_ENCODING) {
        if ( printing)
            PrintLnString(@"\tfailed to recognize IANA encoding name");
        continue;
      }
      
      readData = [NSString stringWithContentsOfFile:filepath encoding:encoding error:&error];
      if ( ! readData ) {
        if ( printing)
            PrintLnString([NSString stringWithFormat:@"\tfailed. Got error=%@",[error localizedDescription]]);
        continue;
      }
      else {
        if ( printing)
            PrintLnString([NSString stringWithFormat:@"\tsucceeded."]);
        break;
      }
      
    }
  }
  // assert: readData contains data, or nil if failure
  // assert: encoding contains last encoding used or sniffed
  // assert: error contains an error, or nil if successful
  return readData;
}

@end
