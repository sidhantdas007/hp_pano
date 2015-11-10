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
#import "HPPPAnalyticsManager.h"
#import "HPPPPageSettingsTableViewController.h"
#import "HPPPPaper.h"
#import "HPPPPrintPageRenderer.h"
#import "HPPPPrintSettings.h"
#import "HPPPPrintItem.h"
#import "HPPPPaperSizeTableViewController.h"
#import "HPPPPaperTypeTableViewController.h"
#import "HPPPPrintSettingsTableViewController.h"
#import "HPPPWiFiReachability.h"
#import "HPPPPrinter.h"
#import "HPPPPrintLaterManager.h"
#import "HPPPDefaultSettingsManager.h"
#import "HPPPPrintSettingsDelegateManager.h"
#import "UITableView+HPPPHeader.h"
#import "UIColor+HPPPHexString.h"
#import "UIView+HPPPAnimation.h"
#import "UIImage+HPPPResize.h"
#import "UIColor+HPPPStyle.h"
#import "NSBundle+HPPPLocalizable.h"
#import "HPPPSupportAction.h"
#import "HPPPLayoutFactory.h"
#import "HPPPMultiPageView.h"
#import "HPPPPageRangeKeyboardView.h"
#import "HPPPPageRange.h"
#import "HPPPPrintManager.h"
#import "HPPPPrintManager+Options.h"
#import "HPPPPrintJobsViewController.h"
#import "HPPPPrintLaterQueue.h"


#define REFRESH_PRINTER_STATUS_INTERVAL_IN_SECONDS 60

#define DEFAULT_ROW_HEIGHT 44.0f
#define DEFAULT_NUMBER_OF_COPIES 1

#define BASIC_PRINT_SUMMARY_SECTION 0
#define PREVIEW_PRINT_SUMMARY_SECTION 1
#define PRINT_FUNCTION_SECTION 2
#define PRINTER_SELECTION_SECTION 3
#define PAPER_SELECTION_SECTION 4
#define PRINT_SETTINGS_SECTION 5
#define PRINT_JOB_NAME_SECTION 6
#define PAGE_RANGE_SECTION 7
#define NUMBER_OF_COPIES_SECTION 8
#define BLACK_AND_WHITE_FILTER_SECTION 9
#define SUPPORT_SECTION 10

#define PRINTER_SELECTION_INDEX 0
#define PAPER_SIZE_ROW_INDEX 0
#define PAPER_TYPE_ROW_INDEX 1
#define PRINT_SETTINGS_ROW_INDEX 0
#define FILTER_ROW_INDEX 0
#define PAGE_RANGE_ROW_INDEX 1

#define kHPPPSelectPrinterPrompt HPPPLocalizedString(@"Select Printer", nil)
#define kPrinterDetailsNotAvailable HPPPLocalizedString(@"Not Available", @"Printer details not available")

@interface HPPPPageSettingsTableViewController ()
   <UIGestureRecognizerDelegate,
    HPPPMultiPageViewDelegate,
    UIAlertViewDelegate,
    HPPPPrintManagerDelegate,
    UITextFieldDelegate>

@property (strong, nonatomic) HPPPPrintManager *printManager;
@property (strong, nonatomic) HPPPWiFiReachability *wifiReachability;

@property (weak, nonatomic) IBOutlet UIStepper *numberOfCopiesStepper;
@property (weak, nonatomic) IBOutlet UISwitch *blackAndWhiteModeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *paperSizeSelectedLabel;
@property (weak, nonatomic) IBOutlet UILabel *paperTypeSelectedLabel;
@property (weak, nonatomic) IBOutlet UILabel *paperSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *paperTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *filterLabel;
@property (weak, nonatomic) IBOutlet UILabel *pageRangeLabel;
@property (weak, nonatomic) IBOutlet UITextField *pageRangeDetailTextField;
@property (weak, nonatomic) IBOutlet UILabel *printLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectPrinterLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectedPrinterLabel;
@property (weak, nonatomic) IBOutlet UILabel *printSettingsLabel;
@property (weak, nonatomic) IBOutlet UILabel *printSettingsDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *jobNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *jobNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *numberOfCopiesLabel;
@property (weak, nonatomic) IBOutlet HPPPMultiPageView *multiPageView;
@property (weak, nonatomic) IBOutlet UILabel *footerHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *footerTextLabel;

@property (weak, nonatomic) UITableViewCell *jobSummaryCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *basicJobSummaryCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *previewJobSummaryCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *printCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *selectPrinterCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *paperSizeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *paperTypeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *pageRangeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *filterCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *printSettingsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *jobNameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *numberOfCopiesCell;
@property (weak, nonatomic) IBOutlet UIView *footerView;

@property (strong, nonatomic) UIButton *pageSelectionMark;
@property (strong, nonatomic) UIImage *selectedPageImage;
@property (strong, nonatomic) UIImage *unselectedPageImage;

@property (strong, nonatomic) HPPPPrintSettingsDelegateManager *delegateManager;

@property (strong, nonatomic) UIBarButtonItem *cancelBarButtonItem;

@property (strong, nonatomic) NSTimer *refreshPrinterStatusTimer;

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) HPPP *hppp;
@property (nonatomic, assign) NSInteger numberOfCopies;

@property (strong, nonatomic) NSMutableArray *itemsToPrint;
@property (strong, nonatomic) NSMutableArray *pageRanges;
@property (strong, nonatomic) NSMutableArray *blackAndWhiteSelections;
@property (strong, nonatomic) NSMutableArray *numCopySelections;

@property (assign, nonatomic) BOOL editing;
@property (weak, nonatomic) IBOutlet UIView *headerInactivityView;

@end

@implementation HPPPPageSettingsTableViewController

int const kSaveDefaultPrinterIndex = 1;

NSString * const kHPPPDefaultPrinterAddedNotification = @"kHPPPDefaultPrinterAddedNotification";
NSString * const kHPPPDefaultPrinterRemovedNotification = @"kHPPPDefaultPrinterRemovedNotification";
NSString * const kPageSettingsScreenName = @"Print Preview Screen";
NSString * const kPrintFromQueueScreenName = @"Add Job Screen";
NSString * const kSettingsOnlyScreenName = @"Print Settings Screen";

#pragma mark - UIView

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if( nil == self.delegateManager ) {
        self.delegateManager = [[HPPPPrintSettingsDelegateManager alloc] init];
    }
    
    self.hppp = [HPPP sharedInstance];
    
    self.cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonTapped:)];

    if( self.hppp.pageSettingsCancelButtonLeft ) {
        self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = self.cancelBarButtonItem;
    }    
    
    if( HPPPPageSettingsDisplayTypePreviewPane == self.displayType ) {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    [self configureJobSummaryCell];
    
    if( nil != self.printItem ) {
        self.delegateManager.pageRange = [[HPPPPageRange alloc] initWithString:kPageRangeAllPages allPagesIndicator:kPageRangeAllPages maxPageNum:self.printItem.numberOfPages sortAscending:YES];
    } else {
        self.delegateManager.pageRange = nil;
    }
    self.delegateManager.pageRange.range = kPageRangeAllPages;
    self.delegateManager.numCopies = DEFAULT_NUMBER_OF_COPIES;

    if (self.navigationController) {
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    } else {
        [[HPPPLogger sharedInstance] logWarn:@"HPPPPageSettingsTableViewController is intended to be embedded in navigation controller. Navigation problems and othe unexpected behavior may occur if used without a navigation controller."];
    }
    
    self.tableView.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPGeneralBackgroundColor];
    self.tableView.separatorColor = [self.hppp.appearance.settings objectForKey:kHPPPGeneralTableSeparatorColor];
    self.tableView.rowHeight = DEFAULT_ROW_HEIGHT;
    
    if (HPPPPageSettingsDisplayTypePageSettingsPane == self.displayType  ||  (HPPPPageSettingsModeSettingsOnly == self.mode && nil == self.printItem)) {
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    self.multiPageView.delegate = self;
    
    self.tableView.tableFooterView.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPGeneralBackgroundColor];
    self.tableView.tableHeaderView.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPGeneralBackgroundColor];

    self.basicJobSummaryCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsBackgroundColor];
    self.basicJobSummaryCell.textLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsSecondaryFont];
    self.basicJobSummaryCell.textLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsSecondaryFontColor];

    self.previewJobSummaryCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsBackgroundColor];
    self.previewJobSummaryCell.textLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsPrimaryFont];
    self.previewJobSummaryCell.textLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsPrimaryFontColor];
    self.previewJobSummaryCell.detailTextLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsSecondaryFont];
    self.previewJobSummaryCell.detailTextLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsSecondaryFontColor];

    self.printCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPMainActionBackgroundColor];
    self.printLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPMainActionLinkFont];
    self.printLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPMainActionActiveLinkFontColor];
    self.printLabel.text = HPPPLocalizedString(@"Print", @"Caption of the button for printing");
    
    self.printSettingsCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
    self.printSettingsCell.accessoryView = [[UIImageView alloc] initWithImage:[self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsDisclosureIndicatorImage]];
    self.printSettingsLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFont];
    self.printSettingsLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
    self.printSettingsLabel.text = HPPPLocalizedString(@"Settings", nil);
    
    self.printSettingsDetailLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFont];
    self.printSettingsDetailLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFontColor];
    
    self.selectPrinterCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
    self.selectPrinterLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFont];
    self.selectPrinterLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
    self.selectPrinterLabel.text = HPPPLocalizedString(@"Printer", nil);
    
    self.selectedPrinterLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFont];
    self.selectedPrinterLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFontColor];
    self.selectedPrinterLabel.text = HPPPLocalizedString(@"Select Printer", nil);
    
    self.paperSizeCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
    self.paperSizeCell.accessoryView = [[UIImageView alloc] initWithImage:[self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsDisclosureIndicatorImage]];
    self.paperSizeLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFont];
    self.paperSizeLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
    self.paperSizeLabel.text = HPPPLocalizedString(@"Paper Size", nil);
    
    self.paperSizeSelectedLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFont];
    self.paperSizeSelectedLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFontColor];
    
    self.paperTypeCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
    self.paperTypeCell.accessoryView = [[UIImageView alloc] initWithImage:[self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsDisclosureIndicatorImage]];
    self.paperTypeLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFont];
    self.paperTypeLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
    self.paperTypeLabel.text = HPPPLocalizedString(@"Paper Type", nil);
    
    self.paperTypeSelectedLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFont];
    self.paperTypeSelectedLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFontColor];
    self.paperTypeSelectedLabel.text = [HPPPPaper titleFromType:HPPPPaperTypePlain];
    
    self.jobNameCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
    self.jobNameLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFont];
    self.jobNameLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
    self.jobNameTextField.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFont];
    self.jobNameTextField.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFontColor];
    self.jobNameTextField.returnKeyType = UIReturnKeyDone;
    self.jobNameTextField.delegate = self;
    
    self.numberOfCopiesCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
    self.numberOfCopiesLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFont];
    self.numberOfCopiesLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
    self.numberOfCopiesLabel.text = HPPPLocalizedString(@"1 Copy", nil);
    
    self.pageRangeCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
    [self setPageRangeLabelText:kPageRangeAllPages];

    self.pageRangeLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFont];
    self.pageRangeLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
    self.pageRangeDetailTextField.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFont];
    self.pageRangeDetailTextField.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsSecondaryFontColor];
    self.pageRangeDetailTextField.delegate = self;
    
    self.selectedPageImage = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsSelectedPageIcon];
    self.unselectedPageImage = [self.hppp.appearance.settings objectForKey:kHPPPJobSettingsUnselectedPageIcon];
    self.pageSelectionMark = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.pageSelectionMark setImage:self.selectedPageImage forState:UIControlStateNormal];
    self.pageSelectionMark.backgroundColor = [UIColor clearColor];
    self.pageSelectionMark.adjustsImageWhenHighlighted = NO;
    [self.pageSelectionMark addTarget:self action:@selector(pageSelectionMarkClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pageSelectionMark];
    
    self.filterCell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
    self.filterLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFont];
    self.filterLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
    self.filterLabel.text = HPPPLocalizedString(@"Black & White mode", nil);
    self.blackAndWhiteModeSwitch.onTintColor = [self.hppp.appearance.settings objectForKey:kHPPPMainActionActiveLinkFontColor];
    
    self.delegateManager.printSettings = [[HPPPPrintSettings alloc] init];
    [self.delegateManager loadLastUsed];
    self.delegateManager.printSettings.printerIsAvailable = YES;
    self.blackAndWhiteModeSwitch.on = self.delegateManager.blackAndWhite;
     
    if (self.hppp.hideBlackAndWhiteOption) {
        self.filterCell.hidden = YES;
    }
    
    self.numberOfCopies = self.delegateManager.numCopies;
    self.numberOfCopiesStepper.value = self.delegateManager.numCopies;
    self.numberOfCopiesStepper.tintColor = [self.hppp.appearance.settings objectForKey:kHPPPMainActionActiveLinkFontColor];
    
    [self reloadPaperSelectionSection];
    
    self.footerHeadingLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPGeneralBackgroundPrimaryFont];
    self.footerHeadingLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPGeneralBackgroundPrimaryFontColor];
    self.footerTextLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPGeneralBackgroundSecondaryFont];
    self.footerTextLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPGeneralBackgroundSecondaryFontColor];
    
    [self updatePrintSettingsUI];
    [[HPPPPrinter sharedInstance] checkLastPrinterUsedAvailability];
    [self updatePageSettingsUI];
    
    if ([self.dataSource respondsToSelector:@selector(numberOfPrintingItems)]) {
        NSInteger numberOfJobs = [self.dataSource numberOfPrintingItems];
        
        self.printLabel.text = [self stringFromNumberOfPrintingItems:numberOfJobs copies:1];
    }
    
    if (IS_OS_8_OR_LATER && HPPPPageSettingsDisplayTypePreviewPane != self.displayType) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidCheckPrinterAvailability:) name:kHPPPPrinterAvailabilityNotification object:nil];
        self.refreshPrinterStatusTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_PRINTER_STATUS_INTERVAL_IN_SECONDS
                                                                          target:self
                                                                        selector:@selector(refreshPrinterStatus:)
                                                                        userInfo:nil
                                                                         repeats:YES];
    }

    [self preparePrintManager];
    [self refreshData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self preparePrintManager];

    if (self.printItem) {
        [self configurePrintButton];
        [self refreshData];
        if( HPPPPageSettingsModeAddToQueue != self.mode && HPPPPageSettingsModeSettingsOnly != self.mode ) {
            if (![[HPPPWiFiReachability sharedInstance] isWifiConnected]) {
                [[HPPPWiFiReachability sharedInstance] noPrintingAlert];
            }
        }
    }
    
    if( self.printLaterJob ) {
        if( HPPPPageSettingsModeAddToQueue != self.mode ) {
            self.delegateManager.pageRange = self.printLaterJob.pageRange;
            self.delegateManager.blackAndWhite = self.printLaterJob.blackAndWhite;
            self.delegateManager.numCopies = self.printLaterJob.numCopies;
        }
        self.delegateManager.jobName = self.printLaterJob.name;
    }
    
    if( HPPPPageSettingsDisplayTypePreviewPane == self.displayType ) {
        self.title = HPPPLocalizedString(@"Preview", @"Title of the Preview pane in any print or add-to-queue screen");
    } else {
        if( HPPPPageSettingsModeAddToQueue == self.mode ) {
            self.title = HPPPLocalizedString(@"Add Print", @"Title of the Add Print to the Print Later Queue Screen");
            self.delegateManager.pageSettingsViewController = self;
        } else if( HPPPPageSettingsModeSettingsOnly == self.mode ) {
            self.title = HPPPLocalizedString(@"Print Settings", @"Title of the screen for setting default print settings");
            self.delegateManager.pageSettingsViewController = self;
        } else {
            self.title = HPPPLocalizedString(@"Page Settings", @"Title of the Page Settings Screen");
            self.delegateManager.pageSettingsViewController = self;
        }
    }
    
    if( HPPPPageSettingsModeAddToQueue == self.mode  &&  HPPPPageSettingsDisplayTypePreviewPane != self.displayType ) {
        self.tableView.tableFooterView = self.footerView;
    } else {
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    [self setPageRangeKeyboardView];
    
    [self configureJobSummaryCell];

    [self refreshData];
    
    NSString *screenName = kPageSettingsScreenName;
    if (HPPPPageSettingsModeSettingsOnly == self.mode) {
        screenName = kSettingsOnlyScreenName;
    } else if (HPPPPageSettingsModePrintFromQueue == self.mode) {
        screenName = kPrintFromQueueScreenName;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionEstablished:)
                                                 name:kHPPPWiFiConnectionEstablished
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionLost:)
                                                 name:kHPPPWiFiConnectionLost
                                               object:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:kHPPPTrackableScreenNotification object:nil userInfo:[NSDictionary dictionaryWithObject:screenName forKey:kHPPPTrackableScreenNameKey]];
}

-  (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kHPPPWiFiConnectionEstablished object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kHPPPWiFiConnectionLost object:nil];

    [self.refreshPrinterStatusTimer invalidate];
    self.refreshPrinterStatusTimer = nil;
    
    self.printManager.delegate = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
    [self.multiPageView refreshLayout];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if( HPPPPageSettingsDisplayTypePreviewPane == self.displayType ) {
        CGRect frame = self.tableView.tableHeaderView.frame;
        frame.size.height = size.height - self.jobSummaryCell.frame.size.height - 1;
        self.tableView.tableHeaderView.frame = frame;
        
        [self.multiPageView refreshLayout];
        
        // without this seemingly useless line, the header view is not displayed in the appropriate frame
        self.tableView.tableHeaderView = self.tableView.tableHeaderView;
    }
    
    [self setPageRangeKeyboardView];
    
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews
{
    [self.view layoutIfNeeded];
    
    [self.tableView bringSubviewToFront:self.pageSelectionMark];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Configure UI

- (void)changePaper
{
    static HPPPPaper *currentPaper = nil;
    if( currentPaper != self.delegateManager.printSettings.paper ) {
        currentPaper = self.delegateManager.printSettings.paper;
        
        if ([self.dataSource respondsToSelector:@selector(printingItemForPaper:withCompletion:)] && [self.dataSource respondsToSelector:@selector(previewImageForPaper:withCompletion:)]) {
            [self.dataSource printingItemForPaper:self.delegateManager.printSettings.paper withCompletion:^(HPPPPrintItem *printItem) {
                if (printItem) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.printItem = printItem;
                    });
                } else {
                    HPPPLogError(@"Missing printing item or preview image");
                }
            }];
        } else {
            if( nil != self.printLaterJob ) {
                self.printItem = [self.printLaterJob printItemForPaperSize:self.delegateManager.paper.sizeTitle];
            }

            [self configureMultiPageViewWithPrintItem:self.printItem];
        }
    }
}

- (BOOL)showPageRange
{
    return self.printItem.numberOfPages > 1;
}

// Hide or show UI that will always be hidden or shown based on the iOS version
- (void) prepareUiForIosVersion
{
    if (!IS_OS_8_OR_LATER){
        self.selectPrinterCell.hidden = YES;
        self.printSettingsCell.hidden = YES;
        self.numberOfCopiesCell.hidden = YES;
    }
}

// Hide or show UI based on current print settings
- (void)updatePageSettingsUI
{
    // This block of beginUpdates-endUpdates is required to refresh the tableView while it is currently being displayed on screen
    [self.tableView beginUpdates];
    
    self.printCell.hidden = NO;
    self.selectPrinterCell.hidden = NO;
    self.printSettingsCell.hidden = YES;
    self.jobNameCell.hidden = YES;
    self.numberOfCopiesCell.hidden = NO;
    self.paperSizeCell.hidden = self.hppp.hidePaperSizeOption;
    self.paperTypeCell.hidden = self.hppp.hidePaperTypeOption || [[self.delegateManager.printSettings.paper supportedTypes] count] == 1;
    self.pageRangeCell.hidden = ![self showPageRange];
    self.pageSelectionMark.hidden = ![self showPageRange];
    
    if (HPPPPageSettingsModeAddToQueue == self.mode) {
        self.jobNameCell.hidden = NO;
        self.selectPrinterCell.hidden = YES;
        self.paperSizeCell.hidden = YES;
        self.paperTypeCell.hidden = YES;
    } else if (HPPPPageSettingsModeSettingsOnly == self.mode) {
        self.cancelBarButtonItem.title = @"Done";
        self.printCell.hidden = YES;
        self.jobSummaryCell.hidden = YES;
        self.numberOfCopiesCell.hidden = YES;
        self.pageRangeCell.hidden = YES;
        self.pageSelectionMark.hidden = YES;
    } else {
        if (IS_OS_8_OR_LATER){
            if (nil != self.delegateManager.printSettings.printerName){
                self.selectPrinterCell.hidden = YES;
                self.paperSizeCell.hidden = YES;
                self.paperTypeCell.hidden = YES;
                self.printSettingsCell.hidden = NO;
            }
            
            if (self.delegateManager.printSettings.printerIsAvailable){
                [self printerIsAvailable];
            } else {
                [self printerNotAvailable];
            }
        }
    }

    if (HPPPPageSettingsDisplayTypePreviewPane == self.displayType) {
        self.jobNameCell.hidden = YES;
        self.printCell.hidden = YES;
        self.selectPrinterCell.hidden = YES;
        self.printSettingsCell.hidden = YES;
        self.paperSizeCell.hidden = YES;
        self.paperTypeCell.hidden = YES;
        self.numberOfCopiesCell.hidden = YES;
        self.pageRangeCell.hidden = YES;
        self.filterCell.hidden = YES;
    } else if( HPPPPageSettingsDisplayTypePageSettingsPane == self.displayType ) {
        self.basicJobSummaryCell.hidden = YES;
        self.previewJobSummaryCell.hidden = YES;
    }
    
    if ([self.dataSource respondsToSelector:@selector(numberOfPrintingItems)]) {
        NSInteger numberOfJobs = [self.dataSource numberOfPrintingItems];
        if (numberOfJobs > 1) {
            self.numberOfCopiesCell.hidden = YES;
            self.filterCell.hidden = YES;
            self.pageRangeCell.hidden = YES;
            self.printLabel.text = HPPPLocalizedString(@"Print All", @"Print all pages in a document");
        }
    }
    
    [self prepareUiForIosVersion];

    [self.tableView endUpdates];
}

// Update the Paper Size, Paper Type, and Select Printer cells
- (void)updatePrintSettingsUI
{
    self.paperSizeSelectedLabel.text = self.delegateManager.printSettings.paper.sizeTitle;
    self.paperTypeSelectedLabel.text = self.delegateManager.printSettings.paper.typeTitle;
    self.selectedPrinterLabel.text = self.delegateManager.selectedPrinterText;
    
    self.printSettingsDetailLabel.text = self.delegateManager.printSettingsText;
}

- (void)updatePrintButtonUI
{
    HPPP *hppp = [HPPP sharedInstance];
    if( [self.delegateManager noPagesSelected] ) {
        self.printCell.userInteractionEnabled = NO;
        self.printLabel.textColor = [hppp.appearance.settings objectForKey:kHPPPMainActionInactiveLinkFontColor];
    } else {
        self.printCell.userInteractionEnabled = YES;
        self.printLabel.textColor = [hppp.appearance.settings objectForKey:kHPPPMainActionActiveLinkFontColor];
    }
    
    if( HPPPPageSettingsModeAddToQueue == self.mode ) {
        self.printLabel.text = self.delegateManager.printLaterLabelText;
    } else {
        self.printLabel.text = self.delegateManager.printLabelText;
    }
}

- (void)showPrinterSelection:(UITableView *)tableView withCompletion:(void (^)(BOOL userDidSelect))completion
{
    if ([[HPPPWiFiReachability sharedInstance] isWifiConnected]) {
        UIPrinterPickerController *printerPicker = [UIPrinterPickerController printerPickerControllerWithInitiallySelectedPrinter:nil];
        printerPicker.delegate = self.delegateManager;
        
        if( IS_IPAD ) {
            [printerPicker presentFromRect:self.selectPrinterCell.frame
                                    inView:tableView
                                  animated:YES
                         completionHandler:^(UIPrinterPickerController *printerPickerController, BOOL userDidSelect, NSError *error){
                             if (completion){
                                 completion(userDidSelect);
                             }
                         }];
        } else {
            [printerPicker presentAnimated:YES completionHandler:^(UIPrinterPickerController *printerPickerController, BOOL userDidSelect, NSError *error){
                if (completion){
                    completion(userDidSelect);
                }
            }];
        }
    } else {
        [[HPPPWiFiReachability sharedInstance] noPrinterSelectAlert];
    }
}

- (void)reloadPrinterSelectionSection
{
    NSRange range = NSMakeRange(PRINT_SETTINGS_SECTION, 1);
    NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView reloadSections:sectionToReload withRowAnimation:UITableViewRowAnimationNone];
}

- (void)reloadPaperSelectionSection
{
    NSRange range = NSMakeRange(PAPER_SELECTION_SECTION, 1);
    NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView reloadSections:sectionToReload withRowAnimation:UITableViewRowAnimationNone];
}

- (HPPPPrintItem *)printItem
{
    return self.delegateManager.printItem;
}

- (void)setPrintItem:(HPPPPrintItem *)printItem
{
    if( nil == self.delegateManager ) {
        self.delegateManager = [[HPPPPrintSettingsDelegateManager alloc] init];
    }

    self.delegateManager.printItem = printItem;
    [self configureMultiPageViewWithPrintItem:printItem];
}

- (void)configureMultiPageViewWithPrintItem:(HPPPPrintItem *)printItem
{
    if (self.delegateManager.printSettings.paper) {
        self.multiPageView.blackAndWhite = self.delegateManager.blackAndWhite;
        [self.multiPageView setInterfaceOptions:[HPPP sharedInstance].interfaceOptions];
        NSArray *images = [printItem previewImagesForPaper:self.delegateManager.printSettings.paper];
        [self.multiPageView setPages:images paper:self.delegateManager.printSettings.paper layout:printItem.layout];
    }
}

- (HPPPMultiPageView *)multiPageView
{
    if (self.previewViewController) {
        _multiPageView = self.previewViewController.multiPageView;
        _multiPageView.delegate = self;
        
        _headerInactivityView = self.previewViewController.headerInactivityView;
    }
    
    return _multiPageView;
}

-(void)respondToMultiPageViewAction
{
    if( self.printItem.numberOfPages > 1 ) {
        BOOL includePage = self.pageSelectionMark.imageView.image == self.unselectedPageImage;
        
        [self.delegateManager includePageInPageRange:includePage pageNumber:self.multiPageView.currentPage];
        
        [self updateSelectedPageIcon:includePage];
    }
}

- (void)setPageRangeLabelText:(NSString *)pageRange
{
    if( pageRange.length ) {
        self.pageRangeDetailTextField.text = pageRange;
    } else {
        self.pageRangeDetailTextField.text = kPageRangeAllPages;
    }
}

-(void)updateSelectedPageIcon:(BOOL)selectPage
{
    UIImage *image;
    
    if( selectPage ) {
        image = self.selectedPageImage;
    } else {
        image = self.unselectedPageImage;
    }
    
    [self.pageSelectionMark setImage:image forState:UIControlStateNormal];
    
    if( self.previewViewController ) {
        [self.previewViewController.pageSelectionMark setImage:image forState:UIControlStateNormal];
    }
}

- (void)setPageRange:(HPPPPageRange *)pageRange
{
	self.delegateManager.pageRange = pageRange;
}

- (HPPPPageRange *)pageRange
{
    if (nil == self.delegateManager.pageRange) {
        self.delegateManager.pageRange = [[HPPPPageRange alloc] initWithString:kPageRangeAllPages allPagesIndicator:kPageRangeAllPages maxPageNum:self.printItem.numberOfPages sortAscending:YES];
        self.delegateManager.pageRange.range = kPageRangeAllPages;
    }
    
    if( 1 < self.printItem.numberOfPages ) {
        [self.delegateManager.pageRange setRange:self.pageRangeDetailTextField.text];
    }
    
    return self.delegateManager.pageRange;
}

- (NSString *)stringFromNumberOfPrintingItems:(NSInteger)numberOfPrintingItems copies:(NSInteger)copies
{
    NSString *result = nil;
    
    if (numberOfPrintingItems == 1) {
        result = HPPPLocalizedString(@"Print", @"Caption of the button for printing");
    } else {
        NSInteger total = numberOfPrintingItems * copies;
        
        if (total == 2) {
            result = HPPPLocalizedString(@"Print both", @"Caption of the button for printing");
        } else {
            result = [NSString stringWithFormat:HPPPLocalizedString(@"Print all %lu", @"Caption of the button for printing"), (long)total];
        }
    }
    
    return result;
}

- (void) refreshData
{
    self.printManager.currentPrintSettings = self.delegateManager.printSettings;
    
    [self setPageRangeLabelText:self.delegateManager.pageRangeText];
    BOOL pageSelected = NO;
    NSArray *pageNums = [self.delegateManager.pageRange getPages];
    for( NSNumber *pageNum in pageNums ) {
        if( [pageNum integerValue] == self.multiPageView.currentPage) {
            pageSelected = YES;
            break;
        }
    }
    [self updateSelectedPageIcon:pageSelected];
    
    self.jobNameTextField.text = self.delegateManager.jobName;
    
    self.numberOfCopiesLabel.text = self.delegateManager.numCopiesLabelText;
    self.pageRangeDetailTextField.text = self.delegateManager.pageRangeText;
    
    if( !self.previewJobSummaryCell.hidden ) {
        self.previewJobSummaryCell.textLabel.text = self.delegateManager.jobName;
        if( HPPPPageSettingsModeAddToQueue == self.mode ) {
            self.previewJobSummaryCell.detailTextLabel.text = self.delegateManager.printLaterJobSummaryText;
        } else {
            self.previewJobSummaryCell.detailTextLabel.text = self.delegateManager.printJobSummaryText;
        }
    } else {
        if( HPPPPageSettingsModeAddToQueue == self.mode ) {
            self.basicJobSummaryCell.textLabel.text = self.delegateManager.printLaterJobSummaryText;
        } else {
            self.basicJobSummaryCell.textLabel.text = self.delegateManager.printJobSummaryText;
        }
    }
    
    [self changePaper];
    [self reloadPaperSelectionSection];
    
    [self updatePageSettingsUI];
    [self updatePrintSettingsUI];
    [self updatePrintButtonUI];
    
    [self.tableView reloadData];
    
    if( self.previewViewController ) {
        [self.previewViewController refreshData];
    }
}

- (void)refreshPrinterStatus:(NSTimer *)timer
{
    HPPPLogInfo(@"Printer status timer fired");
    [[HPPPPrinter sharedInstance] checkLastPrinterUsedAvailability];
}

- (void)positionPreviewJobSummaryCell
{
    CGRect headerFrame = self.tableView.tableHeaderView.frame;
    headerFrame.size.height = self.view.frame.size.height - self.jobSummaryCell.frame.size.height - 1;
    self.tableView.tableHeaderView.frame = headerFrame;
    self.tableView.tableHeaderView = self.tableView.tableHeaderView;
}

- (void)configureJobSummaryCell
{
    if( HPPPPageSettingsModeAddToQueue == self.mode || HPPPPageSettingsModePrintFromQueue == self.mode ) {
        self.jobSummaryCell = self.previewJobSummaryCell;
        self.basicJobSummaryCell.hidden = YES;
        self.previewJobSummaryCell.hidden = NO;
    } else {
        self.jobSummaryCell = self.basicJobSummaryCell;
        self.previewJobSummaryCell.hidden = YES;
        self.basicJobSummaryCell.hidden = NO;
    }
    
    CGRect frame = self.jobSummaryCell.frame;
    if( HPPPPageSettingsDisplayTypePreviewPane == self.displayType ) {
        if( CGFLOAT_MIN < self.previewJobSummaryCell.frame.size.height ) {
            frame.size.height = self.previewJobSummaryCell.frame.size.height;
            self.jobSummaryCell.frame = frame;
        }
        [self positionPreviewJobSummaryCell];
    } else {
        frame.size.height = self.basicJobSummaryCell.frame.size.height;
    }
}

- (BOOL)isPrintSummarySection:(NSInteger)section
{
    return (BASIC_PRINT_SUMMARY_SECTION == section || PREVIEW_PRINT_SUMMARY_SECTION == section);
}

#pragma mark - UITextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if( self.jobNameTextField == textField ) {
        NSString *text = [textField.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
        if( 0 < [text length] ) {
            self.delegateManager.jobName = text;
        } else {
            textField.text = self.delegateManager.jobName;
        }
    } else if( self.pageRangeDetailTextField == textField ) {
        [((HPPPPageRangeKeyboardView *)self.pageRangeDetailTextField.inputView) commitEditing];
    }
    
    [self stopEditing];
    
    [self refreshData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if( self.jobNameTextField == textField ) {
        [self.jobNameTextField resignFirstResponder];
    } else if( self.pageRangeDetailTextField == textField ) {
        [self.pageRangeDetailTextField resignFirstResponder];
    }
    
    [self stopEditing];
    
    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.editing = YES;
    
    if( textField == self.pageRangeDetailTextField ) {
        [((HPPPPageRangeKeyboardView *)self.pageRangeDetailTextField.inputView) prepareForDisplay];
        self.jobNameTextField.userInteractionEnabled = NO;
    } else {
        self.pageRangeDetailTextField.userInteractionEnabled = NO;
    }
    
    return YES;
}

#pragma  mark - Job Name and Page Range editing

-(void)stopEditing
{
    self.editing = NO;
}

- (void)setPageRangeKeyboardView
{
    HPPPPageRangeKeyboardView *pageRangeKeyboardView = [[HPPPPageRangeKeyboardView alloc] initWithFrame:self.view.frame textField:self.pageRangeDetailTextField maxPageNum:[self.printItem numberOfPages]];
    pageRangeKeyboardView.delegate = self.delegateManager;
    self.pageRangeDetailTextField.inputView = pageRangeKeyboardView;
    [self.pageRangeDetailTextField resignFirstResponder];
}

- (void)cancelAllEditing
{
    [self cancelJobNameEditing];
    [((HPPPPageRangeKeyboardView *)self.pageRangeDetailTextField.inputView) cancelEditing];
    self.pageRangeDetailTextField.text = self.delegateManager.pageRangeText;
    [self stopEditing];
}

- (void)cancelJobNameEditing
{
    self.jobNameTextField.text = self.delegateManager.jobName;
    [self.jobNameTextField resignFirstResponder];
    [self stopEditing];
}

-(void)handleTap:(UITapGestureRecognizer *)sender{

    [self cancelAllEditing];
}

- (void)setEditing:(BOOL)editing
{
    static UITapGestureRecognizer *tableViewTaps;
    static UITapGestureRecognizer *headerInactivityViewTaps;
    _editing = editing;
    
    if( _editing ) {
        tableViewTaps = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        headerInactivityViewTaps = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self.tableView addGestureRecognizer:tableViewTaps];
        [self.headerInactivityView addGestureRecognizer:headerInactivityViewTaps];
        self.headerInactivityView.alpha = 0.1F;
        self.headerInactivityView.userInteractionEnabled = YES;
        
        self.numberOfCopiesStepper.userInteractionEnabled = NO;
        self.blackAndWhiteModeSwitch.userInteractionEnabled = NO;
        self.pageSelectionMark.userInteractionEnabled = NO;
    } else {
        [self.tableView removeGestureRecognizer:tableViewTaps];
        [self.headerInactivityView removeGestureRecognizer:headerInactivityViewTaps];
        self.headerInactivityView.alpha = 0.0F;
        self.headerInactivityView.userInteractionEnabled = NO;
        
        self.numberOfCopiesStepper.userInteractionEnabled = YES;
        self.blackAndWhiteModeSwitch.userInteractionEnabled = YES;
        self.pageSelectionMark.userInteractionEnabled = YES;
        
        self.jobNameTextField.userInteractionEnabled = YES;
        self.pageRangeDetailTextField.userInteractionEnabled = YES;
    }
}

#pragma mark - Printer availability

- (void)printerNotAvailable
{
    // This block of beginUpdates-endUpdates is required to refresh the tableView while it is currently being displayed on screen
    [self.tableView beginUpdates];
    UIImage *warningSign = [UIImage imageNamed:@"HPPPDoNoEnter"];
    [self.printSettingsCell.imageView setImage:warningSign];
    self.delegateManager.printSettings.printerIsAvailable = NO;
    [self.tableView endUpdates];
}

- (void)printerIsAvailable
{
    // This block of beginUpdates-endUpdates is required to refresh the tableView while it is currently being displayed on screen
    [self.tableView beginUpdates];
    [self.printSettingsCell.imageView setImage:nil];
    self.delegateManager.printSettings.printerIsAvailable = YES;
    [self.tableView endUpdates];
}

-(void) setPreviewViewController:(HPPPPageSettingsTableViewController *)vc
{
    _previewViewController = vc;
    _previewViewController.delegateManager = self.delegateManager;
}

#pragma mark - Button actions

- (IBAction)closeButtonTapped:(id)sender
{
    if( self.editing ) {
        [self cancelAllEditing];
    } else {
        if ([self.printDelegate respondsToSelector:@selector(didCancelPrintFlow:)]) {
            if (HPPPPageSettingsModeSettingsOnly == self.mode) {
                [self saveSettings];
            }
            [self.printDelegate didCancelPrintFlow:self];
        } else if ([self.printLaterDelegate respondsToSelector:@selector(didCancelAddPrintLaterFlow:)]) {
            if (HPPPPageSettingsModeSettingsOnly == self.mode) {
                [self saveSettings];
            }
            [self.printLaterDelegate didCancelAddPrintLaterFlow:self];
        } else {
            HPPPLogWarn(@"No HPPPPrintDelegate or HPPPAddPrintLaterDelegate has been set to respond to the end of the print flow.  Implement one of these delegates to dismiss the Page Settings view controller.");
        }
    }
}

- (IBAction)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)displaySystemPrintFromView:(UIView *)view
{
    UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
    controller.delegate = self.printManager;
    controller.showsNumberOfCopies = NO;
    controller.showsPageRange = NO;

    self.printManager.currentPrintSettings = self.delegateManager.printSettings;
    [self.printManager prepareController:controller printItem:self.printItem color:!self.blackAndWhiteModeSwitch.on pageRange:self.pageRange numCopies:self.numberOfCopies];
    
    __weak __typeof(self) weakSelf = self;
    UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        
        if (!completed) {
            HPPPLogInfo(@"Print was NOT completed");
        }
        
        if (error) {
            HPPPLogWarn(@"Print error:  %@", error);
        }

        if (completed && !error) {
            [weakSelf.printManager saveLastOptionsForPrinter:printController.printInfo.printerID];
            [weakSelf.printManager processMetricsForPrintItem:weakSelf.printItem andPageRange:weakSelf.pageRange];
        }

        [weakSelf printCompleted:printController isCompleted:completed printError:error];

    };
    
    if (IS_IPAD) {
        self.cancelBarButtonItem.enabled = NO;
        [controller presentFromRect:view.frame inView:self.view animated:YES completionHandler:completionHandler];
    } else {
        [controller presentAnimated:YES completionHandler:completionHandler];
    }
    
}

- (void)pageSelectionMarkClicked
{
    [self respondToMultiPageViewAction];
}

#pragma mark - Stepper actions

- (IBAction)numberOfCopiesStepperTapped:(UIStepper *)sender
{
    self.delegateManager.numCopies = sender.value;
}

#pragma mark - Switch actions

- (IBAction)blackAndWhiteSwitchToggled:(id)sender
{
    self.delegateManager.blackAndWhite = self.blackAndWhiteModeSwitch.on;
    self.multiPageView.blackAndWhite = self.delegateManager.blackAndWhite;
    [self refreshData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (HPPPPageSettingsDisplayTypePreviewPane != self.displayType  &&
        self.hppp.supportActions.count         != 0                 &&
        HPPPPageSettingsModeSettingsOnly       != self.mode)
        return [super numberOfSectionsInTableView:tableView];
    else
        return ([super numberOfSectionsInTableView:tableView] - 1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   
    if (section == SUPPORT_SECTION) {
        return self.hppp.supportActions.count;
    } else if (section == PAPER_SELECTION_SECTION) {
        if ([[self.delegateManager.printSettings.paper supportedTypes] count] > 1) {
            return 2;
        } else {
            return 1;
        }
    } else if ([self isPrintSummarySection:section]           &&
               HPPPPageSettingsModeSettingsOnly == self.mode  &&
               nil == self.printItem) {
        return 0;

    } else if (PAGE_RANGE_SECTION == section && ![self showPageRange]) {
        return 0;
    } else if (NUMBER_OF_COPIES_SECTION == section && !IS_OS_8_OR_LATER) {
        return 0;
    }
    else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (indexPath.section != SUPPORT_SECTION) {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ActionTableViewCellIdentifier"];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ActionTableViewCellIdentifier"];
        }
        
        cell.backgroundColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsBackgroundColor];
        cell.textLabel.font = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFont];
        cell.textLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPSelectionOptionsPrimaryFontColor];
        HPPPSupportAction *action = self.hppp.supportActions[indexPath.row];
        cell.imageView.image = action.icon;
        cell.textLabel.text = action.title;
    }

    return cell;
}



#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( !self.previewViewController  &&  cell == self.jobSummaryCell ) {
        CGRect frame = self.jobSummaryCell.frame;
        frame.origin.x = self.view.frame.size.width - 55;
        frame.origin.y = self.jobSummaryCell.frame.origin.y - 12.5;
        frame.size.width = 32;
        frame.size.height = 32;
        
        self.pageSelectionMark.frame = [self.jobSummaryCell.superview convertRect:frame toView:self.view];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = ZERO_HEIGHT;
    
    if (section == SUPPORT_SECTION) {
        if (self.hppp.supportActions.count != 0) {
            height = HEADER_HEIGHT;
        }
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = ZERO_HEIGHT;
 
    if ( HPPPPageSettingsDisplayTypePreviewPane == self.displayType ||
        0 == [self tableView:tableView numberOfRowsInSection:section]) {
        height = ZERO_HEIGHT;
    } else {
        if( HPPPPageSettingsModeSettingsOnly == self.mode ) {
            if( (section == PREVIEW_PRINT_SUMMARY_SECTION && self.printItem) ||
               section == PRINTER_SELECTION_SECTION ) {
                
                height = SEPARATOR_SECTION_FOOTER_HEIGHT;
            }
            
            if ( section == PAPER_SELECTION_SECTION  &&
                (!self.paperSizeCell.hidden || !self.paperTypeCell.hidden)) {
                height = SEPARATOR_SECTION_FOOTER_HEIGHT;
            }
        } else if( HPPPPageSettingsModeAddToQueue == self.mode ) {
            if( section == PREVIEW_PRINT_SUMMARY_SECTION ||
                section == PRINT_FUNCTION_SECTION        ||
                section == PRINT_JOB_NAME_SECTION        ||
                section == NUMBER_OF_COPIES_SECTION        ) {
                
                height = SEPARATOR_SECTION_FOOTER_HEIGHT;
            }
        } else {
            if (section == PRINT_FUNCTION_SECTION || section == PREVIEW_PRINT_SUMMARY_SECTION) {
                height = SEPARATOR_SECTION_FOOTER_HEIGHT;
            } else if (IS_OS_8_OR_LATER && ((section == PRINTER_SELECTION_SECTION) || (section == PAPER_SELECTION_SECTION))) {
                if ( !self.hppp.hidePaperTypeOption && (self.delegateManager.printSettings.printerUrl == nil) ) {
                    height = SEPARATOR_SECTION_FOOTER_HEIGHT;
                }
            } else if (!IS_OS_8_OR_LATER && (section == PAPER_SELECTION_SECTION)) {
                height = SEPARATOR_SECTION_FOOTER_HEIGHT;
            } else if (IS_OS_8_OR_LATER && (section == PRINT_SETTINGS_SECTION)) {
                if (self.delegateManager.printSettings.printerUrl != nil) {
                    if (self.delegateManager.printSettings.printerIsAvailable) {
                        height = SEPARATOR_SECTION_FOOTER_HEIGHT;
                    } else {
                        height = PRINTER_WARNING_SECTION_FOOTER_HEIGHT;
                    }
                }
            } else if (section == PAGE_RANGE_SECTION) {
                height = SEPARATOR_SECTION_FOOTER_HEIGHT;
            }
            else if (IS_OS_8_OR_LATER && (section == NUMBER_OF_COPIES_SECTION)) {
                height = SEPARATOR_SECTION_FOOTER_HEIGHT;
            } else if (section == SUPPORT_SECTION) {
                height = SEPARATOR_SECTION_FOOTER_HEIGHT;
            } else if (HPPPPageSettingsModeAddToQueue == self.mode && (section == PRINT_JOB_NAME_SECTION)) {
                height = SEPARATOR_SECTION_FOOTER_HEIGHT;
            }
        }
    }
    
    if( HPPPPageSettingsDisplayTypePageSettingsPane == self.displayType && [self isPrintSummarySection:section] ) {
        height = ZERO_HEIGHT;
    }

    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    
    if (indexPath.section == SUPPORT_SECTION) {
        HPPPSupportAction *action = self.hppp.supportActions[indexPath.row];
        if (action.url) {
            [[UIApplication sharedApplication] openURL:action.url];
        } else {
            [self presentViewController:action.viewController animated:YES completion:nil];
        }
    } else if (cell == self.selectPrinterCell) {
        [self showPrinterSelection:tableView withCompletion:nil];
    } else if (cell == self.printCell){
        if( HPPPPageSettingsModeAddToQueue == self.mode ) {
            [self addJobToPrintQueue];
        } else {
            [self oneTouchPrint:tableView];
        }
    } else if (cell == self.pageRangeCell){
        [self.pageRangeDetailTextField becomeFirstResponder];
    }  else if (cell == self.jobNameCell) {
        [self.jobNameTextField becomeFirstResponder];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = nil;
    
    if (section == SUPPORT_SECTION) {
        if (self.hppp.supportActions.count != 0) {
            header = [tableView HPPPHeaderViewForSupportSection];
        }
    }
    
    return header;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footer = nil;
    
    if (IS_OS_8_OR_LATER  &&  HPPPPageSettingsDisplayTypePreviewPane != self.displayType) {
        if (section == PRINT_SETTINGS_SECTION) {
            if ((self.delegateManager.printSettings.printerUrl != nil) && !self.delegateManager.printSettings.printerIsAvailable) {
                footer = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.frame.size.width, PRINTER_WARNING_SECTION_FOOTER_HEIGHT)];
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20.0f, 0.0f, tableView.frame.size.width - 20.0f, PRINTER_WARNING_SECTION_FOOTER_HEIGHT)];
                label.font = [self.hppp.appearance.settings objectForKey:kHPPPGeneralBackgroundPrimaryFont];
                label.textColor = [self.hppp.appearance.settings objectForKey:kHPPPGeneralBackgroundPrimaryFontColor];
                if( HPPPPageSettingsModeSettingsOnly != self.mode && HPPPPageSettingsModeAddToQueue != self.mode ) {
                    if (HPPPPageSettingsModePrintFromQueue == self.mode) {
                        label.text = HPPPLocalizedString(@"Default printer not currently available", nil);
                    } else {
                        label.text = HPPPLocalizedString(@"Recent printer not currently available", nil);
                    }
                }
                [footer addSubview:label];
            }
        }
    }
    
    return footer;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    CGFloat rowHeight = tableView.rowHeight;
    
    if( HPPPPageSettingsDisplayTypePreviewPane == self.displayType && cell == self.jobSummaryCell ) {
        rowHeight = 2 * tableView.rowHeight;
    }
    
    return cell.hidden ? 0.0 : rowHeight;
}

#pragma mark - Print Queue

- (void) addJobToPrintQueue
{
    self.printLaterJob.pageRange = self.delegateManager.pageRange;
    self.printLaterJob.name = self.delegateManager.jobName;
    self.printLaterJob.numCopies = self.delegateManager.numCopies;
    self.printLaterJob.blackAndWhite = self.delegateManager.blackAndWhite;
    
    NSString *titleForInitialPaperSize = [HPPPPaper titleFromSize:[HPPP sharedInstance].defaultPaper.paperSize];
    HPPPPrintItem *printItem = [self.printLaterJob.printItems objectForKey:titleForInitialPaperSize];
    
    if (printItem == nil) {
        HPPPLogError(@"At least the printing item for the initial paper size (%@) must be provided", titleForInitialPaperSize);
    } else {
        BOOL result = [[HPPPPrintLaterQueue sharedInstance] addPrintLaterJob:self.printLaterJob fromController:self];
        
        if (result) {
            if ([self.printLaterDelegate respondsToSelector:@selector(didFinishAddPrintLaterFlow:)]) {
                [self.printLaterDelegate didFinishAddPrintLaterFlow:self];
            }
        } else {
            if ([self.printLaterDelegate respondsToSelector:@selector(didCancelAddPrintLaterFlow:)]) {
                [self.printLaterDelegate didCancelAddPrintLaterFlow:self];
            }
        }
    }
}

#pragma mark - Printing

- (void)oneTouchPrint:(UITableView *)tableView
{
    if (IS_OS_8_OR_LATER) {
        if (self.delegateManager.printSettings.printerUrl == nil ||
            !self.delegateManager.printSettings.printerIsAvailable ) {
            [self showPrinterSelection:tableView withCompletion:^(BOOL userDidSelect){
                if (userDidSelect) {
                    [self startPrinting];
                }
            }];
        } else {
            [self startPrinting];
        }
    } else {
        self.printItem.layout.paper = self.printManager.currentPrintSettings.paper;
        [self displaySystemPrintFromView:self.printCell];
    }
}

- (void)startPrinting
{
    self.itemsToPrint = [[NSMutableArray alloc] init];
    self.pageRanges = [[NSMutableArray alloc] init];
    self.blackAndWhiteSelections = [[NSMutableArray alloc] init];
    self.numCopySelections = [[NSMutableArray alloc] init];
    
    [self collectHPPPPrintLaterJobs];
    if( 0 == self.itemsToPrint.count ) {
        [self collectParallelArrayPrintJobs];
    }
    
    HPPPPrintItem *firstItem = [self.itemsToPrint firstObject];
    HPPPPageRange *pageRange = [self.pageRanges firstObject];
    NSNumber *blackAndWhite = [self.blackAndWhiteSelections firstObject];
    NSNumber *numCopies = [self.numCopySelections firstObject];
    
    if( firstItem ) {
        [self.itemsToPrint removeObjectAtIndex:0];
        [self.blackAndWhiteSelections removeObjectAtIndex:0];
        [self.pageRanges removeObjectAtIndex:0];
        [self.numCopySelections removeObjectAtIndex:0];
    }

    [self print:firstItem blackAndWhite:[blackAndWhite boolValue] pageRange:pageRange numberOfCopies:[numCopies integerValue]];
}

- (void)collectHPPPPrintLaterJobs
{
    NSMutableArray *printLaterJobs = nil;
    
    if ([self.dataSource respondsToSelector:@selector(numberOfPrintingItems)]) {
        NSInteger numberOfJobs = [self.dataSource numberOfPrintingItems];
        if (numberOfJobs > 1) {
            if ([self.dataSource respondsToSelector:@selector(printLaterJobs)]) {
                printLaterJobs = [self.dataSource printLaterJobs].mutableCopy;
            }
        }
    }
    
    for (HPPPPrintLaterJob *job in printLaterJobs) {
        [self.itemsToPrint addObject:[job printItemForPaperSize:self.delegateManager.printSettings.paper.sizeTitle]];
        [self.pageRanges addObject:job.pageRange];
        [self.blackAndWhiteSelections addObject:[NSNumber numberWithBool:job.blackAndWhite]];
        [self.numCopySelections addObject:[NSNumber numberWithInteger:job.numCopies]];
    }
}

- (void)collectParallelArrayPrintJobs
{
    [self.itemsToPrint addObjectsFromArray:[self collectPrintingItems]];
    [self.pageRanges addObjectsFromArray:[self collectPageRanges]];
    [self.blackAndWhiteSelections addObjectsFromArray:[self collectBlackAndWhiteSelections]];
    [self.numCopySelections addObjectsFromArray:[self collectNumCopiesSelections]];
    
    HPPPPrintItem *firstItem = [self.itemsToPrint firstObject];
    
    if( self.pageRanges.count != self.itemsToPrint.count ) {
        HPPPLogWarn(@"%lu HPPPPrintItems and %lu HPPPPageRanges.  Using default values for all HPPPPageRanges.", (unsigned long)self.itemsToPrint.count, (unsigned long)self.pageRanges.count);
        self.pageRanges = [[NSMutableArray alloc] initWithCapacity:self.itemsToPrint.count];
        for (int i=0; i<self.itemsToPrint.count; i++) {
            [self.pageRanges insertObject:[[HPPPPageRange alloc] initWithString:@"All" allPagesIndicator:@"All" maxPageNum:firstItem.numberOfPages sortAscending:TRUE] atIndex:i];
        }
    }
    
    if( self.blackAndWhiteSelections.count != self.itemsToPrint.count ) {
        HPPPLogWarn(@"%lu HPPPPrintItems and %lu BOOLs for black and white.  Using default values for all black and white indicators.", (unsigned long)self.itemsToPrint.count, (unsigned long)self.blackAndWhiteSelections.count);
        self.blackAndWhiteSelections = [[NSMutableArray alloc] initWithCapacity:self.itemsToPrint.count];
        for (int i=0; i<self.itemsToPrint.count; i++) {
            [self.blackAndWhiteSelections insertObject:[NSNumber numberWithBool:NO] atIndex:i];
        }
    }
    
    if( self.numCopySelections.count != self.itemsToPrint.count ) {
        HPPPLogWarn(@"%lu HPPPPrintItems and %lu NSNumbers for number of copies.  Using default values for all number of copies.", (unsigned long)self.itemsToPrint.count, (unsigned long)self.numCopySelections.count);
        self.numCopySelections = [[NSMutableArray alloc] initWithCapacity:self.itemsToPrint.count];
        for (int i=0; i<self.itemsToPrint.count; i++) {
            [self.numCopySelections insertObject:[NSNumber numberWithInteger:DEFAULT_NUMBER_OF_COPIES] atIndex:i];
        }
    }
}

- (NSMutableArray *)collectPrintingItems
{
    NSMutableArray *items = nil;
    
    if ([self.dataSource respondsToSelector:@selector(numberOfPrintingItems)]) {
        NSInteger numberOfJobs = [self.dataSource numberOfPrintingItems];
        if (numberOfJobs > 1) {
            if ([self.dataSource respondsToSelector:@selector(printingItemsForPaper:)]) {
                items = [self.dataSource printingItemsForPaper:self.delegateManager.printSettings.paper].mutableCopy;
            }
        }
    }
    
    if (nil == items) {
        items = [NSMutableArray arrayWithObjects:self.printItem, nil];
    }
    
    return items;
}

- (NSMutableArray *)collectPageRanges
{
    NSMutableArray *pageRanges = nil;
    
    if ([self.dataSource respondsToSelector:@selector(numberOfPrintingItems)]) {
        NSInteger numberOfJobs = [self.dataSource numberOfPrintingItems];
        if (numberOfJobs > 1) {
            if ([self.dataSource respondsToSelector:@selector(pageRangeSelections)]) {
                pageRanges = [self.dataSource pageRangeSelections].mutableCopy;
            }
        }
    }
    
    if (nil == pageRanges) {
        pageRanges = [NSMutableArray arrayWithObjects:self.pageRange, nil];
    }
    
    return pageRanges;
}

- (NSMutableArray *)collectBlackAndWhiteSelections
{
    NSMutableArray *bws = nil;
    
    if ([self.dataSource respondsToSelector:@selector(numberOfPrintingItems)]) {
        NSInteger numberOfJobs = [self.dataSource numberOfPrintingItems];
        if (numberOfJobs > 1) {
            if ([self.dataSource respondsToSelector:@selector(blackAndWhiteSelections)]) {
                bws = [self.dataSource blackAndWhiteSelections].mutableCopy;
            }
        }
    }
    
    if (nil == bws) {
        bws = [NSMutableArray arrayWithObjects:[NSNumber numberWithBool:self.blackAndWhiteModeSwitch.on], nil];
    }
    
    return bws;
}

- (NSMutableArray *)collectNumCopiesSelections
{
    NSMutableArray *numCopies = nil;
    
    if ([self.dataSource respondsToSelector:@selector(numberOfPrintingItems)]) {
        NSInteger numberOfJobs = [self.dataSource numberOfPrintingItems];
        if (numberOfJobs > 1) {
            if ([self.dataSource respondsToSelector:@selector(numberOfCopiesSelections)]) {
                numCopies = [self.dataSource numberOfCopiesSelections].mutableCopy;
            }
        }
    }
    
    if (nil == numCopies) {
        numCopies = [NSMutableArray arrayWithObjects:[NSNumber numberWithInteger:self.numberOfCopiesStepper.value], nil];
    }
    
    return numCopies;
}


- (void)print:(HPPPPrintItem *)printItem blackAndWhite:(BOOL)blackAndWhite pageRange:(HPPPPageRange *)pageRange numberOfCopies:(NSInteger)numCopies
{
    self.delegateManager.blackAndWhite = blackAndWhite;
    self.printManager.currentPrintSettings = self.delegateManager.printSettings;
    self.printManager.currentPrintSettings.color = !blackAndWhite;
    
    NSError *error;
    [self.printManager print:printItem
                   pageRange:pageRange
                   numCopies:numCopies
                       error:&error];
    
    if( HPPPPrintManagerErrorNone != error.code ) {
        HPPPLogError(@"Failed to print with error %@", error);
    }
}

- (void)print:(HPPPPrintItem *)printItem
{
    self.delegateManager.blackAndWhite = self.blackAndWhiteModeSwitch.on;
    self.printManager.currentPrintSettings = self.delegateManager.printSettings;

    [self print:printItem blackAndWhite:self.blackAndWhiteModeSwitch.on pageRange:self.pageRange numberOfCopies:self.numberOfCopiesStepper.value];
}

- (void)printCompleted:(UIPrintInteractionController *)printController isCompleted:(BOOL)completed printError:(NSError *)error
{
    [self.delegateManager savePrinterId:printController.printInfo.printerID];
    
    if (error) {
        HPPPLogError(@"FAILED! due to error in domain %@ with error code %ld", error.domain, (long)error.code);
    }
    
    if (completed) {
        
        [self setDefaultPrinter];
    
        if ([self.printDelegate respondsToSelector:@selector(didFinishPrintFlow:)]) {
            [self.printDelegate didFinishPrintFlow:self];
        }
        else {
            HPPPLogWarn(@"No HPPPPrintDelegate has been set to respond to the end of the print flow.  Implement this delegate to dismiss the Page Settings view controller.");
        }
    }
    
    if (IS_IPAD) {
        self.cancelBarButtonItem.enabled = YES;
    }
}

- (void)setDefaultPrinter
{
    [HPPPDefaultSettingsManager sharedInstance].defaultPrinterName = self.delegateManager.printSettings.printerName;
    [HPPPDefaultSettingsManager sharedInstance].defaultPrinterUrl = self.delegateManager.printSettings.printerUrl.absoluteString;
    [HPPPDefaultSettingsManager sharedInstance].defaultPrinterNetwork = [HPPPAnalyticsManager wifiName];
    [HPPPDefaultSettingsManager sharedInstance].defaultPrinterCoordinate = [[HPPPPrintLaterManager sharedInstance] retrieveCurrentLocation];
    [HPPPDefaultSettingsManager sharedInstance].defaultPrinterModel = self.delegateManager.printSettings.printerModel;
    [HPPPDefaultSettingsManager sharedInstance].defaultPrinterLocation = self.delegateManager.printSettings.printerLocation;
    [[NSNotificationCenter defaultCenter] postNotificationName:kHPPPDefaultPrinterAddedNotification object:self userInfo:nil];
}

- (void)saveSettings
{
    [self setDefaultPrinter];
    
    NSString *printerID = [HPPPDefaultSettingsManager sharedInstance].defaultPrinterUrl;
    [self.delegateManager savePrinterId:printerID];
    [self.printManager saveLastOptionsForPrinter:printerID];
}

- (void)preparePrintManager
{
    if (nil == self.printManager) {
        self.printManager = [[HPPPPrintManager alloc] init];
    }
    self.printManager.delegate = self;

    HPPPPrintManagerOptions options = HPPPPrintManagerOriginCustom;
    if ([self.printDelegate class] == [HPPPPrintActivity class]) {
        options = HPPPPrintManagerOriginShare;
    } else if ([self.printDelegate class] == [HPPPPrintJobsViewController class]) {
        options = HPPPPrintManagerOriginQueue;
    }

    if ([self.dataSource respondsToSelector:@selector(numberOfPrintingItems)]) {
        if ([self.dataSource numberOfPrintingItems] > 1) {
            options += HPPPPrintManagerMultiJob;
        }
    }
    
    self.printManager.options = options;
    
}

#pragma mark - HPPPMultipageViewDelegate

- (void)multiPageView:(HPPPMultiPageView *)multiPageView didChangeFromPage:(NSUInteger)oldPageNumber ToPage:(NSUInteger)newPageNumber
{
    if (HPPPPageSettingsModeSettingsOnly != self.mode) {
        BOOL pageSelected = NO;
        
        NSArray *pageNums = [self.pageRange getPages];
        
        for( NSNumber *pageNum in pageNums ) {
            if( [pageNum integerValue] == newPageNumber ) {
                pageSelected = YES;
                break;
            }
        }
        
        [self updateSelectedPageIcon:pageSelected];
    }
}

- (void)multiPageView:(HPPPMultiPageView *)multiPageView didSingleTapPage:(NSUInteger)pageNumber
{
    if (HPPPPageSettingsModeSettingsOnly != self.mode) {
        [self respondToMultiPageViewAction];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}

#pragma mark - HPPPPrintManagerDelegate

- (void)didFinishPrintJob:(UIPrintInteractionController *)printController completed:(BOOL)completed error:(NSError *)error
{
    if (error) {
        HPPPLogError(@"Print error: %@", error);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HPPPPrintItem *nextItem = [self.itemsToPrint firstObject];
        NSNumber *blackAndWhite = [self.blackAndWhiteSelections firstObject];
        HPPPPageRange *pageRange = [self.pageRanges firstObject];
        NSNumber *numCopies = [self.numCopySelections firstObject];
        
        if (nextItem) {
            [self.itemsToPrint removeObjectAtIndex:0];
            [self.blackAndWhiteSelections removeObjectAtIndex:0];
            [self.pageRanges removeObjectAtIndex:0];
            [self.numCopySelections removeObjectAtIndex:0];
            
            [self print:nextItem blackAndWhite:[blackAndWhite boolValue] pageRange:pageRange numberOfCopies:[numCopies integerValue]];
        } else {
            [self printCompleted:printController isCompleted:completed printError:error];
        }
    });
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PrintSettingsSegue"]) {
        
        HPPPPrintSettingsTableViewController *vc = (HPPPPrintSettingsTableViewController *)segue.destinationViewController;
        vc.printSettings = self.delegateManager.printSettings;
        vc.useDefaultPrinter = (HPPPPageSettingsModePrintFromQueue == self.mode);
        vc.delegate = self.delegateManager;
    } else if ([segue.identifier isEqualToString:@"PaperSizeSegue"]) {
        
        HPPPPaperSizeTableViewController *vc = (HPPPPaperSizeTableViewController *)segue.destinationViewController;
        vc.currentPaper = self.delegateManager.printSettings.paper;
        vc.delegate = self.delegateManager;
    } else if ([segue.identifier isEqualToString:@"PaperTypeSegue"]) {
        
        HPPPPaperTypeTableViewController *vc = (HPPPPaperTypeTableViewController *)segue.destinationViewController;
        vc.currentPaper = self.delegateManager.printSettings.paper;
        vc.delegate = self.delegateManager;
    }
}

#pragma mark - Notifications

- (void)handleDidCheckPrinterAvailability:(NSNotification *)notification
{
    HPPPLogInfo(@"handleDidCheckPrinterAvailability: %@", notification);
    
    BOOL available = [[notification.userInfo objectForKey:kHPPPPrinterAvailableKey] boolValue];
    
    if ( available ) {
        [self printerIsAvailable];
    } else {
        [self printerNotAvailable];
    }
    
    [self reloadPrinterSelectionSection];
}

#pragma mark - Wi-Fi handling

- (void)connectionEstablished:(NSNotification *)notification
{
    [self configurePrintButton];
}

- (void)connectionLost:(NSNotification *)notification
{
    [self configurePrintButton];
    [[HPPPWiFiReachability sharedInstance] noPrintingAlert];
}

- (void)configurePrintButton
{
    if ([[HPPPWiFiReachability sharedInstance] isWifiConnected]) {
        self.printCell.userInteractionEnabled = YES;
        self.printLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPMainActionActiveLinkFontColor];
    } else {
        self.printCell.userInteractionEnabled = NO;
        self.printLabel.textColor = [self.hppp.appearance.settings objectForKey:kHPPPMainActionInactiveLinkFontColor];
    }
}

@end
