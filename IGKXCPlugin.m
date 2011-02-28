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

static IMP IMP_IGKXCPlugin_SwizzledMethod = NULL;

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
		IMP_IGKXCPlugin_SwizzledMethod(self, _cmd, searchString);
	}
}

+ (void)generateHTMLForSymbol:(id)symbol fromQueryDictionary:(NSDictionary*)queryDict inExpressionSource:(id)source
{
	[self searchForAPIString:[symbol performSelector:@selector(name)]];
}

+ (void) postPluginAvailableNotification
{
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"IngredientsXcodePluginIsAvailable" object:nil];
}

+ (BOOL)swizzleSelectorNamed:(NSString*)aSelectorString inClassNamed:(NSString*)aClassName
{
	Class targetClass = NSClassFromString(aClassName);
	
	if (targetClass == nil) return NO;
	
	SEL selector = NSSelectorFromString(aSelectorString);
	
	Method myImplementation = class_getClassMethod(self, selector);
	Method xcodeImplementation = class_getInstanceMethod(targetClass, selector);
	
	IMP_IGKXCPlugin_SwizzledMethod = method_getImplementation(xcodeImplementation);
	method_setImplementation(xcodeImplementation, method_getImplementation(myImplementation));
	
	return xcodeImplementation != nil;	
}

+ (BOOL)swizzleXcode3
{
	return [self swizzleSelectorNamed:@"searchForAPIString:" inClassNamed: @"XCDocSetAccessModule"];
}

+ (BOOL)swizzleXcode4
{
	return [self swizzleSelectorNamed:@"generateHTMLForSymbol:fromQueryDictionary:inExpressionSource:" inClassNamed: @"IDEQuickHelpController"];
}

+ (void) pluginDidLoad:(NSBundle *)plugin
{
	NSArray* xcodeBundleIDs = [NSArray arrayWithObjects:@"com.apple.Xcode", @"com.apple.dt.Xcode",nil];
	if (![xcodeBundleIDs containsObject:[[NSBundle mainBundle] bundleIdentifier]])
		return;

	NSString *pluginName = [[[plugin bundlePath] lastPathComponent] stringByDeletingPathExtension];
	NSString *version = [plugin objectForInfoDictionaryKey:@"CFBundleVersion"];

	BOOL couldSwizzle = [self swizzleXcode3] || [self swizzleXcode4];
	
	if (couldSwizzle)
	{
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(postPluginAvailableNotification) name:@"IsIngredientsXcodePluginAvailable" object:nil];
		[self postPluginAvailableNotification];
		NSLog(@"%@ %@ loaded successfully", pluginName, version);
	}
	else
		NSLog(@"%@ %@ failed to load", pluginName, version);
}

@end
