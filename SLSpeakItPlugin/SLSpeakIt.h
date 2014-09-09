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
@property (strong, nonatomic) NSString *markBegin;
@property (strong, nonatomic) NSString *markEnd;
@property (strong, nonatomic) NSString *varName;
@property (strong, nonatomic) NSString *secondVarName;
@property (nonatomic) NSRange replacementRange;
@property (strong, nonatomic) NSMutableArray *translatedCodeArray;
@property (strong, nonatomic) NSString *previousInput;
@property (strong, nonatomic) NSMutableArray *previousInputArray;
@property (strong, nonatomic) NSMutableArray *variablesArray;
@property (strong, nonatomic) NSMutableArray *collectionsArray;

- (void)tryReplacingStringWithCode;

@end
