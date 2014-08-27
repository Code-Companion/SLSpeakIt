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
    NSLog(@"Launching SLSpeakIt...");
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
    // Consider using NSUserDefaults for storing data between sessions
    self.variablesArray = [[NSMutableArray alloc] init];
    self.collectionsArray = [[NSMutableArray alloc] init];
    self.previousInputArray = [[NSMutableArray alloc] init];
    self.translatedCodeArray = [[NSMutableArray alloc] init];
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
    // case - create an integer variable
    if ([self.rawInputString rangeOfString:@"Create an integer variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create an integer variable";
        [self setVariableNameAndValue];
    
    // case - create a float variable
    } else if ([self.rawInputString rangeOfString:@"Create a float variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a float variable";
        [self setVariableNameAndValue];
    
    // case - create a double variable
    } else if ([self.rawInputString rangeOfString:@"Create a double variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a double variable";
        [self setVariableNameAndValue];
        
    // case - create a string variable
    } else if ([self.rawInputString rangeOfString:@"Create a string variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a string variable";
        [self setVariableNameAndValue];
    
    // case - create an unsigned integer NSUInteger variable
    } else if ([self.rawInputString rangeOfString:@"Create an unsigned integer variable. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create an unsigned integer variable";
        [self setVariableNameAndValue];
    
    // case - create an array
    } else if ([self.rawInputString rangeOfString:@"Create an array. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create an array";
        [self setArrayOrSetName];
        
    // case - create a mutable array
    } else if ([self.rawInputString rangeOfString:@"Create a mutable array. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a mutable array";
        [self setArrayOrSetName];
        
    // case - create a set
    } else if ([self.rawInputString rangeOfString:@"Create a set. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a set";
        [self setArrayOrSetName];
    
    // case - create a mutable set
    } else if ([self.rawInputString rangeOfString:@"Create a mutable set. Call it "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Create a mutable set";
        [self setArrayOrSetName];
        
    // case - add to array or set
    } else if ([self.rawInputString rangeOfString:@"Put "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Put ";
        [self addToArrayOrSet];
        
    // case - remove from array or set
    } else if ([self.rawInputString rangeOfString:@"Remove "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Remove ";
        [self removeFromArrayOrSet];

    // case - get random object from array or set
    } else if ([self.rawInputString rangeOfString:@"Random item from collection "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Random item from collection ";
        [self getRandomFromArrayOrSet];
        
    // case - log to console
    } else if ([self.rawInputString rangeOfString:@"Print "].location != NSNotFound) {
        NSLog(@"Found match of lineStart");
        self.lineStart = @"Print ";
        [self logToConsole];
    
    // case - delete warning
    } else if ([self.rawInputString rangeOfString:@"Delete warning"].location != NSNotFound) {
        self.lineStart = @"Delete warning";
        [self deleteWarning];
        
    // case - create a fast enumeration loop
    } else if ([self.rawInputString rangeOfString:@"Create a fast enumeration loop. For "].location != NSNotFound) {
        self.lineStart = @"Create a fast enumeration loop. For ";
        [self createFastEnumerationLoop];
    
//    // case - create a loop
//    } else if ([self.rawInputString rangeOfString:@"Create a loop"].location != NSNotFound) {
//        self.lineStart = @"Create a loop";
//        [self setLoopConditions];
        
//    // case - create an if statement
//    } else if ([self.rawInputString rangeOfString:@"Create an if statement"].location != NSNotFound) {
//        self.lineStart = @"Create an if statement";
//        [self createIfStatement];
//        
    // Do some math operations for ints, floats, doubles, etc.
    // Add an NSNumber variable type
    
    // Create an if statement. Condition: x < 5 etc.
    
    // Else if at close-bracket (if so, then get condition: etc.
    // Else at close-bracket (if so, then end and replace with code
    
    // Create a while loop. Condition: etc.
    
    // Next line -> does a newline \n
    
    // Previous line
    
    // Add a (void/bool/int/id/NSArray/etc.) method. Call it
    // Return functionality
        
    // default case
    } else {
        NSLog(@"No match of lineStart");
    }
}

- (void)setVariableNameAndValue
{
    if ([self.rawInputString rangeOfString:@". Equal to "].location == NSNotFound) {
        NSLog(@"Variable not detected");
    } else {
        // Find and set the variable name
        NSRange varStartRange = [self.rawInputString rangeOfString:@"Call it " options:NSBackwardsSearch];
        NSRange varEndRange = [self.rawInputString rangeOfString:@". Equal to " options:NSBackwardsSearch];
        NSUInteger varLength = (varEndRange.location) - (varStartRange.location+8);
        NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+8, varLength)];
        
        // If the variable has a value, find and set it, then call a method to replace
        // on-screen text with code
        if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
            NSLog(@"Variable value not detected");
            varName = nil;
        } else {
            NSRange valStartRange = [self.rawInputString rangeOfString:@"Equal to " options:NSBackwardsSearch];
            NSRange valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
            NSUInteger valLength = (valEndRange.location) - (valStartRange.location+9);
            NSString *value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+9, valLength)];
            [self.variablesArray addObject:varName];
            
            if ([self.lineStart isEqualToString:@"Create an integer variable"]) {
                int variableValue = [value intValue];
                self.translatedCodeString = [NSString stringWithFormat:@"int %@ = %d;\n\t", varName, variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create a float variable"]) {
                float variableValue = [value floatValue];
                self.translatedCodeString = [NSString stringWithFormat:@"float %@ = %f;\n\t", varName, variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create a double variable"]) {
                double variableValue = [value doubleValue];
                self.translatedCodeString = [NSString stringWithFormat:@"double %@ = %f;\n\t", varName, variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create a string variable"]) {
                self.translatedCodeString = [NSString stringWithFormat:@"NSString *%@ = @\"%@\";\n\t", varName, value];
                [self replaceLineWithTranslatedCodeString];
            } else if ([self.lineStart isEqualToString:@"Create an unsigned integer variable"]) {
                NSUInteger variableValue = [value intValue];
                self.translatedCodeString = [NSString stringWithFormat:@"NSUInteger %@ = %lu;\n\t", varName, (unsigned long)variableValue];
                [self replaceLineWithTranslatedCodeString];
            } else {
                value = @"Placeholder";
                varName = @"Placeholder";
            }
        }
    }
}

- (void)resetVariableValue
{
    
}

- (void)setArrayOrSetName
{
    if ([self.rawInputString rangeOfString:@". Next."].location != NSNotFound) {
        
        // Find and set the array or set name
        NSRange arrStartRange = [self.rawInputString rangeOfString:@"Call it " options:NSBackwardsSearch];
        NSRange arrEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
        NSUInteger arrLength = (arrEndRange.location) - (arrStartRange.location+8);
        NSString *arrName = [self.rawInputString substringWithRange:NSMakeRange(arrStartRange.location+8, arrLength)];
        [self.collectionsArray addObject:arrName];
        
        // Call a method to replace on-screen text with code
        if ([self.lineStart isEqualToString:@"Create an array"]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSArray *%@ = [[NSArray alloc] init];\n\t", arrName];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.lineStart isEqualToString:@"Create a mutable array"]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSMutableArray *%@ = [[NSMutableArray alloc] init];\n\t", arrName];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.lineStart isEqualToString:@"Create a set"]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSSet *%@ = [[NSSet alloc] init];\n\t", arrName];
            [self replaceLineWithTranslatedCodeString];
        } else if ([self.lineStart isEqualToString:@"Create a mutable set"]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSMutableSet *%@ = [[NSMutableSet alloc] init];\n\t", arrName];
            [self replaceLineWithTranslatedCodeString];
        }

    } else {
        NSLog(@"Array name not detected");
    }
}

- (void)addToArrayOrSet
{
    // Get the object name to add
    if ([self.rawInputString rangeOfString:@" into collection "].location != NSNotFound) {
        NSRange varStartRange = [self.rawInputString rangeOfString:self.lineStart options:NSBackwardsSearch];
        NSRange varEndRange = [self.rawInputString rangeOfString:@" into collection " options:NSBackwardsSearch];
        NSUInteger varLength = (varEndRange.location) - (varStartRange.location+4);
        NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+4, varLength)];
        
        // Find out which array or set to put it in
        if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
            NSLog(@"No array or set name detected");
        } else {
            NSRange arrStartRange = [self.rawInputString rangeOfString:@" into collection " options:NSBackwardsSearch];
            NSRange arrEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
            NSUInteger arrLength = (arrEndRange.location) - (arrStartRange.location+17);
            NSString *arrName = [self.rawInputString substringWithRange:NSMakeRange(arrStartRange.location+17, arrLength)];
            
            // Call a method to replace on-screen text with code
            if ([self.collectionsArray containsObject:arrName] && [self.variablesArray containsObject:varName]) {
                self.translatedCodeString = [NSString stringWithFormat:@"[%@ addObject:%@];\n\t", arrName, varName];
                [self replaceLineWithTranslatedCodeString];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The collection %@ or the variable %@ does not exist yet.\n\t", arrName, varName];
                [self replaceLineWithTranslatedCodeString];
            }
        }
    }
}

- (void)getRandomFromArrayOrSet
{
    if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
        NSLog(@"No array or set name detected");
    } else {
        NSRange arrStartRange = [self.rawInputString rangeOfString:self.lineStart options:NSBackwardsSearch];
        NSRange arrEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
        NSUInteger arrLength = (arrEndRange.location) - (arrStartRange.location+28);
        NSString *arrName = [self.rawInputString substringWithRange:NSMakeRange(arrStartRange.location+28, arrLength)];
        NSLog(@"arrName is %@", arrName);
        
        // Call a method to replace on-screen text with code
        if ([self.collectionsArray containsObject:arrName]) {
            self.translatedCodeString = [NSString stringWithFormat:@"NSInteger index = arc4random() %% [%@ count];\n\tid randomObject = [%@ objectAtIndex:index];\n\t", arrName, arrName];
            self.translatedCodeString = [self.translatedCodeString stringByAppendingString:@"NSLog(@\"Random object selected is %@.\", randomObject);\n\t"];
            [self replaceLineWithTranslatedCodeString];
        } else {
            self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The collection %@ does not exist yet.\n\t", arrName];
            [self replaceLineWithTranslatedCodeString];
        }
    }
}

- (void)removeFromArrayOrSet
{
    // Get the object name to remove
    if ([self.rawInputString rangeOfString:@" from collection "].location != NSNotFound) {
        NSRange varStartRange = [self.rawInputString rangeOfString:self.lineStart options:NSBackwardsSearch];
        NSRange varEndRange = [self.rawInputString rangeOfString:@" from collection " options:NSBackwardsSearch];
        NSUInteger varLength = (varEndRange.location) - (varStartRange.location+7);
        NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+7, varLength)];

        // Find out which array or set to remove it from
        if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
            NSLog(@"No array or set name detected");
        } else {
            NSRange arrStartRange = [self.rawInputString rangeOfString:@" from collection " options:NSBackwardsSearch];
            NSRange arrEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
            NSUInteger arrLength = (arrEndRange.location) - (arrStartRange.location+17);
            NSString *arrName = [self.rawInputString substringWithRange:NSMakeRange(arrStartRange.location+17, arrLength)];
            
            // Call a method to replace on-screen text with code
            if ([self.collectionsArray containsObject:arrName] && [self.variablesArray containsObject:varName]) {
                self.translatedCodeString = [NSString stringWithFormat:@"[%@ removeObject:%@];\n\t", arrName, varName];
                [self replaceLineWithTranslatedCodeString];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The collection %@ or the variable %@ does not exist yet.\n\t", arrName, varName];
                [self replaceLineWithTranslatedCodeString];
            }
        }
    }
}

- (void)logToConsole
{
    if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
        NSLog(@"String to print not detected");
    } else {
        // Get the string to print
        NSRange printStartRange = [self.rawInputString rangeOfString:self.lineStart options:NSBackwardsSearch];
        NSRange printEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
        NSUInteger printLength = (printEndRange.location) - (printStartRange.location+6);
        NSString *printString = [self.rawInputString substringWithRange:NSMakeRange(printStartRange.location+6, printLength)];
        
        self.translatedCodeString = [NSString stringWithFormat:@"NSLog(@\"%@\");\n\t", printString];
        [self replaceLineWithTranslatedCodeString];
    }
}

- (void)deleteWarning
{
    if ([self.rawInputString rangeOfString:@". Next.\n"].location == NSNotFound) {
        NSLog(@"Warning deletion not confirmed");
    } else {
        NSRange warningStartRange = [self.rawInputString rangeOfString:@"// Warning: " options:NSBackwardsSearch];
        NSRange warningEndRange = [self.rawInputString rangeOfString:@" warning. Next.\n"];
        NSUInteger warningLength = (warningEndRange.location+15) - (warningStartRange.location);
        NSRange replacementRange = NSMakeRange(warningStartRange.location, warningLength);
        self.translatedCodeString = @"";
        [self.textView insertText:self.translatedCodeString replacementRange:replacementRange];
    }
}

- (void)createFastEnumerationLoop
{
    if ([self.rawInputString rangeOfString:@" in collection "].location != NSNotFound) {
        // Get the variable name
        NSRange varStartRange = [self.rawInputString rangeOfString:self.lineStart options:NSBackwardsSearch];
        NSRange varEndRange = [self.rawInputString rangeOfString:@" in collection " options:NSBackwardsSearch];
        NSUInteger varLength = (varEndRange.location) - (varStartRange.location+self.lineStart.length);
        NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+self.lineStart.length, varLength)];
        
        if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
            // Get the array name
            NSRange arrStartRange = [self.rawInputString rangeOfString:@" in collection " options:NSBackwardsSearch];
            NSRange arrEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
            NSUInteger arrLength = (arrEndRange.location) - (arrStartRange.location+arrStartRange.length);
            NSString *arrName = [self.rawInputString substringWithRange:NSMakeRange(arrStartRange.location+arrStartRange.length, arrLength)];
            
            // Check for array existence and then replace on-screen text with code
            if ([self.collectionsArray containsObject:arrName]) {
                [self.variablesArray addObject:varName];
                // Fix cursor position here
                self.translatedCodeString = [NSString stringWithFormat:@"for (id %@ in %@) {\n\t\t}", varName, arrName];
                [self replaceLineWithTranslatedCodeString];
            } else {
                self.translatedCodeString = [NSString stringWithFormat:@"// Warning: The variable %@ or the collection %@ does not exist yet.\n\t", varName, arrName];
                [self replaceLineWithTranslatedCodeString];
            }
        }
    }
}

//- (void)setLoopConditions
//{
//    if ([self.rawInputString rangeOfString:@". Condition "].location != NSNotFound) {
//        // Get the variable to operate on
//        NSRange varStartRange = [self.rawInputString rangeOfString:@". Condition " options:NSBackwardsSearch];
//        NSRange varEndRange;
//        if ([self.rawInputString rangeOfString:@" equal to "].location != NSNotFound) {
//            varEndRange = [self.rawInputString rangeOfString:@" equal to " options:NSBackwardsSearch];
//        } else if ([self.rawInputString rangeOfString:@" less than "].location != NSNotFound) {
//            varEndRange = [self.rawInputString rangeOfString:@" less than " options:NSBackwardsSearch];
//        } else if ([self.rawInputString rangeOfString:@" greater than "].location != NSNotFound) {
//            varEndRange = [self.rawInputString rangeOfString:@" greater than " options:NSBackwardsSearch];
//        } else if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
//            varEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//        } else {
//            NSLog(@"Did not detect variable name");
//        }
//        NSUInteger varLength = (varEndRange.location) - (varStartRange.location+12);
//        NSString *varName = [self.rawInputString substringWithRange:NSMakeRange(varStartRange.location+12, varLength)];
//        NSLog(@"varName is %@", varName);
//        
//        // Get the value that the variable is compared to
//        if ([self.rawInputString rangeOfString:@". Next.\n"].location != NSNotFound) {
//            NSRange valStartRange;
//            NSRange valEndRange;
//            NSUInteger valLength;
//            NSString *value = nil;
//            // add "not equal to" here as another if case
//            if ([self.rawInputString rangeOfString:@" equal to "].location != NSNotFound) {
//                valStartRange = [self.rawInputString rangeOfString:@" equal to " options:NSBackwardsSearch];
//                valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//                valLength = (valEndRange.location) - (valStartRange.location+10);
//                value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+10, valLength)];
//                if ([self.rawInputString rangeOfString:@"integer"].location != NSNotFound) {
//                    int variableValue = [value intValue];
//                    self.translatedCodeString = [NSString stringWithFormat:@"while (%@ == %d) {\n", varName, variableValue];
//                    [self replaceLineWithTranslatedCodeString];
//                } else if ([self.rawInputString rangeOfString:@"float"].location != NSNotFound) {
//                    float variableValue = [value floatValue];
//                    self.translatedCodeString = [NSString stringWithFormat:@"while (%@ == %f) {\n", varName, variableValue];
//                    [self replaceLineWithTranslatedCodeString];
//                } else if ([self.rawInputString rangeOfString:@"double"].location != NSNotFound) {
//                    double variableValue = [value doubleValue];
//                    self.translatedCodeString = [NSString stringWithFormat:@"while (%@ == %f) {\n", varName, variableValue];
//                    [self replaceLineWithTranslatedCodeString];
//                } else if (([self.rawInputString rangeOfString:@"YES"].location != NSNotFound) || ([self.rawInputString rangeOfString:@"NO"].location != NSNotFound)) {
//                    self.translatedCodeString = [NSString stringWithFormat:@"while (%@ == %@) {\n", varName, value];
//                    [self replaceLineWithTranslatedCodeString];
//                } else {
//                    NSLog(@"Could not replace text with code");
//                }
//            } else if ([self.rawInputString rangeOfString:@" less than "].location != NSNotFound) {
//                valStartRange = [self.rawInputString rangeOfString:@" less than " options:NSBackwardsSearch];
//                valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//                valLength = (valEndRange.location) - (valStartRange.location+11);
//                value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+11, valLength)];
//            } else if ([self.rawInputString rangeOfString:@" greater than "].location != NSNotFound) {
//                valStartRange = [self.rawInputString rangeOfString:@" greater than " options:NSBackwardsSearch];
//                valEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//                valLength = (valEndRange.location) - (valStartRange.location+14);
//                value = [self.rawInputString substringWithRange:NSMakeRange(valStartRange.location+14, valLength)];
//            } else {
//                NSLog(@"Could not set valStartRange");
//            }
//        }
//    }
//}

//- (void)createIfStatement
//{
//    // Get the condition
//    if ([self.rawInputString rangeOfString:@"Condition "].location != NSNotFound) {
//        NSRange conditionStartRange = [self.rawInputString rangeOfString:@"Condition " options:NSBackwardsSearch];
//        NSRange conditionEndRange = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
//        NSUInteger conditionLength = (conditionEndRange.location) - (conditionStartRange.location+10);
//        NSString *condition
//    }
//}

- (void)replaceLineWithTranslatedCodeString
{
    // First we get the user's original input as a range in textStorage, so we can replace it with code.
    NSRange lineRangeStart = [self.rawInputString rangeOfString:self.lineStart options:NSBackwardsSearch];
    NSRange lineRangeEnd = [self.rawInputString rangeOfString:@". Next.\n" options:NSBackwardsSearch];
    NSUInteger lineRangeLength = (lineRangeEnd.location+7) - (lineRangeStart.location);
    NSRange replacementRange = NSMakeRange(lineRangeStart.location, lineRangeLength);
    
    // We store the user's original input in an array in case we need it.
    self.previousInput = [self.rawInputString substringWithRange:replacementRange];
    [self.previousInputArray addObject:self.previousInput];
    
    // Then we replace the text on-screen with valid code and add the code to an array
    // of commands issued so far.
    [self.textView insertText:self.translatedCodeString replacementRange:replacementRange];
    if ([self.translatedCodeString rangeOfString:@"// Warning: "].location == NSNotFound) {
        [self.translatedCodeArray addObject:self.translatedCodeString];
    }
}

// Make an undo function to delete the latest translatedCodeString from the screen
// and remove it as lastObject from translatedCodeArray
// If the words "Undo" appear on-screen, set that as lineRangeEnd and delete the whole string
// from self.lineStart to lineRangeEnd, OR from self.translatedCodeString lastObject to lineRangeEnd.

- (void)didClickStopSpeakIt:(id)sender
{
    self.rawInputString = nil;
    self.previousInput = nil;
    self.previousInputArray = nil;
    self.translatedCodeString = nil;
    self.lineStart = nil;
    // Consider storing array contents in NSUserDefaults here
    [self.onOffSwitch setTitle:@"Start SpeakIt"];
    [self.onOffSwitch setAction:@selector(didClickBeginSpeakIt:)];
    NSLog(@"Stopped SpeakIt");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
