//
//  SLSpeakIt.h
//  SLSpeakItPlugin
//
//  Created by Transcend on 8/14/14.
//  Copyright (c) 2014 SunLoveSystems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface SLSpeakIt : NSObject

@property (strong, nonatomic) NSMenuItem *onOffSwitch;
@property (strong, nonatomic) NSString *rawInputString;
@property (strong, nonatomic) NSString *translatedCodeString;
@property (strong, nonatomic) NSTextView *textView;
@property (strong, nonatomic) NSString *lineStart;
@property (strong, nonatomic) NSMutableArray *translatedCodeArray;

- (void)tryReplacingStringWithCode;

@end
