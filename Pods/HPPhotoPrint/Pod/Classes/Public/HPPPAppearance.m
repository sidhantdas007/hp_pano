//
// Hewlett-Packard Company
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

#import "HPPPAppearance.h"

@implementation HPPPAppearance

// General
NSString * const kHPPPGeneralBackgroundColor = @"kHPPPBackgroundBackgroundColor";
NSString * const kHPPPGeneralBackgroundPrimaryFont = @"kHPPPBackgroundPrimaryFont";
NSString * const kHPPPGeneralBackgroundPrimaryFontColor = @"kHPPPBackgroundPrimaryFontColor";
NSString * const kHPPPGeneralBackgroundSecondaryFont = @"kHPPPBackgroundSecondaryFont";
NSString * const kHPPPGeneralBackgroundSecondaryFontColor = @"kHPPPBackgroundSecondaryFontColor";
NSString * const kHPPPGeneralTableSeparatorColor = @"kHPPPGeneralTableSeparatorColor";

// Selection Options
NSString * const kHPPPSelectionOptionsBackgroundColor = @"kHPPPSelectionOptionsBackgroundColor";
NSString * const kHPPPSelectionOptionsPrimaryFont = @"kHPPPSelectionOptionsPrimaryFont";
NSString * const kHPPPSelectionOptionsPrimaryFontColor = @"kHPPPSelectionOptionsPrimaryFontColor";
NSString * const kHPPPSelectionOptionsSecondaryFont = @"kHPPPSelectionOptionsSecondaryFont";
NSString * const kHPPPSelectionOptionsSecondaryFontColor = @"kHPPPSelectionOptionsSecondaryFontColor";
NSString * const kHPPPSelectionOptionsLinkFont = @"kHPPPSelectionOptionsLinkFont";
NSString * const kHPPPSelectionOptionsLinkFontColor = @"kHPPPSelectionOptionsLinkFontColor";
NSString * const kHPPPSelectionOptionsDisclosureIndicatorImage = @"kHPPPSelectionOptionsDisclosureIndicatorImage";
NSString * const kHPPPSelectionOptionsCheckmarkImage = @"kHPPPSelectionOptionsCheckmarkImage";

// Job Settings
NSString * const kHPPPJobSettingsBackgroundColor = @"kHPPPJobSettingsBackgroundColor";
NSString * const kHPPPJobSettingsPrimaryFont = @"kHPPPJobSettingsPrimaryFont";
NSString * const kHPPPJobSettingsPrimaryFontColor = @"kHPPPJobSettingsPrimaryFontColor";
NSString * const kHPPPJobSettingsSecondaryFont = @"kHPPPJobSettingsSecondaryFont";
NSString * const kHPPPJobSettingsSecondaryFontColor = @"kHPPPJobSettingsSecondaryFontColor";
NSString * const kHPPPJobSettingsSelectedPageIcon = @"kHPPPJobSettingsSelectedPageIcon";
NSString * const kHPPPJobSettingsUnselectedPageIcon = @"kHPPPJobSettingsUnselectedPageIcon";
NSString * const kHPPPJobSettingsSelectedJobIcon = @"kHPPPJobSettingsSelectedJobIcon";
NSString * const kHPPPJobSettingsUnselectedJobIcon = @"kHPPPJobSettingsUnselectedJobIcon";
NSString * const kHPPPJobSettingsMagnifyingGlassIcon = @"kHPPPJobSettingsMagnifyingGlassIcon";

// Main Action
NSString * const kHPPPMainActionBackgroundColor = @"kHPPPMainActionBackgroundColor";
NSString * const kHPPPMainActionLinkFont = @"kHPPPMainActionLinkFont";
NSString * const kHPPPMainActionActiveLinkFontColor = @"kHPPPMainActionActiveLinkFontColor";
NSString * const kHPPPMainActionInactiveLinkFontColor = @"kHPPPMainActionInactiveLinkFontColor";

// Queue Project Count
NSString * const kHPPPQueuePrimaryFont = @"kHPPPQueuePrimaryFont";
NSString * const kHPPPQueuePrimaryFontColor = @"kHPPPQueuePrimaryFontColor";

// Form Field
NSString * const kHPPPFormFieldBackgroundColor = @"kHPPPFormFieldBackgroundColor";
NSString * const kHPPPFormFieldPrimaryFont = @"kHPPPFormFieldPrimaryFont";
NSString * const kHPPPFormFieldPrimaryFontColor = @"kHPPPFormFieldPrimaryFontColor";

// Overlay
NSString * const kHPPPOverlayBackgroundColor = @"kHPPPOverlayBackgroundColor";
NSString * const kHPPPOverlayBackgroundOpacity = @"kHPPPOverlayBackgroundOpacity";
NSString * const kHPPPOverlayPrimaryFont = @"kHPPPOverlayPrimaryFont";
NSString * const kHPPPOverlayPrimaryFontColor = @"kHPPPOverlayPrimaryFontColor";
NSString * const kHPPPOverlaySecondaryFont = @"kHPPPOverlaySecondaryFont";
NSString * const kHPPPOverlaySecondaryFontColor = @"kHPPPOverlaySecondaryFontColor";
NSString * const kHPPPOverlayLinkFont = @"kHPPPOverlayLinkFont";
NSString * const kHPPPOverlayLinkFontColor = @"kHPPPOverlayLinkFontColor";

// Activity
NSString * const kHPPPActivityPrintIcon = @"kHPPPActivityPrintIcon";
NSString * const kHPPPActivityPrintQueueIcon = @"kHPPPActivityPrintQueueIcon";

- (NSDictionary *)settings
{
    if (nil == _settings) {
        _settings = [self defaultSettings];
    }
    
    return _settings;
}

- (NSString *)dateFormat
{
  return @"MMMM d, h:mma";
}

- (NSDictionary *)defaultSettings
{
    NSString *regularFont = @"HelveticaNeue";
    NSString *lightFont   = @"HelveticaNeue-Medium";
    
    _settings = @{// General
                  kHPPPGeneralBackgroundColor:             [UIColor colorWithRed:0xEF/255.0F green:0xEF/255.0F blue:0xF4/255.0F alpha:1.0F],
                  kHPPPGeneralBackgroundPrimaryFont:       [UIFont fontWithName:regularFont size:14],
                  kHPPPGeneralBackgroundPrimaryFontColor:  [UIColor colorWithRed:0x33/255.0F green:0x33/255.0F blue:0x33/255.0F alpha:1.0F],
                  kHPPPGeneralBackgroundSecondaryFont:     [UIFont fontWithName:lightFont size:12],
                  kHPPPGeneralBackgroundSecondaryFontColor:[UIColor colorWithRed:0x33/255.0F green:0x33/255.0F blue:0x33/255.0F alpha:1.0F],
                  kHPPPGeneralTableSeparatorColor:         [UIColor colorWithRed:0xC8/255.0F green:0xC7/255.0F blue:0xCC/255.0F alpha:1.0F],
                  
                  // Selection Options
                  kHPPPSelectionOptionsBackgroundColor:         [UIColor colorWithRed:0xFF/255.0F green:0xFF/255.0F blue:0xFF/255.0F alpha:1.0F],
                  kHPPPSelectionOptionsPrimaryFont:             [UIFont fontWithName:regularFont size:16],
                  kHPPPSelectionOptionsPrimaryFontColor:        [UIColor colorWithRed:0x00/255.0F green:0x00/255.0F blue:0x00/255.0F alpha:1.0F],
                  kHPPPSelectionOptionsSecondaryFont:           [UIFont fontWithName:regularFont size:16],
                  kHPPPSelectionOptionsSecondaryFontColor:      [UIColor colorWithRed:0x8E/255.0F green:0x8E/255.0F blue:0x93/255.0F alpha:1.0F],
                  kHPPPSelectionOptionsLinkFont:                [UIFont fontWithName:regularFont size:16],
                  kHPPPSelectionOptionsLinkFontColor:           [UIColor colorWithRed:0x00/255.0F green:0x7A/255.0F blue:0xFF/255.0F alpha:1.0F],
                  kHPPPSelectionOptionsDisclosureIndicatorImage:[UIImage imageNamed:@"HPPPArrow"],
                  kHPPPSelectionOptionsCheckmarkImage:          [UIImage imageNamed:@"HPPPCheck"],
                  
                  // Job Settings
                  kHPPPJobSettingsBackgroundColor:    [UIColor colorWithRed:0xFF/255.0F green:0xFF/255.0F blue:0xFF/255.0F alpha:1.0F],
                  kHPPPJobSettingsPrimaryFont:        [UIFont fontWithName:regularFont size:16],
                  kHPPPJobSettingsPrimaryFontColor:   [UIColor colorWithRed:0x00/255.0F green:0x00/255.0F blue:0x00/255.0F alpha:1.0F],
                  kHPPPJobSettingsSecondaryFont:      [UIFont fontWithName:regularFont size:12],
                  kHPPPJobSettingsSecondaryFontColor: [UIColor colorWithRed:0x00/255.0F green:0x00/255.0F blue:0x00/255.0F alpha:1.0F],
                  kHPPPJobSettingsSelectedPageIcon:   [UIImage imageNamed:@"HPPPSelected"],
                  kHPPPJobSettingsUnselectedPageIcon: [UIImage imageNamed:@"HPPPUnselected"],
                  kHPPPJobSettingsSelectedJobIcon:    [UIImage imageNamed:@"HPPPActiveCircle"],
                  kHPPPJobSettingsUnselectedJobIcon:  [UIImage imageNamed:@"HPPPInactiveCircle"],
                  kHPPPJobSettingsMagnifyingGlassIcon:[UIImage imageNamed:@"HPPPMagnify"],
                  
                  // Main Action
                  kHPPPMainActionBackgroundColor:       [UIColor colorWithRed:0xFF/255.0F green:0xFF/255.0F blue:0xFF/255.0F alpha:1.0F],
                  kHPPPMainActionLinkFont:              [UIFont fontWithName:regularFont size:18],
                  kHPPPMainActionActiveLinkFontColor:   [UIColor colorWithRed:0x00/255.0F green:0x7A/255.0F blue:0xFF/255.0F alpha:1.0F],
                  kHPPPMainActionInactiveLinkFontColor: [UIColor colorWithRed:0xAA/255.0F green:0xAA/255.0F blue:0xAA/255.0F alpha:1.0F],
                  
                  // Queue Project Count
                  kHPPPQueuePrimaryFont:     [UIFont fontWithName:regularFont size:16],
                  kHPPPQueuePrimaryFontColor:[UIColor colorWithRed:0x00 green:0x00 blue:0x00 alpha:1.0F],
                  
                  // Form Field
                  kHPPPFormFieldBackgroundColor:  [UIColor colorWithRed:0xFF/255.0F green:0xFF/255.0F blue:0xFF/255.0F alpha:1.0F],
                  kHPPPFormFieldPrimaryFont:      [UIFont fontWithName:regularFont size:16],
                  kHPPPFormFieldPrimaryFontColor: [UIColor colorWithRed:0x00/255.0F green:0x00/255.0F blue:0x00/255.0F alpha:1.0F],
                  
                  // Overlay
                  kHPPPOverlayBackgroundColor:    [UIColor colorWithRed:0x00/255.0F green:0x00/255.0F blue:0x00/255.0F alpha:1.0F],
                  kHPPPOverlayBackgroundOpacity:  [NSNumber numberWithFloat:.80F],
                  kHPPPOverlayPrimaryFont:        [UIFont fontWithName:regularFont size:16],
                  kHPPPOverlayPrimaryFontColor:   [UIColor colorWithRed:0xFF/255.0F green:0xFF/255.0F blue:0xFF/255.0F alpha:1.0F],
                  kHPPPOverlaySecondaryFont:      [UIFont fontWithName:regularFont size:14],
                  kHPPPOverlaySecondaryFontColor: [UIColor colorWithRed:0xFF/255.0F green:0xFF/255.0F blue:0xFF/255.0F alpha:1.0F],
                  kHPPPOverlayLinkFont:           [UIFont fontWithName:regularFont size:18],
                  kHPPPOverlayLinkFontColor:      [UIColor colorWithRed:0xFF/255.0F green:0xFF/255.0F blue:0xFF/255.0F alpha:1.0F],
                  
                  // Activity
                  kHPPPActivityPrintIcon:      [UIImage imageNamed:@"HPPPPrint"],
                  kHPPPActivityPrintQueueIcon: [UIImage imageNamed:@"HPPPPrintLater"],
                  };
    
    return _settings;
}

// This function is helpful in finding desired font names
- (void)listAllFonts
{
    NSArray *familyNames = [[NSArray alloc] initWithArray:[UIFont familyNames]];
    NSArray *fontNames;
    NSInteger indFamily, indFont;
    for (indFamily=0; indFamily<[familyNames count]; ++indFamily)
    {
        NSLog(@"Family name: %@", [familyNames objectAtIndex:indFamily]);
        fontNames = [[NSArray alloc] initWithArray:
                     [UIFont fontNamesForFamilyName:
                      [familyNames objectAtIndex:indFamily]]];
        for (indFont=0; indFont<[fontNames count]; ++indFont)
        {
            NSLog(@"    Font name: %@", [fontNames objectAtIndex:indFont]);
        }
    }
}

@end
