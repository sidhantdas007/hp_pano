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

#import "HPPP.h"
#import "UITableView+HPPPHeader.h"
#import "UIColor+HPPPHexString.h"
#import "NSBundle+HPPPLocalizable.h"

#define TITLE_LEFT_OFFSET 10.0f
#define TITLE_HEIGHT 30.0f

@implementation UITableView (HPPPHeader)

- (UIView *)HPPPHeaderViewForSupportSection
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, HEADER_HEIGHT)];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(TITLE_LEFT_OFFSET, HEADER_HEIGHT - TITLE_HEIGHT, self.frame.size.width, TITLE_HEIGHT)];
    titleLabel.text =  HPPPLocalizedString(@"SUPPORT:", @"Title of a table section");
    titleLabel.font = [[HPPP sharedInstance].appearance.settings objectForKey:kHPPPGeneralBackgroundPrimaryFont];
    titleLabel.textColor = [[HPPP sharedInstance].appearance.settings objectForKey:kHPPPGeneralBackgroundPrimaryFontColor];
    
    [headerView addSubview:titleLabel];
    
    return headerView;
}

@end
