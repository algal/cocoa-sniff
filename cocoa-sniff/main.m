//
//  main.m
//  cocoa-encoding
//
//  Created by Alexis Gallagher on 2012-03-02.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <getopt.h>
#import <Foundation/Foundation.h>
#import "ALGEncodingUtils.h"
#import "NSArray+functional.h"

#define DEFAULT_ENCODINGS_TO_TRY (@[@"SNIFF",@"windows-1252",@"macintosh"])


void PrintSupportedEncodings()
{
  for (NSStringEncoding const * encodingptr = [NSString availableStringEncodings];
       *encodingptr !=0; ++encodingptr)
  {
    NSStringEncoding encoding = *encodingptr;
    NSNumber * encodingValue = @(encoding);
    NSString * encodingName = [NSString localizedNameOfStringEncoding:encoding];
    NSString * IANAname = [ALGEncodingUtils IANACharSetNameOfEncoding:encoding];

    ALGPrintLnString([NSString stringWithFormat:@"%48s %16s %@",
                   encodingName.UTF8String,IANAname.UTF8String,encodingValue]);
  }
}

NSArray * RemoveSNIFFFromEncodingNames(NSArray * encodings)
{
  return [encodings mapUsingBlock:^NSString*(NSString* obj) {
    return ([obj isEqualToString:@"SNIFF"] ? @"" : obj);
  }];
}

int ch=0;
int listSet=0;
int convertSet=0;

/* options descriptor */
static struct option longopts[] = {
  { "list",       no_argument,       &listSet,       1 },
  { "encodings",  required_argument, NULL, 'e' },
  { "convert",    no_argument,       &convertSet,    1 },
  { NULL,         0,                 NULL,           0 }
};

void PrintUsage(NSString * appName) {
  ALGPrintLnString([NSString stringWithFormat:@"usage: %@ [--list]",appName]);
  ALGPrintLnString([NSString stringWithFormat:@"usage: %@ [--convert] [--encodings=encoding1,encoding2,encoding3] filename",appName]);
  ALGPrintLnString(
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
    
    // if requested, print encodings and exit
    if (listSet == 1) {
      PrintSupportedEncodings();
      exit(0);
    }
    
    // if no file given, exit
    if (argc==0) {
      PrintUsage(appName);
      exit(2);
    }
    
    BOOL verbose = (convertSet!=1);
   
    NSString * arg = [NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding];
    
    if(verbose)
        ALGPrintLnString([NSString stringWithFormat:@"%@:",arg]);

    NSString * fileData = [ALGEncodingUtils stringWithContentsOfFile:arg
                                          tryingIANACharSetNames:RemoveSNIFFFromEncodingNames(encodingsToTry)
                                         printAttemptedDecodings:verbose];
    if (fileData != nil) {
      retcode = 1;
      if (convertSet == 1) {
        ALGPrintString(fileData);
      }
    } else {
      retcode = 0;
    }
  }
  return retcode;
}

