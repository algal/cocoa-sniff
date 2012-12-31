//
//  main.m
//  cocoa-encoding
//
//  Created by Alexis Gallagher on 2012-03-02.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <getopt.h>
#import <Foundation/Foundation.h>
#import "ALGUtilities.h"
#import "NSArray+functional.h"

#define DEFAULT_ENCODINGS_TO_TRY (@[@"utf-8",@"windows-1252",@"macintosh",@"SNIFF"])


void PrintSupportedEncodings()
{
  PrintLnString([NSString stringWithFormat:@"%16s %48s %@",
                 @"IANA_CharSetName".UTF8String,@"NSSttringEncoding".UTF8String,@"value"]);
  NSDictionary * namesAndValues = [ALGUtilities dictionaryWithNSStringEncodingNamesAndValues];
  [namesAndValues enumerateKeysAndObjectsUsingBlock:^(NSString * encodingName, NSNumber * encodingValue, BOOL *stop) {
    NSStringEncoding encoding = [encodingValue unsignedIntegerValue];
    NSString * IANAname = [ALGUtilities nameOfEncoding:encoding];
    
    PrintLnString([NSString stringWithFormat:@"%16s %48s %@",
                   IANAname.UTF8String,encodingName.UTF8String,encodingValue]);
  }];
  
}

NSArray * RemoveSNIFFFromEncodingNames(NSArray * encodings)
{
  return [encodings mapUsingBlock:^NSString*(NSString* obj) {
    return ([obj isEqualToString:@"SNIFF"] ? @"" : obj);
  }];
}

int ch=0;
int listSet=0;

/* options descriptor */
static struct option longopts[] = {
  { "list",       no_argument,       &listSet,       1 },
  { "encodings",  required_argument, NULL, 'e' },
  { NULL,         0,                 NULL,           0 }
};

void PrintUsage(NSString * appName) {
  PrintLnString([NSString stringWithFormat:@"usage: %@ [--list]",appName]);
  PrintLnString([NSString stringWithFormat:@"usage: %@ [--encodings=encoding1,encoding2,encoding3] filename",appName]);
  PrintLnString(
                [NSString stringWithFormat:
                @"\n"
                @"\tEncodings must be IANA charset names, except for the special\n"
                @"\tencoding name SNIFF, which causes the system to rely on Cocoa's\n"
                @"\tencoding guesser.\n"
                @"\n"
                @"\tThis app assumes its operating in a UTF-8 terminal.\n"
                @"\tIf no list of encoding is specified, the default is %@",
                 DEFAULT_ENCODINGS_TO_TRY
                 ]
                );
}

int main (int argc, const char * argv[])
{
  int retcode=0;
  @autoreleasepool {
    NSString * const appName = [[NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding]
                                lastPathComponent];
    
    NSArray * encodingsToTry = DEFAULT_ENCODINGS_TO_TRY;
    
    while ((ch = getopt_long(argc, (char * const *)argv, "e:", longopts, NULL)) != -1)
      switch (ch) {
        case 'e':
          encodingsToTry = [[NSString stringWithCString:optarg
                                               encoding:NSUTF8StringEncoding]
                            componentsSeparatedByString:@","];
          break;
      }
    argc -= optind;
    argv += optind;
    
    // print list if that's required
    if (listSet == 1) {
      PrintSupportedEncodings();
      exit(0);
    }
    
    // abort if no file given
    if (argc==0) {
      PrintUsage(appName);
      exit(2);
    }
    
    NSString * arg = [NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding];
    
    
    // try utf-8, then windows-1252, then macintosh.
    /**
     Not clear if it is ever the case that windows-1252 fails where macintosh succeeds.
     Unfortunately, successfully reading a file with a specified encoding does not
     mean that was the correct encoding.
     */
    PrintLnString([NSString stringWithFormat:@"%@:",arg]);
    NSString * fileData = [ALGUtilities stringWithContentsOfFile:arg
                                          tryingIANACharSetNames:
                           RemoveSNIFFFromEncodingNames(encodingsToTry)
                           ];
    
    
    if (fileData != nil) {
      retcode = 1;
      PrintString([NSString stringWithFormat:@"file's contents with this encoding=\n%@",fileData]);
    } else {
      retcode = 0;
    }
  }
  return retcode;
}

