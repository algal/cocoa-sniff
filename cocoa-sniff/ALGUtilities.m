//
//  ALGUtilities.m
//  OHI
//
//  Created by Alexis Gallagher on 2011-12-29.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ALGUtilities.h"
#import "PSLog.h"
#import "NSArray+functional.h"

#define NUMBER_OF_COLUMNS 22 // (a hint for perf)

@implementation ALGUtilities


+(NSDictionary*)dictionaryWithNSStringEncodingNamesAndValues
{
  // pulled from OSX 10.7 docs on 2012-03-02T11:36UTC
  // CoreFoundation offers more encodings
  const int encodingsCount = 24;
  NSStringEncoding encodings[encodingsCount] =   {NSASCIIStringEncoding,
    NSNEXTSTEPStringEncoding,
    NSJapaneseEUCStringEncoding,
    NSUTF8StringEncoding,
    NSISOLatin1StringEncoding,
    NSSymbolStringEncoding,
    NSNonLossyASCIIStringEncoding,
    NSShiftJISStringEncoding,
    NSISOLatin2StringEncoding,
    NSUnicodeStringEncoding,
    NSWindowsCP1251StringEncoding,
    NSWindowsCP1252StringEncoding,
    NSWindowsCP1253StringEncoding,
    NSWindowsCP1254StringEncoding,
    NSWindowsCP1250StringEncoding,
    NSISO2022JPStringEncoding,
    NSMacOSRomanStringEncoding,
    NSUTF16StringEncoding,
    NSUTF16BigEndianStringEncoding,
    NSUTF16LittleEndianStringEncoding,
    NSUTF32StringEncoding,
    NSUTF32BigEndianStringEncoding,
    NSUTF32LittleEndianStringEncoding,
    NSProprietaryStringEncoding};
  
  NSMutableArray * encodingsAsValues = [NSMutableArray arrayWithCapacity:encodingsCount];
  for (NSInteger i = 0; i < encodingsCount; ++i) {
    [encodingsAsValues addObject:[NSNumber numberWithUnsignedInteger:encodings[i]]];
  }
  
  NSArray * encodingNames = [NSArray arrayWithObjects:
                             @"NSASCIIStringEncoding",
                             @"NSNEXTSTEPStringEncoding",
                             @"NSJapaneseEUCStringEncoding",
                             @"NSUTF8StringEncoding",
                             @"NSISOLatin1StringEncoding",
                             @"NSSymbolStringEncoding",
                             @"NSNonLossyASCIIStringEncoding",
                             @"NSShiftJISStringEncoding",
                             @"NSISOLatin2StringEncoding",
                             @"NSUnicodeStringEncoding",
                             @"NSWindowsCP1251StringEncoding",
                             @"NSWindowsCP1252StringEncoding",
                             @"NSWindowsCP1253StringEncoding",
                             @"NSWindowsCP1254StringEncoding",
                             @"NSWindowsCP1250StringEncoding",
                             @"NSISO2022JPStringEncoding",
                             @"NSMacOSRomanStringEncoding",
                             @"NSUTF16StringEncoding",
                             @"NSUTF16BigEndianStringEncoding",
                             @"NSUTF16LittleEndianStringEncoding",
                             @"NSUTF32StringEncoding",
                             @"NSUTF32BigEndianStringEncoding",
                             @"NSUTF32LittleEndianStringEncoding",
                             @"NSProprietaryStringEncoding",
                             nil];
  
  return [NSDictionary dictionaryWithObjects:encodingsAsValues
                                     forKeys:encodingNames];
}


#define UNRECOGNIZED_NSSTRING_ENCODING 0 // is unused by Apple's enum, so seems ok
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


+(NSString*)nameOfEncoding:(NSStringEncoding) encoding
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
{
  NSStringEncoding encoding;
  NSError * error = nil;
  NSString * readData = nil;
  
  for (NSString * IANACharSetName in theIANACharSetNames) {
    error = nil;
    
    if ([IANACharSetName isEqualToString:@""] ) {
      // sniff the encoding
      PSLogInfo(@"Trying to sniff encoding.");
      readData = [NSString stringWithContentsOfFile:filepath usedEncoding:&encoding error:&error];
      if ( ! readData ) {
        PSLogInfo(@"Sniffing failed, with error:%@",[error localizedDescription]);
        continue;
      } 
      else {
        PSLogInfo(@"Sniffing succeeded, discovered IANACharSet:%@",[ALGUtilities nameOfEncoding:encoding]);
        break;
      }
    } 
    // try a given encoding
    else {
      PSLogInfo(@"Trying to read file using IANACharSet=%@",IANACharSetName);
      encoding = [ALGUtilities encodingForIANACharSetName:IANACharSetName];
      if (encoding == UNRECOGNIZED_NSSTRING_ENCODING) {
        PSLogWarning(@"Unable to interpret as a IANA CharSet name:%@",IANACharSetName); 
        continue;
      } 
      else
      {
        PSLogInfo(@"translating IANACharSet=%@ into NSStringEncoding=%@",
                  IANACharSetName,[ALGUtilities nameOfEncoding:encoding]);
      }
      
      readData = [NSString stringWithContentsOfFile:filepath encoding:encoding error:&error];
      if ( ! readData ) {
        PSLogInfo(@"Failed to read file using IANACharSet=%@. Got error=%@",IANACharSetName,[error localizedDescription]);
        continue;
      }
      else {
        PSLogInfo(@"Succeeded in reading file with IANACharSet=%@",IANACharSetName);
        break;
      }
      
    }
  }
  // assert: readData contains data, or nil if failure
  // assert: encoding contains last encoding used or sniffed
  // assert: error contains an error, or nil if successful
  return readData;
}


+(BOOL) fileIsUTF8Encoded:(NSString*)theFilepath
{
  NSError * error = nil;
  NSStringEncoding encoding = NSUTF8StringEncoding;
  
  NSString *str = [NSString stringWithContentsOfFile:theFilepath encoding:encoding error:&error];
  if ( str != nil )
    return YES;
    
  PSLogError(@"failure reading filepath %@ while using encoding %@",theFilepath,
               [ALGUtilities nameOfEncoding:encoding] );
  PSLogWarning(@"The error object says:\n description=%@\n failureReason=%@\n recoveryoptions=%@\n recoverysuggestion=%@",
               [error localizedDescription],
               [error localizedFailureReason],
               [error localizedRecoveryOptions],
               [error localizedRecoverySuggestion]);
  
  return NO;
}

@end
