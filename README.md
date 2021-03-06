SLSpeakIt
=========
An Xcode plugin that transforms text or voice input into valid code. This is pre-alpha software, do not expect perfection or even functionality! If you are using Yosemite, all bets are off.

In progress and welcome collaborators.

To install and start using the plugin
--------------------------------------
Download the plugin and open the SLSpeakIt.xcodeproj file in Xcode. Build and run it, then restart Xcode. You should see a new menu item ("Start SpeakIt") in Xcode's Edit menu. 

Once the plugin is installed, open or create any Xcode file, choose "Start SpeakIt" from the Edit menu, and start coding in plain English! Type in the commands listed below, and the plugin will generate valid code (Objective-C at present). (Voice input also should work, but I need to build in more fuzziness to accept results that aren't exact matches for commands.) Please send any feedback to sunlovesystems@gmail.com 

--IMPORTANT-- **Commands may change.** This is pre-alpha software.

Currently, valid commands include: 

Variable creation and assignment
---------------------------------
+ Create an integer variable. Call it [wildcard]. Equal to [wildcard]. Next.
+ Create a float variable. Call it [wildcard]. Equal to [wildcard]. Next.
+ Create a double variable. Call it [wildcard]. Equal to [wildcard]. Next.
+ Create a string variable. Call it [wildcard]. Equal to [wildcard]. Next.
+ Create an unsigned integer variable. Call it [wildcard]. Equal to [wildcard]. Next.

Collection creation, population and selection
----------------------------------------------
+ Create an array. Call it [wildcard]. Next.
+ Create a mutable array. Call it [wildcard]. Next.
+ Create a set. Call it [wildcard]. Next.
+ Create a mutable set. Call it [wildcard]. Next.
+ Put item [wildcard] into collection [wildcard]. Next.
+ Remove [wildcard] from collection [wildcard]. Next.
+ Random item from collection [wildcard]. Next.

Control flow
-------------
+ Create a fast enumeration loop. For [wildcard] in collection [wildcard]. Next.
+ Create a for loop from start point [wildcard] to end point [wildcard], counting [up/down]. Next.
+ Create a while loop. While [wildcard] variable is [operator] [type] [wildcard]. Next. 
+ Create a while loop. While [wildcard] [exists/does not exist]. Next.
+ Create an [if/else if] statement. [If/Else if] [wildcard] variable is [operator] [type] [wildcard]. Next.
+ Create an [if/else if] statement. [If/Else if] [wildcard] [exists/does not exist]. Next.

[operator] = [not equal to/greater than or equal to/less than or equal to/equal to/greater than/less than]
[type] = [integer/float/double/string/bool]

Logging
--------
+ Print [wildcard]. Next.

Workflow
---------
+ Did I declare [wildcard]. Next.
+ Delete warning. Next.
+ Undo. Next. 

The command grammar will be refined toward a version 1.0 as more functionality is added. Commands need to be: 

1. Easy to learn.
2. Clear enough for voice recognition to pick up (i.e., “Create” instead of “Make”).
3. Detailed and unique enough to allow text replacement to find the right location in the file. 
4. Concise enough to be typed as text without causing major headaches.
