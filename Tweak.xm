#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define PREF_PATH @"/var/mobile/Library/Preferences/com.ichitaso.hidekbsettings.plist"
#define Notify_Preferences "com.ichitaso.hidekbsettings.prefschanged"

static BOOL hideKBS;
static BOOL hideOneHand;

@interface UIInputSwitcherItem : NSObject
@property (nonatomic,copy) NSString *identifier;
@end

%hook UIInputSwitcherView
- (void)_reloadInputSwitcherItems {
	%orig;
    // Hide Keyboard Settings
    if (hideKBS) {
        NSMutableArray *items = MSHookIvar<NSMutableArray *>(self, "m_inputSwitcherItems");
        if (items.count > 1 &&
        ([[(UIInputSwitcherItem *)items[0] identifier] isEqualToString:@"launchkeyboardsettings"] ||
        [[(UIInputSwitcherItem *)items[0] identifier] isEqualToString:@"launchdictationsettings"]
        )) {
            [items removeObjectAtIndex:0];
        }
    }
}

- (BOOL)_isHandBiasSwitchVisible {
    // Hide One-Handed Keyboard
    if (hideOneHand) {
        return NO;
    } else {
        return %orig;
    }
}
%end

%hook UIKeyboardLayoutStar
- (void)_setBiasEscapeButtonVisible:(BOOL)arg1 {
    // Hide One-Handed Keyboard Arrow
    if (hideOneHand) {
        %orig(NO);
    } else {
        %orig;
    }
}
%end

static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    @autoreleasepool {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
        
        hideKBS = (BOOL)[dict[@"hideKBS"] ? : @YES boolValue];
        hideOneHand = (BOOL)[dict[@"hideOneHand"] ? : @YES boolValue];
    }
}

%ctor {
    @autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        settingsChanged,
                                        CFSTR(Notify_Preferences),
                                        NULL,
                                        CFNotificationSuspensionBehaviorCoalesce);
        
        settingsChanged(NULL, NULL, NULL, NULL, NULL);
    }
}
