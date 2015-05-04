#import <substrate.h>
#import <sys/sysctl.h>
#import <Preferences/PSListController.h>
#import <Preferences/Preferences.h>
#import <Preferences/PSSpecifier.h>

extern "C" CFPropertyListRef MGCopyAnswer(CFStringRef);

@interface PSMagnifyMode : NSObject
@end

@interface PSMagnifyController : PSListController
@end

BOOL hook = NO;
BOOL deviceNameOverride = NO;
BOOL deviceNameOverride2 = NO;

NSArray *(*PSGetMagnifyModes)();
NSArray *(*original_PSGetMagnifyModes)();
NSArray *hax_PSGetMagnifyModes()
{
	hook = YES;
	NSArray *modes = original_PSGetMagnifyModes();
	hook = NO;
	return modes;
}

%hook PSMagnifyController

- (id)init
{
	hook = YES;
	id orig = %orig;
	hook = NO;
	return orig;
}

+ (NSString *)localizedMagnifyModeName
{
	hook = YES;
	NSString *orig = %orig;
	hook = NO;
	return orig;
}

+ (PSMagnifyMode *)currentMagnifyMode
{
	hook = YES;
	PSMagnifyMode *orig = %orig;
	hook = NO;
	return orig;
}

- (void)loadView
{
	hook = YES;
	%orig;
	hook = NO;
}

- (void)finishDone:(id)arg1
{
	deviceNameOverride2 = YES;
	%orig;
	deviceNameOverride2 = NO;
}

%end

%hook UIDevice

+ (NSString *)modelSpecificLocalizedStringKeyForKey:(NSString *)key
{
	deviceNameOverride = [key isEqualToString:@"DISPLAY_ZOOM_DESCRIPTION"] || [key isEqualToString:@"CONFIRMATION_PROMPT"];
	NSString *orig = %orig;
	deviceNameOverride = NO;
	return orig;
}

%end

%hook NSBundle

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)table
{
	BOOL hook = [table isEqualToString:@"Magnify"] && deviceNameOverride2;
	NSString *orig = %orig;
	if (hook) {
		CFStringRef deviceName = (CFStringRef)MGCopyAnswer(CFSTR("GSDeviceName"));
		NSString *newString = [orig stringByReplacingOccurrencesOfString:@"iPhone" withString:(NSString *)deviceName];
		CFRelease(deviceName);
		return newString;
	}
	return orig;
}

%end

%hook DisplayController

- (NSMutableArray *)specifiers
{
	if (MSHookIvar<NSMutableArray *>(self, "_specifiers") != nil)
		return %orig();
	deviceNameOverride2 = YES;
	NSMutableArray *specifiers = %orig();
	deviceNameOverride2 = NO;
	BOOL shouldMove = YES;
	NSUInteger index1 = NSNotFound;
	NSUInteger index2 = NSNotFound;
	NSString *identifier = nil;
	for (PSSpecifier *spec in specifiers) {
		identifier = [spec propertyForKey:@"id"];
		if ([identifier isEqualToString:@"AUTO_BRIGHTNESS"]) {
			shouldMove = NO;
		}
		if ([identifier isEqualToString:@"DISPLAY_ZOOM_GROUP"]) {
			index1 = [specifiers indexOfObject:spec];
		}
		else if ([identifier isEqualToString:@"MAGNIFY"]) {
			index2 = [specifiers indexOfObject:spec];
		}
	}
	if (shouldMove) {
		id object = [[[specifiers objectAtIndex:3] retain] autorelease];
		[specifiers removeObjectAtIndex:3];
		[specifiers insertObject:object atIndex:1];
	}	
	return specifiers;
}

%end

MSHook(CFPropertyListRef, MGCopyAnswer, CFStringRef key)
{
	if (CFEqual(key, CFSTR("HWModelStr")) && hook)
		return CFSTR("N61AP");
	if (CFEqual(key, CFSTR("GSDeviceName")) & deviceNameOverride && deviceNameOverride2)
		return CFSTR("iPhone");
    return _MGCopyAnswer(key);
}

%ctor
{
	const char *pref = "/System/Library/PrivateFrameworks/Preferences.framework/Preferences";
	MSHookFunction(MGCopyAnswer, MSHake(MGCopyAnswer));
	MSImageRef ref = MSGetImageByName(pref);
	const char *func1 = "___PSGetMagnifyModes_block_invoke";
	PSGetMagnifyModes = (NSArray *(*)())MSFindSymbol(ref, func1);
	MSHookFunction((void *)PSGetMagnifyModes, (void *)hax_PSGetMagnifyModes, (void **)&original_PSGetMagnifyModes);
	%init;
}
