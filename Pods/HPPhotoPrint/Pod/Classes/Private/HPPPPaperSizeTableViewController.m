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

#import "HPPPPaperSizeTableViewController.h"
#import "HPPP.h"
#import "HPPPPaper.h"
#import "UIColor+HPPPStyle.h"
#import "UITableView+HPPPHeader.h"
#import "NSBundle+HPPPLocalizable.h"

NSString * const kPaperSizeScreenName = @"Paper Size Screen";

@interface HPPPPaperSizeTableViewController ()

@property (nonatomic, strong) HPPP *hppp;

@end

@implementation HPPPPaperSizeTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = HPPPLocalizedString(@"Paper Size", @"Title of the Paper Size screen");
    
    self.hppp = [HPPP sharedInstance];
    
    self.tableView.backgroundColor = [[HPPP sharedInstance].appearance.settings objectForKey:kHPPPGeneralBackgroundColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorColor = [[HPPP sharedInstance].appearance.settings objectForKey:kHPPPGeneralTableSeparatorColor];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kHPPPTrackableScreenNotification object:nil userInfo:[NSDictionary dictionaryWithObject:kPaperSizeScreenName forKey:kHPPPTrackableScreenNameKey]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self uniqueSizeTitles] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PaperSizeTableViewCellIdentifier"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PaperSizeTableViewCellIdentifier"];
    }
    
    cell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
    cell.textLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFont];
    cell.textLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
    
    cell.textLabel.text = [self uniqueSizeTitles][indexPath.row];
    
    if ([cell.textLabel.text isEqualToString:self.currentPaper.sizeTitle]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsCheckmarkImage]];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    for (NSInteger i = 0; i < [[self uniqueSizeTitles] count]; i++) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        cell.accessoryView = nil;
    }
    
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.accessoryView = [[UIImageView alloc] initWithImage:[self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsCheckmarkImage]];
    
    NSUInteger selectedSize = [HPPPPaper sizeFromTitle:selectedCell.textLabel.text];
    NSUInteger defaultSize = [[HPPPPaper defaultTypeForSize:selectedSize] unsignedIntegerValue];
    HPPPPaper *paper = [[HPPPPaper alloc] initWithPaperSize:selectedSize paperType:defaultSize];
    if ([paper supportsType:self.currentPaper.paperType]) {
        paper = [[HPPPPaper alloc] initWithPaperSize:selectedSize paperType:self.currentPaper.paperType];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
    
    if ([self.delegate respondsToSelector:@selector(paperSizeTableViewController:didSelectPaper:)]) {
        [self.delegate paperSizeTableViewController:self didSelectPaper:paper];
    }
}

- (NSArray *)uniqueSizeTitles
{
    NSMutableArray *sizeTitles = [NSMutableArray array];
    for (HPPPPaper *paper in [HPPP sharedInstance].supportedPapers) {
        if (![sizeTitles containsObject:paper.sizeTitle]) {
            [sizeTitles addObject:paper.sizeTitle];
        }
    }
    return sizeTitles;
}

@end
