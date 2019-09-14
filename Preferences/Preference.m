#import <UIKit/UIKit.h>
#import "Preferences.h"
#import <SafariServices/SafariServices.h>
#import <spawn.h>

static void easy_spawn(const char* args[]) {
    pid_t pid;
    int status;
    posix_spawn(&pid, args[0], NULL, NULL, (char* const*)args, NULL);
    waitpid(pid, &status, WEXITED);
}

@interface PSSpecifier (Private)
- (void)setIdentifier:(NSString *)identifier;
@end

@interface PSListController (Private)
- (void)loadView;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)_returnKeyPressed:(id)arg1;
- (void)presentViewController:(id)arg1 animated:(BOOL)arg2 completion:(id)arg3;
@end

@interface PSTableCell (Private)
@property(readonly, assign, nonatomic) UILabel* textLabel;
@end

static CGFloat const kHBFPHeaderTopInset = 64.f;
static CGFloat const kHBFPHeaderHeight = 160.f;

@interface HideKBSettingsController : PSListController {
    CGRect topFrame;
    UILabel *bannerTitle;
    UILabel *footerLabel;
}
- (void)respringPrefs:(NSNotification *)notification;
- (void)respring;
@property(retain) UIView *bannerView;
@end

@class PSSpecifier;

#define PREF_PATH @"/var/mobile/Library/Preferences/com.ichitaso.hidekbsettings.plist"
#define Notify_Preferences "com.ichitaso.hidekbsettings.prefschanged"
#define Notify_Resprings "com.ichitaso.hidekbsettings.respring"

#define TWEAK_TITLE @"HideKBSettings"
#define TWEAK_DESCRIPTION @"Hide Keyboard Settings for iOS 11 & 12"

@implementation HideKBSettingsController
- (instancetype)init {
    self = [super init];
    
    // Respring Notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"respringPrefs" object:nil];
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)respringPrefsCallBack,
                                    CFSTR(Notify_Resprings),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respringPrefs:) name:@"respringPrefs" object:nil];
    
    return self;
}

void respringPrefsCallBack() {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"respringPrefs" object:nil];
}

- (void)respringPrefs:(NSNotification *)notification {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"Respring is required"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                      // Do Nothing
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Respring"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
                                                          [self respring];
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)respring {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/sbreload"]) {
        easy_spawn((const char *[]){"/usr/bin/sbreload", NULL});
    } else {
        easy_spawn((const char *[]){"/usr/bin/killall", "backboardd", NULL});
    }
}

- (void)loadView {
    [super loadView];
    
    CGFloat headerHeight = 0 + kHBFPHeaderHeight;
    CGRect selfFrame = [self.view frame];
    
    _bannerView = [[UIView alloc] init];
    _bannerView.frame = CGRectMake(0, -kHBFPHeaderHeight, selfFrame.size.width, headerHeight);
    _bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self.table addSubview:_bannerView];
    [self.table sendSubviewToBack:_bannerView];
    
    topFrame = CGRectMake(0, -kHBFPHeaderHeight, 414, kHBFPHeaderHeight);
    
    bannerTitle = [[UILabel alloc] init];
    bannerTitle.text = TWEAK_TITLE;
    [bannerTitle setFont:[UIFont fontWithName:@"HelveticaNeue-Ultralight" size:36]];
    bannerTitle.textColor = [UIColor blackColor];
    
    [_bannerView addSubview:bannerTitle];
    
    [bannerTitle setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerTitle attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0f]];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:20.0f]];
    bannerTitle.textAlignment = NSTextAlignmentCenter;//NSTextAlignmentRight;
    
    footerLabel = [[UILabel alloc] init];
    footerLabel.text = TWEAK_DESCRIPTION;
    [footerLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]];
    footerLabel.textColor = [UIColor grayColor];
    footerLabel.alpha = 1.0;
    
    [_bannerView addSubview:footerLabel];
    
    [footerLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:footerLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0f]];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:footerLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:60.0f]];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.table setContentInset:UIEdgeInsetsMake(kHBFPHeaderHeight-kHBFPHeaderTopInset,0,0,0)];
    [self.table setContentOffset:CGPointMake(0, -kHBFPHeaderHeight+kHBFPHeaderTopInset)];
}

- (NSArray *)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        PSSpecifier* spec;
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Settings"
                                              target:self
                                                 set:Nil
                                                 get:Nil
                                              detail:Nil
                                                cell:PSGroupCell
                                                edit:Nil];
        [spec setProperty:@"Hide \"Keyboard Settings\" button from the globe button 🌐 switcher."  forKey:@"footerText"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Hide Keyboard Settings"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSSwitchCell
                                                edit:Nil];
        [spec setProperty:@"hideKBS" forKey:@"key"];
        [spec setProperty:@YES forKey:@"default"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"Hide \"One-Handed Keyboard\" option from the globe button 🌐 switcher.\n\nOne Handed Keyboard mode can still be manually activated from \"Settings->General->Keyboard->One Handed Keyboard\"" forKey:@"footerText"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Hide One-Handed Keyboard"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSSwitchCell
                                                edit:Nil];
        [spec setProperty:@"hideOneHand" forKey:@"key"];
        [spec setProperty:@YES forKey:@"default"];
        [specifiers addObject:spec];
        
        
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Credit"
                                              target:self
                                                 set:Nil
                                                 get:Nil
                                              detail:Nil
                                                cell:PSGroupCell
                                                edit:Nil];
        [spec setProperty:@"Credit" forKey:@"label"];
        [spec setProperty:@"Special thanks: Based by A_H_Rabie on FLEX & @hirakujira\n\n© Will feel Tips by ichitaso" forKey:@"footerText"];
        [specifiers addObject:spec];
        
        NSString *mainBundle = [[self bundle] bundlePath];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Follow on Twitter"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSButtonCell
                                                edit:nil];
        
        spec->action = @selector(openTwitter);
        UIImage *image1 = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/twitter.png", mainBundle]];
        [spec setProperty:image1 forKey:@"iconImage"];
        [specifiers addObject:spec];
                
        spec = [PSSpecifier preferenceSpecifierNamed:@"Donate"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        
        spec->action = @selector(donate);
        UIImage *image2 = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/paypal.png", mainBundle]];
        [spec setProperty:image2 forKey:@"iconImage"];
        [specifiers addObject:spec];
        
        _specifiers = [specifiers copy];
    }
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    @autoreleasepool {
        NSMutableDictionary *EnablePrefsCheck = [[NSMutableDictionary alloc] initWithContentsOfFile:PREF_PATH]?:[NSMutableDictionary dictionary];
        [EnablePrefsCheck setObject:value forKey:[specifier identifier]];
        
        // Write if you need Respring
        //if ([[specifier identifier] isEqualToString:@"hideKBS"]) {
        //   CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(Notify_Resprings), NULL, NULL, YES);
        //}
        
        [EnablePrefsCheck writeToFile:PREF_PATH atomically:YES];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(Notify_Preferences), NULL, NULL, YES);
    }
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    @autoreleasepool {
        NSDictionary *EnablePrefsCheck = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
        return EnablePrefsCheck[[specifier identifier]]?:[[specifier properties] objectForKey:@"default"];
    }
}

- (void)openTwitter {
    NSString *twitterID = @"ichitaso";
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Follow on @ichitaso"
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Open in Tweetbot" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///user_profile/%@",twitterID]]
                                               options:@{}
                                     completionHandler:nil];
        }]];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Open in Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@",twitterID]]
                                               options:@{}
                                     completionHandler:nil];
        }]];
    }
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Open in Browser" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        double delayInSeconds = 0.8;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self openURLInBrowser:[NSString stringWithFormat:@"https://twitter.com/%@",twitterID]];
        });
    }]];
    
    // Fix Crash for iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect rect = self.view.frame;
        alertController.popoverPresentationController.sourceView = self.view;
        alertController.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(rect)-60,rect.size.height-50, 120,50);
        alertController.popoverPresentationController.permittedArrowDirections = 0; // Hide Callout Arrow
    } else {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
        }]];
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)donate {
    [self openURLInBrowser:@"https://cydia.ichitaso.com/donation.html"];
}

- (void)openURLInBrowser:(NSString *)url {
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
    [self presentViewController:safari animated:YES completion:nil];
}

@end
