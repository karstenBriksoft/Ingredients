//
//  IGKXCPlugin.m
//  Ingredients
//
//  Created by Cédric Luthi on 11/03/2010.
//  Written in 2010 by Cédric Luthi.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

@interface Ingredients : NSObject
@end

@implementation Ingredients

static IMP IMP_XCDocSetAccessModule_searchForAPIString_ = NULL;

+ (void) searchForAPIString:(NSString *)searchString
{
	CFPreferencesSynchronize(CFSTR("net.fileability.ingredients"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	Boolean useAsXcodeBrowser = CFPreferencesGetAppBooleanValue(CFSTR("IGKXcodeBrowser"), CFSTR("net.fileability.ingredients"), NULL);
	
	if (useAsXcodeBrowser)
	{
		NSURL *ingredientsURL = [NSURL URLWithString:[NSString stringWithFormat:@"x-ingredients:search/%@", searchString]];
		[[NSWorkspace sharedWorkspace] openURL:ingredientsURL];
	}
	else
	{
		IMP_XCDocSetAccessModule_searchForAPIString_(self, _cmd, searchString);
	}
}

+ (void) postPluginAvailableNotification
{
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"IngredientsXcodePluginIsAvailable" object:nil];
}

+ (void) pluginDidLoad:(NSBundle *)plugin
{
	if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Xcode"])
		return;
	
	Class XCDocSetAccessModule = NSClassFromString(@"XCDocSetAccessModule");
	SEL searchForAPIString_ = @selector(searchForAPIString:);
	Method Ingredients_searchForAPIString_ = class_getClassMethod(self, searchForAPIString_);
	Method XCDocSetAccessModule_searchForAPIString_ = class_getInstanceMethod(XCDocSetAccessModule, searchForAPIString_);
	IMP_XCDocSetAccessModule_searchForAPIString_ = method_getImplementation(XCDocSetAccessModule_searchForAPIString_);
	method_setImplementation(XCDocSetAccessModule_searchForAPIString_, method_getImplementation(Ingredients_searchForAPIString_));
	
	NSString *pluginName = [[[plugin bundlePath] lastPathComponent] stringByDeletingPathExtension];
	NSString *version = [plugin objectForInfoDictionaryKey:@"CFBundleVersion"];
	if (XCDocSetAccessModule_searchForAPIString_)
	{
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(postPluginAvailableNotification) name:@"IsIngredientsXcodePluginAvailable" object:nil];
		[self postPluginAvailableNotification];
		NSLog(@"%@ %@ loaded successfully", pluginName, version);
	}
	else
		NSLog(@"%@ %@ failed to load", pluginName, version);
}

@end
