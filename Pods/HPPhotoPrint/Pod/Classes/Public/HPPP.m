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
#import "HPPPPrintLaterManager.h"
#import "HPPPPrintLaterQueue.h"
#import "HPPPPrintJobsViewController.h"
#import "HPPPPageSettingsTableViewController.h"
#import "HPPPWiFiReachability.h"
#import "HPPPPrintManager.h"
#import <CoreFoundation/CoreFoundation.h>
#import "HPPPLayoutFactory.h"

NSString * const kHPPPLibraryVersion = @"2.6.9";

NSString * const kLaterActionIdentifier = @"LATER_ACTION_IDENTIFIER";
NSString * const kPrintActionIdentifier = @"PRINT_ACTION_IDENTIFIER";
NSString * const kPrintCategoryIdentifier = @"PRINT_CATEGORY_IDENTIFIER";

NSString * const kHPPPShareCompletedNotification = @"kHPPPShareCompletedNotification";

NSString * const kHPPPTrackableScreenNotification = @"kHPPPTrackableScreenNotification";
NSString * const kHPPPTrackableScreenNameKey = @"screen-name";

NSString * const kHPPPPrintQueueNotification = @"kHPPPPrintQueueNotification";
NSString * const kHPPPPrintQueueActionKey = @"kHPPPPrintQueueActionKey";
NSString * const kHPPPPrintQueueJobKey = @"kHPPPPrintQueueJobKey";
NSString * const kHPPPPrintQueuePrintItemKey = @"kHPPPPrintQueuePrintItemKey";

NSString * const kHPPPPrintJobAddedToQueueNotification = @"kHPPPPrintJobAddedToQueueNotification";
NSString * const kHPPPPrintJobRemovedFromQueueNotification = @"kHPPPPrintJobRemovedFromQueueNotification";
NSString * const kHPPPAllPrintJobsRemovedFromQueueNotification = @"kHPPPAllPrintJobsRemovedFromQueueNotification";

NSString * const kHPPPPrinterAvailabilityNotification = @"kHPPPPrinterAvailabilityNotification";
NSString * const kHPPPPrinterAvailableKey = @"availability";
NSString * const kHPPPPrinterKey = @"printer";

NSString * const kHPPPWiFiConnectionEstablished = @"kHPPPWiFiConnectionEstablished";
NSString * const kHPPPWiFiConnectionLost = @"kHPPPWiFiConnectionLost";

NSString * const kHPPPBlackAndWhiteFilterId = @"black_and_white_filter";
NSString * const kHPPPNumberOfCopies = @"copies";
NSString * const kHPPPPaperSizeId = @"paper_size";
NSString * const kHPPPPaperTypeId = @"paper_type";
NSString * const kHPPPPaperWidthId = @"user_paper_width_inches";
NSString * const kHPPPPaperHeightId = @"user_paper_height_inches";
NSString * const kHPPPPrinterId = @"printer_id";
NSString * const kHPPPPrinterDisplayLocation = @"printer_location";
NSString * const kHPPPPrinterMakeAndModel = @"printer_model";
NSString * const kHPPPPrinterDisplayName = @"printer_name";

NSString * const kHPPPNumberPagesDocument = @"number_pages_document";
NSString * const kHPPPNumberPagesPrint = @"number_pages_print";

NSString * const kHPPPPrinterPaperWidthPoints = @"printer_paper_width_points";
NSString * const kHPPPPrinterPaperHeightPoints = @"printer_paper_height_points";
NSString * const kHPPPPrinterPaperAreaWidthPoints = @"printer_paper_area_width_points";
NSString * const kHPPPPrinterPaperAreaHeightPoints = @"printer_paper_area_height_points";
NSString * const kHPPPPrinterPaperAreaXPoints = @"printer_paper_area_x_points";
NSString * const kHPPPPrinterPaperAreaYPoints = @"printer_paper_area_y_points";

BOOL const kHPPPDefaultUniqueDeviceIdPerApp = YES;

@implementation HPPP

#pragma mark - Public methods

+ (HPPP *)sharedInstance
{
    static HPPP *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HPPP alloc] init];
        sharedInstance.interfaceOptions = [[HPPPInterfaceOptions alloc] init];
        sharedInstance.printPaperDelegate = nil;
        sharedInstance.uniqueDeviceIdPerApp = kHPPPDefaultUniqueDeviceIdPerApp;
    });
    
    return sharedInstance;
}

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        
        if ([HPPPPrintLaterManager sharedInstance].userNotificationsPermissionSet) {
            [[HPPPPrintLaterManager sharedInstance] initLocationManager];
            [[HPPPPrintLaterManager sharedInstance] initUserNotifications];
        }
        
        self.handlePrintMetricsAutomatically = YES;
        self.lastOptionsUsed = [NSMutableDictionary dictionary];
        self.appearance = [[HPPPAppearance alloc] init];
        self.supportedPapers = [HPPPPaper availablePapers];
        self.defaultPaper = [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize5x7 paperType:HPPPPaperTypePhoto];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShareCompletedNotification:) name:kHPPPShareCompletedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)hideBlackAndWhiteOption
{
    BOOL retVal = YES;
    
    if (IS_OS_8_OR_LATER) {
        retVal = _hideBlackAndWhiteOption;
    }
    
    return retVal;
}

#pragma mark - Metrics 

- (void)handleShareCompletedNotification:(NSNotification *)notification
{
    NSString *offramp = [notification.userInfo objectForKey:kHPPPOfframpKey];
    if ([HPPPPrintManager printingOfframp:offramp]  && self.handlePrintMetricsAutomatically) {
        // The client app must disable automatic print metric handling in order to post print metrics via the notification system
        HPPPLogError(@"Cannot post extended metrics notification while automatic metric handling is active");
        return;
    }
    [[HPPPAnalyticsManager sharedManager] trackShareEventWithPrintItem:notification.object andOptions:notification.userInfo];
}

#pragma mark - Getter methods

- (UIViewController *)printViewControllerWithDelegate:(id<HPPPPrintDelegate>)delegate dataSource:(id<HPPPPrintDataSource>)dataSource printItem:(HPPPPrintItem *)printItem fromQueue:(BOOL)fromQueue settingsOnly:(BOOL)settingsOnly;
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"HPPP" bundle:[NSBundle mainBundle]];
    
    if (IS_SPLIT_VIEW_CONTROLLER_IMPLEMENTATION) {
        UISplitViewController *pageSettingsSplitViewController = (UISplitViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HPPPPageSettingsSplitViewController"];
        
        if( 1 == pageSettingsSplitViewController.viewControllers.count ) {
            HPPPLogError(@"Only one navController created for the pageSettingsSplitViewController... correcting");
            UINavigationController *activeNavigationController = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"HPPPActiveNavigationController"];
            UINavigationController *detailsNavigationController = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"HPPPPreviewNavigationController"];
            NSMutableArray *viewControllers = [[NSMutableArray alloc] initWithObjects:activeNavigationController, detailsNavigationController, nil];
            pageSettingsSplitViewController.viewControllers = viewControllers;
        }
        
        UINavigationController *detailsNavigationController = pageSettingsSplitViewController.viewControllers[1];
        if( nil == (HPPPPageSettingsTableViewController *)detailsNavigationController.topViewController ) {
            HPPPLogError(@"Preview pane view controller failed to be created... correcting");
            HPPPPageSettingsTableViewController *previewPane = [storyboard instantiateViewControllerWithIdentifier:@"HPPPPageSettingsTableViewController"];
            [detailsNavigationController pushViewController:previewPane animated:NO];
        }
        detailsNavigationController.navigationBar.translucent = NO;
        HPPPPageSettingsTableViewController *previewPane = (HPPPPageSettingsTableViewController *)detailsNavigationController.topViewController;
        previewPane.dataSource = dataSource;
        previewPane.printItem = printItem;
        previewPane.displayType = HPPPPageSettingsDisplayTypePreviewPane;
        
        UINavigationController *masterNavigationController = pageSettingsSplitViewController.viewControllers[0];
        if( nil == (HPPPPageSettingsTableViewController *)masterNavigationController.topViewController ) {
            HPPPLogError(@"Page Settings view controller failed to be created... correcting");
            HPPPPageSettingsTableViewController *pageSettingsTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"HPPPPageSettingsTableViewController"];
            [masterNavigationController pushViewController:pageSettingsTableViewController animated:NO];
        }
        masterNavigationController.navigationBar.translucent = NO;
        HPPPPageSettingsTableViewController *pageSettingsTableViewController = (HPPPPageSettingsTableViewController *)masterNavigationController.topViewController;
        pageSettingsTableViewController.displayType = HPPPPageSettingsDisplayTypePageSettingsPane;
        pageSettingsTableViewController.printDelegate = delegate;
        pageSettingsTableViewController.dataSource = dataSource;
        pageSettingsTableViewController.printItem = printItem;
        pageSettingsSplitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        pageSettingsTableViewController.previewViewController = previewPane;
       
        if( fromQueue ) {
            pageSettingsTableViewController.mode = HPPPPageSettingsModePrintFromQueue;
            previewPane.mode = HPPPPageSettingsModePrintFromQueue;
        } else if( settingsOnly ) {
            pageSettingsTableViewController.mode = HPPPPageSettingsModeSettingsOnly;
            previewPane.mode = HPPPPageSettingsModeSettingsOnly;
        } else {
            pageSettingsTableViewController.mode = HPPPPageSettingsModePrint;
            previewPane.mode = HPPPPageSettingsModePrint;
        }

        return pageSettingsSplitViewController;
    } else {
        // Is not possible to use UISplitViewController in iOS 7 without been the first view controller of the app. You can however do tricky workarounds like embbeding the Split View Controller in a Container View Controller, but that can end up in difficult bugs to find.
        // From Apple Documentation (iOS 7):
        // "you must always install the view from a UISplitViewController object as the root view of your application’s window. [...] Split view controllers cannot be presented modally."
        HPPPPageSettingsTableViewController *pageSettingsTableViewController = (HPPPPageSettingsTableViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HPPPPageSettingsTableViewController"];
        
        pageSettingsTableViewController.displayType = HPPPPageSettingsDisplayTypeSingleView;
        pageSettingsTableViewController.printItem = printItem;
        pageSettingsTableViewController.printDelegate = delegate;
        pageSettingsTableViewController.dataSource = dataSource;
        
        if( fromQueue ) {
            pageSettingsTableViewController.mode = HPPPPageSettingsModePrintFromQueue;
        } else if( settingsOnly ) {
            pageSettingsTableViewController.mode = HPPPPageSettingsModeSettingsOnly;
        } else {
            pageSettingsTableViewController.mode = HPPPPageSettingsModePrint;
        }

        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:pageSettingsTableViewController];
        navigationController.navigationBar.translucent = NO;
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        
        return navigationController;
    }
}

- (UIViewController *)printLaterViewControllerWithDelegate:(id<HPPPAddPrintLaterDelegate>)delegate printLaterJob:(HPPPPrintLaterJob *)printLaterJob
{
    HPPPPrintItem *printItem = [printLaterJob.printItems objectForKey:self.defaultPaper.sizeTitle];

    HPPPPageSettingsTableViewController *pageSettingsTableViewController;
    HPPPPageSettingsTableViewController *previewViewController;
    
    UIViewController *vc = [self printViewControllerWithDelegate:nil dataSource:nil printItem:printItem fromQueue:NO settingsOnly:NO];
    
    if( [vc isKindOfClass:[UINavigationController class]] ) {
        pageSettingsTableViewController = (HPPPPageSettingsTableViewController *)((UINavigationController *)vc).topViewController;
    } else if( [vc isKindOfClass:[UISplitViewController class]] ) {
        UINavigationController *masterNavigationController = (UINavigationController *)((UISplitViewController *)vc).viewControllers[0];
        pageSettingsTableViewController = (HPPPPageSettingsTableViewController *)masterNavigationController.topViewController;

        UINavigationController *previewNavigationController = (UINavigationController *)((UISplitViewController *)vc).viewControllers[1];
        previewViewController = (HPPPPageSettingsTableViewController *)previewNavigationController.topViewController;
        previewViewController.mode = HPPPPageSettingsModeAddToQueue;
        previewViewController.printLaterJob = printLaterJob;
    } else {
        pageSettingsTableViewController = (HPPPPageSettingsTableViewController *)vc;
    }
    
    pageSettingsTableViewController.printLaterJob = printLaterJob;
    pageSettingsTableViewController.printLaterDelegate = delegate;
    pageSettingsTableViewController.mode = HPPPPageSettingsModeAddToQueue;
    
    return vc;
}

#pragma mark - Setter methods

- (UIUserNotificationCategory *)printLaterUserNotificationCategory
{
    return [[HPPPPrintLaterManager sharedInstance] printLaterUserNotificationCategory];
}

- (void)handleNotification:(UILocalNotification *)notification
{
    [[HPPPPrintLaterManager sharedInstance] handleNotification:notification];
}

- (void)handleNotification:(UILocalNotification *)notification action:(NSString *)action
{
    [[HPPPPrintLaterManager sharedInstance] handleNotification:notification action:action];
}

- (void)presentPrintQueueFromController:(UIViewController *)controller animated:(BOOL)animated completion:(void(^)(void))completion
{
    [HPPPPrintJobsViewController presentAnimated:animated usingController:controller andCompletion:completion];
}

- (NSInteger)numberOfJobsInQueue
{
    return [[HPPPPrintLaterQueue sharedInstance] retrieveNumberOfPrintLaterJobs];
}

- (NSString *)nextPrintJobId
{
    return [[HPPPPrintLaterQueue sharedInstance] retrievePrintLaterJobNextAvailableId];
}

- (void)clearQueue
{
    [[HPPPPrintLaterQueue sharedInstance] deleteAllPrintLaterJobs];
}

- (void)addJobToQueue:(HPPPPrintLaterJob *)job
{
    [[HPPPPrintLaterQueue sharedInstance] addPrintLaterJob:job fromController:nil];
}

- (BOOL)isWifiConnected
{
    return [[HPPPWiFiReachability sharedInstance] isWifiConnected];
}

@end
