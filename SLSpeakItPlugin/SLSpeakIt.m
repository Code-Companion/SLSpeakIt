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
    }
}

- (void)tryReplacingStringWithCode
{
    NSLog(@"Replacing code...");
    
    // first case - an integer variable
    if ([self.rawInputString rangeOfString:@"Create an integer variable. Call it "].location == NSNotFound) {
        NSLog(@"String does not contain Create an integer variable. Call it ");
    } else {
        NSLog(@"Found match of Create an integer variable. Call it ");
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
                NSLog(@"Integer variable value not detected");
            } else {
                NSLog(@"Integer variable value detected");
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
                NSRange lineRangeStart = [self.rawInputString rangeOfString:@"Create an integer variable." options:
                    NSBackwardsSearch];
                NSRange lineRangeEnd = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
                NSUInteger lineRangeLength = (lineRangeEnd.location+7) - lineRangeStart.location;
                NSLog(@"Line range length is %lu", (unsigned long)lineRangeLength);
                NSRange replacementRange = NSMakeRange(lineRangeStart.location, lineRangeLength);
                self.rawInputString = [self.rawInputString stringByReplacingCharactersInRange:replacementRange withString:self.translatedCodeString];
                NSLog(@"%@", self.rawInputString);
                [self.textView insertText:self.translatedCodeString replacementRange:replacementRange];
            }
        }
    }
    
    // second case - a float variable -- make these || OR cases for each type of variable
    // This is not being called, is it too far outside brackets or need to do something else?
    if ([self.rawInputString rangeOfString:@"Create a float variable. Call it "].location == NSNotFound) {
        NSLog(@"String does not contain Create a float variable. Call it ");
    } else {
        NSLog(@"Found match of Create a float variable. Call it ");
        // this line is repeat for all variables and could be generalized in a method - maybe move this down
        // to join varEndRange
        NSRange varStartRange = [self.rawInputString rangeOfString:@"Call it " options:NSBackwardsSearch];
        if ([self.rawInputString rangeOfString:@". Equal to "].location == NSNotFound) {
            NSLog(@"Variable not detected");
            self.translatedCodeString = [NSString stringWithFormat:@"float "];
        } else {
            // Next x lines are repeat for all variables and could be generalized in a method too
            NSLog(@"Variable name detected");
            NSRange varEndRange = [self.rawInputString rangeOfString:@". Equal to " options:NSBackwardsSearch];
            NSUInteger varLength = (varEndRange.location) - (varStartRange.location+8);
            NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+8, varLength)];
            if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
                NSLog(@"Float variable value not detected");
            } else {
                NSRange valStartRange = [self.rawInputString rangeOfString:@"Equal to " options:NSBackwardsSearch];
                NSRange valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
                NSUInteger valLength = (valEndRange.location) - (valStartRange.location+9);
                NSString *value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+9, valLength)];
                // here you may need to switch on type of variable - if int; if float; etc.
                // but just for the next three lines
                float variableValue = [value floatValue];
                self.translatedCodeString = [NSString stringWithFormat:@"float %@ = %f;\n", varName, variableValue];
                
                // this part is all repeat and should be generalized in a method except for the first line which
                // should be in the switch OR changed to "Create" if that is doable
                NSRange lineRangeStart = [self.rawInputString rangeOfString:@"Create a float variable" options:NSBackwardsSearch];
                NSRange lineRangeEnd = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
                NSUInteger lineRangeLength = (lineRangeEnd.location+7) - (lineRangeStart.location);
                NSRange replacementRange = NSMakeRange(lineRangeStart.location, lineRangeLength);
                self.rawInputString = [self.rawInputString stringByReplacingCharactersInRange:replacementRange withString:self.translatedCodeString];
                [self.textView insertText:self.translatedCodeString replacementRange:replacementRange];
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
