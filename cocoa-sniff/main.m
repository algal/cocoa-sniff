//
//  main.m
//  cocoa-encoding
//
//  Created by Alexis Gallagher on 2012-03-02.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSLog.h"
#import "ALGUtilities.h"

void PrintSupportedEncodings(void);
void PrintString(NSString * s);
void PrintLnString(NSString * s);


void PrintString(NSString * s)
{
  printf("%s",[s UTF8String]);
}
void PrintLnString(NSString * s)
{
  printf("%s\n",[s UTF8String]);
}


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


int main (int argc, const char * argv[])
{
  @autoreleasepool {
    
    if (argc != 2) {
      PrintLnString(@"usage: cocoa-sniff [filename]");
      PrintLnString(@"usage: cocoa-sniff --list");
      exit(1);
    }
    
    NSString * arg = [NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding];
    if ([arg isEqualToString:@"--list"]) {
      PrintSupportedEncodings();
    }
    else {
      // try utf-8, then windows-1252, then macintosh.
      /**
       Not clear if it is ever the case that windows-1252 fails where macintosh succeeds.
       Unfortunately, successfully reading a file with a specified encoding does not
       mean that was the correct encoding.
       
       */
      NSString * fileData = [ALGUtilities stringWithContentsOfFile:arg
                                            tryingIANACharSetNames:
                             @[@"utf-8",@"windows-1252",@"macintosh",@""]];
      
//      NSLog(@"file's contents=%@",fileData);
    }
  }
  return 0;
}

