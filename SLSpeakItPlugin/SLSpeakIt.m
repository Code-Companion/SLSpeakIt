//
//  SLSpeakIt.m
//  SLSpeakItPlugin
//
//  Created by Transcend on 8/14/14.
//  Copyright (c) 2014 SunLoveSystems. All rights reserved.
//

#import "SLSpeakIt.h"

static SLSpeakIt *speaker = nil;

@implementation SLSpeakIt

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	[self speaker];
}

+ (SLSpeakIt *)speaker
{
    NSLog(@"This is our first Xcode plugin!");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        speaker = [[self alloc] init];
    });
    
    return speaker;
}

- (id)init
{
    if (self = [super init]) {
        [self addMenuItems];
    }
    return self;
}

- (void)addMenuItems {
    NSMenu *mainMenu = [NSApp mainMenu];
    
    NSMenuItem *editMenu = [mainMenu itemAtIndex:2];
    self.onOffSwitch = [[NSMenuItem alloc] initWithTitle:@"Start SpeakIt" action:@selector(didClickBeginSpeakIt:) keyEquivalent:@""];
    [self.onOffSwitch setTarget:self];
    [[editMenu submenu] addItem:self.onOffSwitch];
}

- (void)didClickBeginSpeakIt:(id)sender
{
    [self.onOffSwitch setTitle:@"Stop SpeakIt"];
    [self.onOffSwitch setAction:@selector(didClickStopSpeakIt:)];
    NSLog(@"Started SpeakIt");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(didChangeText:)
                                                name:NSTextDidChangeNotification
                                              object:nil];
}

- (void)didChangeText:(NSNotification *) notification {
    if ([[notification object] isKindOfClass:[NSTextView class]] && [[notification object] isKindOfClass:NSClassFromString(@"DVTSourceTextView")]) {
        self.textView = (NSTextView *)[notification object];
        
        self.rawInputString = self.textView.textStorage.string;
        NSLog(@"The raw input string is: %@", self.rawInputString);
        
        [self tryReplacingStringWithCode];
        NSLog(@"Translated code string is %@", self.translatedCodeString);
        
        if ([self.translatedCodeString isEqual:@"int size = 5;\n"]) {
            NSLog(@"%@ Success!", self.translatedCodeString);
        
        } else {
            NSLog(@"We are not there yet");
            // [self.rawInputString stringByReplacingCharactersInRange:range withString:self.translatedCodeString];
        }
    }
}

- (void)tryReplacingStringWithCode
{
    NSLog(@"Replacing code...");
    if ([self.rawInputString rangeOfString:@"Make an integer variable. Call it "].location == NSNotFound) {
        NSLog(@"String does not contain Make an integer variable. Call it ");
        self.translatedCodeString = @"new code string";
    } else {
        NSLog(@"Found match of Make an integer variable. Call it ");
        NSRange varStartRange = [self.rawInputString rangeOfString:@"Call it " options:NSBackwardsSearch];
        NSLog(@"Waiting for variable input...");
        if ([self.rawInputString rangeOfString:@". Equal to "].location == NSNotFound) {
            NSLog(@"Variable not detected");
            self.translatedCodeString = [NSString stringWithFormat:@"int "];
            NSLog(@"Translated code string will be %@", self.translatedCodeString);
        } else {
            NSLog(@"Variable name detected");
            NSRange varEndRange = [self.rawInputString rangeOfString:@". Equal to " options:NSBackwardsSearch];
            NSUInteger varLength = (varEndRange.location) - (varStartRange.location+8);
            NSLog(@"VarLength is %lu", (unsigned long)varLength);
            NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+8, varLength)];
            NSLog(@"Variable name appears to be %@", varName);
            self.translatedCodeString = [NSString stringWithFormat:@"int %@ = ", varName];
            NSLog(@"Translated code string is %@", self.translatedCodeString);
            NSLog(@"Waiting for value of variable");
            if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
                NSLog(@"Variable value not detected");
            } else {
                NSLog(@"Variable value detected");
                NSRange valStartRange = [self.rawInputString rangeOfString:@"Equal to " options:NSBackwardsSearch];
                NSRange valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
                NSUInteger valLength = (valEndRange.location) - (valStartRange.location+9);
                NSLog(@"ValLength is %lu", (unsigned long)valLength);
                NSString *value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+9, valLength)];
                NSLog(@"Value appears to be %@", value);
                int variableValue = [value intValue];
                self.translatedCodeString = [NSString stringWithFormat:@"int %@ = %d;\n", varName, variableValue];
                NSLog(@"Translated code string is %@", self.translatedCodeString);
                // Now do the replacement
                NSRange lineRangeStart = [self.rawInputString rangeOfString:@"Make an integer variable." options:
                    NSBackwardsSearch];
                NSRange lineRangeEnd = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
                NSUInteger lineRangeLength = (lineRangeEnd.location+7) - lineRangeStart.location;
                NSLog(@"Line range length is %lu", (unsigned long)lineRangeLength);
                NSRange replacementRange = NSMakeRange(lineRangeStart.location, lineRangeLength);
                self.rawInputString = [self.rawInputString stringByReplacingCharactersInRange:replacementRange withString:self.translatedCodeString];
                NSLog(@"%@", self.rawInputString);
                [self.textView insertText:self.translatedCodeString replacementRange:replacementRange];
                // this crashes Xcode
//                NSTextStorage *newStorage = [[NSTextStorage alloc] initWithString:self.rawInputString];
//                [self.textView.layoutManager replaceTextStorage:newStorage];
            }
        }
    }
}

- (void)didClickStopSpeakIt:(id)sender
{
    self.rawInputString = nil;
    self.translatedCodeString = nil;
    [self.onOffSwitch setTitle:@"Start SpeakIt"];
    [self.onOffSwitch setAction:@selector(didClickBeginSpeakIt:)];
    NSLog(@"Stopped SpeakIt");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
