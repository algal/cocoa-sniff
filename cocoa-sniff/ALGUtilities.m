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

+(BOOL)validateUserSuppliedCSV:(NSString*)csvFilenameWithSuffix HasField:(NSString*)columnName
{
  // check if file is present
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString * documentsPrefix = [paths objectAtIndex:0];
  NSString * csvPath = [documentsPrefix stringByAppendingPathComponent:csvFilenameWithSuffix];
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:csvPath];
  if ( fileExists == NO ) {
    PSLogInfo(@"Did not find user supplied CSV filename %@",csvFilenameWithSuffix);
    return NO;
  }
  
  // try to parse them into an array of arrays
  NSArray * arrayOfArrays = [ALGUtilities arrayFromCSVFilepath:csvPath];
  if ( arrayOfArrays == nil ) return NO;
  
  // verify first row has a columnName, case-insensitively
  NSArray * headers = [[arrayOfArrays objectAtIndex:0] mapUsingBlock:^id(id obj) {
    return [obj lowercaseString];
  }];
  if (  [headers containsObject:[columnName lowercaseString]] == false ) return NO;
  
  // verify all rows have same number of columns
  NSInteger columnCount = [headers count];
  for (NSArray * row in arrayOfArrays) {
    if ( [row count] != columnCount ) return NO;
  }
  
  return YES;
}

/**
 Converts a CSV string into an array of arrays.

 Code taken on
 on 2011-12-29T18:04Z
 from
 http://www.macresearch.org/cocoa-scientists-part-xxvi-parsing-csv-data
 where it was stated that "I’m releasing this code into the public domain, so use it as you please."
 
 TODO: replace this with CHCSVParser, which seems more mature.
 */
+(NSArray *) arrayOfArraysFromCSVString:(NSString *) csvString
{
  NSMutableArray *rows = [NSMutableArray array];
  
  // Get newline character set
  NSMutableCharacterSet *newlineCharacterSet = (id)[NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
  [newlineCharacterSet formIntersectionWithCharacterSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
  
  // Characters that are important to the parser
  NSMutableCharacterSet *importantCharactersSet = (id)[NSMutableCharacterSet characterSetWithCharactersInString:@",\""];
  [importantCharactersSet formUnionWithCharacterSet:newlineCharacterSet];
  
  // Create scanner, and scan string
  NSScanner *scanner = [NSScanner scannerWithString:csvString];
  [scanner setCharactersToBeSkipped:nil];
  while ( ![scanner isAtEnd] ) {        
    BOOL insideQuotes = NO;
    BOOL finishedRow = NO;
    NSMutableArray *columns = [NSMutableArray arrayWithCapacity:(NUMBER_OF_COLUMNS+1)];
    NSMutableString *currentColumn = [NSMutableString string];
    while ( !finishedRow ) {
      @autoreleasepool {
        NSString *tempString;
        if ( [scanner scanUpToCharactersFromSet:importantCharactersSet intoString:&tempString] ) {
          [currentColumn appendString:tempString];
        }
        
        if ( [scanner isAtEnd] ) {
          if ( ![currentColumn isEqualToString:@""] ) [columns addObject:currentColumn];
          finishedRow = YES;
        }
        // this line is a perf bottleneck on startup
        else if ( [scanner scanCharactersFromSet:newlineCharacterSet intoString:&tempString] ) {
          if ( insideQuotes ) {
            // Add line break to column text
            [currentColumn appendString:tempString];
          }
          else {
            // End of row
            if ( ![currentColumn isEqualToString:@""] ) [columns addObject:currentColumn];
            finishedRow = YES;
          }
        }
        else if ( [scanner scanString:@"\"" intoString:NULL] ) {
          if ( insideQuotes && [scanner scanString:@"\"" intoString:NULL] ) {
            // Replace double quotes with a single quote in the column string.
            [currentColumn appendString:@"\""]; 
          }
          else {
            // Start or end of a quoted string.
            insideQuotes = !insideQuotes;
          }
        }
        else if ( [scanner scanString:@"," intoString:NULL] ) {  
          if ( insideQuotes ) {
            [currentColumn appendString:@","];
          }
          else {
            // This is a column separating comma
            [columns addObject:currentColumn];
            currentColumn = [NSMutableString string];
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
          }
        }
      }
    }
    if ( [columns count] > 0 ) [rows addObject:columns];
  }
  
  return rows;
}


+(NSArray *) arrayFromCSVFilepath: (NSString *) csvFilepath
{
  if ( ! [[NSFileManager defaultManager] fileExistsAtPath:csvFilepath] ) {
    PSLogError(@"cannot import file as csv does not exist:%@",csvFilepath);
    return nil;
  }
  
  
  // TODO: cleanup. Reads the data twice now in some cases.

  // try to read as utf-8
  NSStringEncoding encodingToAttempt = NSUTF8StringEncoding;
  NSString * csvData;
  NSError * error = nil;
  csvData = [NSString stringWithContentsOfFile:csvFilepath
                                      encoding:encodingToAttempt
                                         error:&error];
  if ( csvData  != nil ) {
    PSLogInfo(@"Read file as utf-8 without incident");
  }
  // if utf-8 fails...
  else {
    PSLogWarning(@"failure reading csv filepath %@ as utf-8. Trying to sniff encoding.",csvFilepath);

    // ... then sniff.
    NSStringEncoding sniffedEncoding;
    // try to guess encoding for debugging
    error=nil;
    csvData = [NSString stringWithContentsOfFile:csvFilepath 
                                    usedEncoding:&sniffedEncoding 
                                           error:&error];
    if ( csvData == nil ) {
      // if sniffing fails ..
      PSLogWarning(@"Unable to read %@, probably because unable to guess its encoding.",csvFilepath);
      PSLogWarning(@"The error object says:\n description=%@\n failureReason=%@\n recoveryoptions=%@\n recoverysuggestion=%@",
                [error localizedDescription],
                [error localizedFailureReason],
                [error localizedRecoveryOptions],
                [error localizedRecoverySuggestion]);

      // ... then try last resort,
      encodingToAttempt = NSMacOSRomanStringEncoding;
      PSLogWarning(@"Going to default to trying encoding=%@",[ALGUtilities nameOfEncoding:encodingToAttempt]);

      
      // try again with guessed/defaulted encoding
      error=nil;
      csvData = [NSString stringWithContentsOfFile:csvFilepath
                                          encoding:encodingToAttempt
                                             error:&error];
      // if last resort fails ..
      if ( csvData == nil ) {
        // .. give up
        PSLogError(@"failure reading csv filepath %@ while using encoding %@",csvFilepath,
                   [ALGUtilities nameOfEncoding:encodingToAttempt] );
        PSLogWarning(@"The error object says:\n description=%@\n failureReason=%@\n recoveryoptions=%@\n recoverysuggestion=%@",
                     [error localizedDescription],
                     [error localizedFailureReason],
                     [error localizedRecoveryOptions],
                     [error localizedRecoverySuggestion]);
        return nil;
      } 
      else {
        PSLogInfo(@"successfully read file using 'macintosh' encoding");
      }
    } 
    else
    {
      // but if sniffing succeeded, then trust it and log the fact
      PSLogWarning(@"Detected that file %@ probably has the (IANA-named) encoding=%@. Going to try reading that",
                   csvFilepath,[ALGUtilities nameOfEncoding:sniffedEncoding]);
    }
  }

  // assert: we've read the file, possibly based on a sniffd encoding
  NSArray * csvArray = [ALGUtilities arrayOfArraysFromCSVString:csvData];
  
  if ( csvArray == nil ) {
    PSLog(@"csv file was read, but could not be parsed into an NSArray");
    return nil;
  }
  
  return csvArray;
  
}


/**
 Creates fresh array of arrays, given a csv file, or nil if error.
 */
+(NSArray *) arrayFromCSVFilename: (NSString *) csvFilename
{
  NSString * csvFilepath = [[NSBundle bundleForClass:[self class]] pathForResource:csvFilename ofType:@"csv"];
  
  if ( csvFilepath == nil ) {
    PSLog(@"Failed to find csv file %@.csv",csvFilename);
    return nil;
  }
  
  return [ALGUtilities arrayFromCSVFilepath:csvFilepath];
}


/**
  Given an array of arrays, where the first is headers, returns an array of dictionaries using the LOWERCASE column names as keys.
 
 */
+(NSArray *) arrayOfDictionariesFromArrayOfArrays:(NSArray *)arrayOfArrays
{
  NSArray * headersLowercase = [arrayOfArrays objectAtIndex:0];

  NSMutableArray * results = [NSMutableArray arrayWithCapacity:[arrayOfArrays count]];
  NSRange allButFirst;
  allButFirst.location=1;
  allButFirst.length = [arrayOfArrays count]-1;
  for ( NSArray * line in [arrayOfArrays subarrayWithRange:allButFirst] ) {
    [results addObject:[NSDictionary dictionaryWithObjects:line forKeys:headersLowercase]];
  }
  
  return results;
}

/** If theStringOrFilename seems to be a filename ending in .xml, then
 reads the file from Documents folder or the app bundle and returns it 
 as a string. Otherwise, assumes it's a string and just returns it.
 
 This let's us populate spreadsheet cells either with filenames or with raw
 xhtml, whatever be our fancy
 */
+(NSString*)stringFromStringOrXMLFilename:(NSString*)theStringOrFilename
{
  if ( [[theStringOrFilename pathExtension] isEqualToString:@"xml"] ) {
    NSString * filePath = [ALGUtilities pathForFile:[theStringOrFilename stringByDeletingPathExtension] 
                                             ofType:@"xml"];
    NSError * error = nil;
    NSString * results= [NSString stringWithContentsOfFile:filePath 
                                                  encoding:NSUTF8StringEncoding 
                                                     error:&error];
    if ( ! results ) {
      PSLogError(@"Unable to read file %@ because it is not saved in utf-8 encoding",filePath);
      return nil;
    } else {
      return results;
    }
  } 
  else {
    return theStringOrFilename;
  }
}


/*
 Like [NSBundle pathForResource:ofType:, but first looks for the file 
 (possibly recursively)  in ~/Documents, the directory accessible to 
 the user via iTunes File Sharing.
 
 Set isDocument to YES if file ws found in ~/Documents
 
 Then, on failure, looks in app's bundle resources
 
 // http://mobiforge.com/developing/story/importing-exporting-documents-ios
 */
+(NSString*)  pathForFile:(NSString*)theFilename 
                   ofType:(NSString*)theFileExtension
{
  BOOL recursively = YES; 
  NSString * filenameWithExtension = theFilename;
  if ( theFileExtension ) {
    filenameWithExtension = [theFilename stringByAppendingPathExtension:theFileExtension];
  }

  NSString * path;

  // construct the ~/Documents path
  NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString * documentsDir =  [searchPaths objectAtIndex:0];
  
  if ( recursively ) {
    // recursively search under ~/Documents/ for <filename>
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:documentsDir];
    NSString *subpathWithExtension;
    while (subpathWithExtension = [dirEnum nextObject]) {
      NSString * searchedPathWithExtension = [documentsDir stringByAppendingPathComponent:subpathWithExtension];
      BOOL isDirectory;
      [[NSFileManager defaultManager] fileExistsAtPath:searchedPathWithExtension 
                                           isDirectory:&isDirectory ];
      if ( ! isDirectory && 
          [[[searchedPathWithExtension pathComponents] lastObject] 
           isEqualToString:filenameWithExtension]) {
            PSLogWarning(@"Found file %@ in ~/Documents, before looking bundle Resources",filenameWithExtension);
            return searchedPathWithExtension;
          }
    }
    // recursive search failed
    path = nil;
  } 
  else {
    // probe for file only at ~/Documents/<filename>
    NSString * possibleFilepath = [documentsDir stringByAppendingPathComponent:filenameWithExtension];
    // return the path if the file exists
    if ( [[NSFileManager defaultManager] fileExistsAtPath:possibleFilepath] ) {
      PSLogWarning(@"Found file %@ in ~/Documents, before looking bundle Resources",possibleFilepath);
      path = possibleFilepath;
    }
    else {
      // probing one location failed
      path = nil;
    }
  }
  
  // if not found in ~/Documents, try Resources
  if ( ! path ) {
    // assert: not found in Documents
    path = [[NSBundle bundleForClass:[self class]] pathForResource:theFilename ofType:theFileExtension];
  }
  
  return path;
}

#pragma mark - text encoding helpers

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
