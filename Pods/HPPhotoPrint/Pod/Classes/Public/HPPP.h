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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HPPPAppearance.h"
#import "HPPPPrintActivity.h"
#import "HPPPPrintLaterActivity.h"
#import "HPPPPrintLaterJob.h"
#import "HPPPSupportAction.h"
#import "HPPPLogger.h"
#import "HPPPInterfaceOptions.h"
#import "HPPPPrintSettings.h"

@class HPPPPaper;
@class HPPPPrintItem;
@protocol HPPPPrintPaperDelegate;

#define LAST_PRINTER_USED_URL_SETTING @"lastPrinterUrlUsed"
#define HPPP_ERROR_DOMAIN @"com.hp.hppp"
#define HPPP_ANIMATION_DURATION 0.6F

#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#define IS_IPHONE_4 ([[UIScreen mainScreen] bounds].size.height == 480.0f)
#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height == 568.0f)
#define IS_IPHONE_6 ([[UIScreen mainScreen] bounds].size.height == 667.0f)
#define IS_IPHONE_6_PLUS ([[UIScreen mainScreen] bounds].size.height == 736.0f)

#define IS_SPLIT_VIEW_CONTROLLER_IMPLEMENTATION (IS_OS_8_OR_LATER && IS_IPAD)

#define IS_PORTRAIT UIDeviceOrientationIsPortrait((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation)
#define IS_LANDSCAPE UIDeviceOrientationIsLandscape((UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation)

#define DEGREES_TO_RADIANS(x) (x * M_PI/180.0)

extern NSString * const kLaterActionIdentifier;
extern NSString * const kPrintActionIdentifier;
extern NSString * const kPrintCategoryIdentifier;

@protocol HPPPPrintDelegate;
@protocol HPPPPrintDataSource;
@protocol HPPPAddPrintLaterDelegate;

/*!
 * @abstract Main HP Photo Print manager class
 * @discussion This singleton class manages configuration settings and stored job information.
 */
@interface HPPP : NSObject

/*!
 * @abstract Indicates the version of the print library
 * @discussion Full version history can be found at: https://github.com/IPGPTP/hp_photo_print/wiki/Release-Notes
 */
extern NSString * const kHPPPLibraryVersion;

/*!
 * @abstract Notifies subscribers that a share action was completed
 * @discussion Clients can use this notification to indicate that the user completed a sharing action. This is useful for collecting and reporting analytics.
 */
extern NSString * const kHPPPShareCompletedNotification;

/*!
 * @abstract Notifies subscribers that a trackable screen was visited
 * @discussion Clients can use this notification to indicate that the user visited a trackable screen. This is useful for collecting and reporting analytics.
 * @seealso kHPPPTrackableScreenNameKey
 */
extern NSString * const kHPPPTrackableScreenNotification;

/*!
 * @abstract Used to retrieve name of the trackable screen
 * @discussion This key works with the trackable screen notification to inform the client application when a trackable screen was visited.
 * @seealso kHPPPTrackableScreenNotification
 */
extern NSString * const kHPPPTrackableScreenNameKey;

/*!
 * @abstract Notifies subscribers with the result of the printer avaiability check
 * @discussion Clients can use this notification to update the user interface with printer status
 * @seealso kHPPPPrinterAvailableKey
 * @seealso kHPPPPrinterAvailabilityNotification
 */
extern NSString * const kHPPPPrinterAvailabilityNotification;

/*!
 * @abstract Used to retrieve availability of the printer
 * @discussion This key works with the printer available notification to inform the client application whether the printer was available or not.
 * @seealso kHPPPPrinterAvailabilityNotification
 * @seealso kHPPPPrinterKey
 */
extern NSString * const kHPPPPrinterAvailableKey;

/*!
 * @abstract Used to retrieve printer that was checked for avaiability
 * @discussion This key works with the printer available notification to communicate the UIPrinter object that was checked for availability.
 * @seealso kHPPPPrinterAvailabilityNotification
 * @seealso kHPPPPrinterAvailableKey
 */
extern NSString * const kHPPPPrinterKey;

/*!
 * @abstract Notifies subscribers that a print queue operation was completed (print or delete)
 * @seealso kHPPPPrintQueueActionKey
 * @seealso kHPPPPrintQueueJobKey
 * @seealso kHPPPPrintQueuePrintItemKey
 */
extern NSString * const kHPPPPrintQueueNotification;

/*!
 * @abstract The notification sent when a job is added to the print queue
 */
extern NSString * const kHPPPPrintJobAddedToQueueNotification;

/*!
 * @abstract The notification sent when a job is removed from the print queue
 */
extern NSString * const kHPPPPrintJobRemovedFromQueueNotification;

/*!
 * @abstract The notification sent when all jobs are removed from the print queue
 */
extern NSString * const kHPPPAllPrintJobsRemovedFromQueueNotification;

/*!
 * @abstract Used to retrieve the action performed on the job
 * @seealso kHPPPPrintQueueNotification
 * @seealso kHPPPPrintQueueJobKey
 * @seealso kHPPPPrintQueuePrintItemKey
 */
extern NSString * const kHPPPPrintQueueActionKey;

/*!
 * @abstract Used to retrieve the HPPPPrintLater job that was printed or deleted
 * @seealso kHPPPPrintQueueNotification
 * @seealso kHPPPPrintQueueActionKey
 * @seealso kHPPPPrintQueuePrintItemKey
 */
extern NSString * const kHPPPPrintQueueJobKey;

/*!
 * @abstract Used to retrieve the specific print item from the job that was printed or deleted
 * @seealso kHPPPPrintQueueNotification
 * @seealso kHPPPPrintQueueActionKey
 * @seealso kHPPPPrintQueueJobKey
 */
extern NSString * const kHPPPPrintQueuePrintItemKey;

/*!
 * @abstract Notification used to indicate when Wi-Fi connection is established
 */
extern NSString * const kHPPPWiFiConnectionEstablished;

/*!
 * @abstract Notification used to indicate when Wi-Fi connection is lost
 */
extern NSString * const kHPPPWiFiConnectionLost;

/*!
 * @abstract Used to retrieve last paper size used
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the paper size used.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPaperSizeId;

/*!
 * @abstract Used to retrieve last paper type used
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the paper type used.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPaperTypeId;


/*!
 * @abstract Used to retrieve width of the last paper size used
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the width in inches of the last paper used.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPaperWidthId;

/*!
 * @abstract Used to retrieve height of the last paper size used
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the height in inches of the last paper used.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPaperHeightId;

/*!
 * @abstract Used to retrieve last black/white setting used
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain a true/false value indicating if black/white was chosen.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPBlackAndWhiteFilterId;

/*!
 * @abstract Used to retrieve ID of the printer used for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the ID of the printer that was used.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterId;

/*!
 * @abstract Used to retrieve display name of the printer used for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. Only available in iOS 8 after the printer has been contacted successfully.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterDisplayName;

/*!
 * @abstract Used to retrieve the total number of pages in the document used for the last job
 */
extern NSString * const kHPPPNumberPagesDocument;

/*!
 * @abstract Used to retrieve the total number of pages the user selected to print for the last job
 */
extern NSString * const kHPPPNumberPagesPrint;

/*!
 * @abstract Used to retrieve display location of the printer used for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. Only available in iOS 8 after the printer has been contacted successfully.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterDisplayLocation;

/*!
 * @abstract Used to retrieve ID of the printer used for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. Only available in iOS 8 after the printer has been contacted successfully.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterMakeAndModel;

/*!
 * @abstract Used to retrieve number of copies used for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the number of copies that was used.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPNumberOfCopies;

/*!
 * @abstract Used to retrieve the width of the paper (in points) for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the width of the paper in points.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterPaperWidthPoints;

/*!
 * @abstract Used to retrieve the height of the paper (in points) for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the height of the paper in points.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterPaperHeightPoints;

/*!
 * @abstract Used to retrieve the width of the printing rectangle (in points) for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the width of the printing rectangle in points.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterPaperAreaWidthPoints;

/*!
 * @abstract Used to retrieve the height of the printing rectangle (in points) for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the height of the printing rectangle in points.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterPaperAreaHeightPoints;

/*!
 * @abstract Used to retrieve the x coordinate of the printing rectangle origin (in points) for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the x coordinate of the printing rectangle origin in points.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterPaperAreaXPoints;

/*!
 * @abstract Used to retrieve the y coordinate of the printing rectangle origin (in points) for the last job
 * @discussion This key works with the dictionary contained in the @link lastOptionsUsed @/link property. If the last job was successful, the value for this key will contain the y coordinate of the printing rectangle origin in points.
 * @seealso lastOptionsUsed
 */
extern NSString * const kHPPPPrinterPaperAreaYPoints;

/*!
 * @abstract Job name of the print
 */
@property (strong, nonatomic) NSString *printJobName;

/*!
 * @abstract Indicates whether the black and white option should be hidden
 * @discussion If this value is true, the black and white filter option is hidden on the print preview page and the black and white filter is not used. The default values is false (not hidden).
 *   The black and white filter option is only available for iOS version 8.0 and above.
 */
@property (assign, nonatomic) BOOL hideBlackAndWhiteOption;

/*!
 * @abstract Indicates whether the paper size option should be hidden
 * @discussion If this value is true, the paper size option is hidden on the print preview page and the default paper size is used. The default values is false (not hidden).
 * @seealso defaultPaper
 */
@property (assign, nonatomic) BOOL hidePaperSizeOption;

/*!
 * @abstract Indicates whether the paper type option should be hidden
 * @discussion If this value is true, the paper type option is hidden on the print preview page and the default paper type is used if applicable (e.g. 4x6 always uses photo paper regardless of the value of the default paper type). The default value is false (not hidden).
 * @seealso defaultPaper
 */
@property (assign, nonatomic) BOOL hidePaperTypeOption;

/*!
 * @abstract List of supported paper sizes
 * @discussion An array of HPPPPaper objects specifying the list of supported papers
 * @seealso HPPPPaper
 */
@property (strong, nonatomic) NSArray *supportedPapers;

/*!
 * @abstract Default paper
 * @discussion An @link HPPPPaper @/link object specifying the default paper size and type to use. 
 * This object is used to set the initial selection for paper size and paper type. It is also used as the value for paper size when the paper size selection is hidden. 
 * Default initial value is @link HPPPPaperSize5x7 @/link .  Note that paper type does not apply to all paper sizes (e.g. 4x6 always uses photo paper regardless what paper type is specified). 
 * Default value is @link HPPPPaperTypePhoto @/link .
 */
@property (strong, nonatomic) HPPPPaper *defaultPaper;

/*!
 * @abstract A dictionary of the most recent print options used
 * @discussion If the last print job was successful this property contains a dictionary of various options used for the job. If the last print job failed or was canceled then this property contains an empty dictionary.
 * @seealso kHPPPBlackAndWhiteFilterId
 * @seealso kHPPPPaperSizeId
 * @seealso kHPPPPaperTypeId
 * @seealso kHPPPPaperWidthId
 * @seealso kHPPPPaperHeightId
 * @seealso kHPPPPrinterId
 * @seealso kHPPPPrinterDisplayName
 * @seealso kHPPPPrinterDisplayLocation
 * @seealso kHPPPPrinterMakeAndModel
 * @seealso kHPPPNumberOfCopies
 * @seealso kHPPPPrinterPaperWidthPoints
 * @seealso kHPPPPrinterPaperHeightPoints
 * @seealso kHPPPPrinterPaperAreaWidthPoints
 * @seealso kHPPPPrinterPaperAreaHeightPoints
 * @seealso kHPPPPrinterPaperAreaXPoints
 * @seealso kHPPPPrinterPaperAreaYPoints
 */
@property (strong, nonatomic) NSDictionary *lastOptionsUsed;

/*!
 * @abstract An array of support actions to display on the print preview page
 * @discussion This is an array of @link HPPPSupportAction @/link objects, each describing a single support action. Support actions include an icon and a title and are displayed in a support section at the bottom of the print preview page. An action can either open a URL or present a view controller.
 * @seealso HPPPSupportAction
 */
@property (strong, nonatomic) NSArray *supportActions;

/*!
 * @abstract Causes the HPPrintProvider pod to handle metrics for the print activity.
 * @discussion Defaults to YES. If set to NO, the pod will not send metrics for the print activity automatically. However, the client application can still record print metrics using the notification kHPPPShareCompletedNotification.
 * @seealso kHPPPShareCompletedNotification
 */
@property (assign, nonatomic) BOOL handlePrintMetricsAutomatically;

/*!
 * @abstract Used to customize look and feel
 * @discussion Allows customization of the look and feel of the print later screens (e.g. fonts, colors, buttons, etc.).
 */
@property (strong, nonatomic) HPPPAppearance *appearance;

/*!
 * @abstract Options used to configure the user interface
 * @discussion Options are used to configure the UI and other behavior of the print activity
 * @seealso HPPPInterfaceOptions
 */
@property (strong, nonatomic) HPPPInterfaceOptions *interfaceOptions;

/*!
 * @abstract Specifies an object implementing the HPPPPrintPaperDelegate protocol
 * @discussion The print paper delegate is used to control paper-related features
 * @seealso HPPPPrintPaperDelegate
 */
@property (weak, nonatomic) id<HPPPPrintPaperDelegate>printPaperDelegate;

/*!
 * @abstract Specifies that each app is assigned a unique device ID regardless of vendor
 * @discussion By default, Apple assigns a common device ID that is shared among all apps owned by a given vender. This setting causes a unique ID to be assigned to all apps regardless of vendor.
 */
@property (assign, nonatomic) BOOL uniqueDeviceIdPerApp;

/*!
 * @abstract Indicates whether the cancel button on page settings screen is on the left or right of the navigationItem
 * @discussion If this value is true, the cancel button will show on the left of the navigation item on PageSettings otherwise it will appear on the right.  Default is right.
 */
@property (assign, nonatomic) BOOL pageSettingsCancelButtonLeft;


/*!
 * @abstract Prepares a view controller suitable for the device and OS
 * @description This method prepares a view controller for displaying the print flow. It takes into consideration the device type and OS and prepares either a split view controller (iPad with iOS 8 or above) or a standard view controller. Both types are wrapped in a navigation controller. The controller returned is suitable for using with the UIActivity method 'activityViewController'.
 * @param delegate An optional delegate object that implements the HPPPPrintDelegate protocol
 * @param dataSource An optional data source object that implements the HPPPPrintDataSource protocol
 * @param printItem The item to print
 * @param fromQueue Indicates if controller being requested from the print queue
 * @param settingsOnly Indicates that the controller will be used for settings only and not for printing
 * @return The view controller that the client should present
 */
- (UIViewController *)printViewControllerWithDelegate:(id<HPPPPrintDelegate>)delegate dataSource:(id<HPPPPrintDataSource>)dataSource printItem:(HPPPPrintItem *)printItem fromQueue:(BOOL)fromQueue settingsOnly:(BOOL)settingsOnly;

/*!
 * @abstract Prepares a view controller suitable for the device and OS
 * @description This method prepares a view controller for displaying the "add to print queue" flow. It takes into consideration the device type and OS and prepares either a split view controller (iPad with iOS 8 or above) or a standard view controller. Both types are wrapped in a navigation controller. The controller returned is suitable for using with the UIActivity method 'activityViewController'.
 * @param delegate An optional delegate object that implements the HPPPAddPrintLaterDelegate protocol
 * @param printLaterJob The printLaterJob populated with appropriate printItem(s)
 * @return The view controller that the client should present
 */
- (UIViewController *)printLaterViewControllerWithDelegate:(id<HPPPAddPrintLaterDelegate>)delegate printLaterJob:(HPPPPrintLaterJob *)printLaterJob;

/*!
 * @abstract User notification category used for print reminder
 * @discussion UIUserNotificationCategory to register in the clients for push notifications of the print later. The clients must do the registration because it may happen that the client have other notification categories to register, and all the registration must be do at the same time, otherwise the new category will override the previous one.
 */
- (UIUserNotificationCategory *)printLaterUserNotificationCategory;

/*!
 * @abstract Handles when the user taps an action button on the notification dialog
 */
- (void)handleNotification:(UILocalNotification *)notification;

/*!
 * @abstract Handles when the user taps the notification itself
 * @discussion This method is called when the user taps the notification body itself rather than one of the specific action buttons
 */
- (void)handleNotification:(UILocalNotification *)notification action:(NSString *)action;

/*!
 * @abstract Displays the list of print jobs modally
 * @discussion This method prepares an instance of a view controller with the contents of the print queue and displays it modally.
 * @param controller The controller used as the parent for displaying the modal view controller
 * @param animated A boolean indicating whether or not to animate the display
 * @param completion A block to call when the display animation is complete
 */
- (void)presentPrintQueueFromController:(UIViewController *)controller animated:(BOOL)animated completion:(void(^)(void))completion;

/*!
 * @abstract Retrieves the total number of jobs currently in the print queue
 * @return An integer representing the number of jobs
 */
- (NSInteger)numberOfJobsInQueue;

/*!
 * @abstract Used to get the next available job ID
 * @return The next available job ID
 */
- (NSString *)nextPrintJobId;

/*!
 * @abstract Add a print job to the print queue
 */
- (void)addJobToQueue:(HPPPPrintLaterJob *)job;

/*!
 * @abstract Removes all jobs from the print queue
 */
- (void)clearQueue;

/*!
 * @abstract Indicates whether or not Wi-Fi is connected
 * @return YES or NO
 */
- (BOOL)isWifiConnected;

/*!
 * @abstract Used to access the singleton instance of this class
 */
+ (HPPP *)sharedInstance;

@end

/*!
 * @abstract Defines a delegate protocal for reporting print events
 * @seealso HPPPPrintDataSource
 */
@protocol HPPPPrintDelegate <NSObject>

/*!
 * @abstract Called when the print flow finishes successfully
 * @discussion This delegate method is called when the print flow finishes successfully. This means that the print job was sent to the printer without error. It does not mean that the job was completed and printed without error, just that the job was queued successfully. Errors such as out-of-paper could still occur after this method is called.
 * @param printViewController The view controller calling the method
 * @returns Nothing
 * @seealso didCancelPrintFlow:
 */
- (void)didFinishPrintFlow:(UIViewController *)printViewController;

/*!
 * @abstract Called when the print flow is canceled
 * @discussion This method is called when the print flow is canceled by the user. If the print job is queued successfully but subsequently canceled by the user in the Print Center, this method is not called.
 * @param printViewController The view controller calling the method
 * @returns Nothing
 * @seealso didFinishPrintFlow:
 */
- (void)didCancelPrintFlow:(UIViewController *)printViewController;

@end

/*!
 * @abstract Defines a data source protocol for requesting the printable image
 * @seealso HPPPPrintDelegate
 */
@protocol HPPPPrintDataSource <NSObject>

/*!
 * @abstract Called when a new printing item is needed
 * @discussion This method is called when initiating the print flow or whenever relevant parameters are changed (e.g. page size).
 * @param paper The @link HPPPPaper @/link object that the item will be laid out on
 * @seealso HPPPPaper
 */
- (void)printingItemForPaper:(HPPPPaper *)paper withCompletion:(void (^)(HPPPPrintItem * printItem))completion;

/*!
 * @abstract Called when a new preview image is needed
 * @discussion This method is called when initiating the print flow or whenever relevant parameters are changed (e.g. page size).
 * @param paper The @link HPPPPaper @/link object that the item will be laid out on
 * @seealso HPPPPaper
 */
- (void)previewImageForPaper:(HPPPPaper *)paper withCompletion:(void (^)(UIImage *previewImage))completion;

@optional

/*!
 * @abstract Called to request the total number of print jobs to print
 * @return The number of jobs to print
 * @seealso printingItemsForPaper:
 */
- (NSInteger)numberOfPrintingItems;

/*!
 * @abstract Called to request the list of HPPPPrintLaterJob objects for printing.
 * @discussion This function offers an alternate method of printing a collection of print jobs to the other option of giving four parallel arrays of
 *  HPPPPrintItem, HPPPPageRange, NSNumbers (for wrapping black and white BOOL data), and NSNumbers (for wrapping number of copies NSInteger data).  
 *  If this function is implemented, the parallel arrays will be ignored (IE, printingItemsForPaper:, pageRangeSelections, blackAndWhiteSelections,
 *  and numCopiesSelections will not be called.
 * @return An array of HPPPPrintLaterJobs to be printed
 * @seealso numberOfPrintingItems
 */
- (NSArray *)printLaterJobs;

/*!
 * @abstract Called to request the printing item for each job
 * @discussion When using this function, the numberOfCopiesSelections, blackAndWhiteSelections, and HPPPPageRange selection 
 *  functions should also be implemented.  If they aren't used, default values will be used.
 * @param paper The type and size of paper being requested
 * @return An array of printing items for this paper size/type, one item per job
 * @seealso numberOfPrintingItems
 */
- (NSArray *)printingItemsForPaper:(HPPPPaper *)paper;

/*!
 * @abstract Called to request the page range for each job
 * @discussion This function is used in conjunction with printingItemsForPaper:.  This function should return an array with
 *  parallel values to the array returned by printingItemsForPaper:.
 * @return An array of page ranges for each job, in the same order as the array returned by printingItemsForPaper:
 *  The page ranges are stored in HPPPPageRange objects
 * @seealso numberOfPrintingItems
 * @seealso printingItemsForPaper:
 * @seealso numberOfCopiesSelections
 * @seealso blackAndWhiteSelections
 * @seealso HPPPPageRange
 */
- (NSArray *)pageRangeSelections;

/*!
 * @abstract Called to request the black-and-white preference for each job
 * @discussion This function is used in conjunction with printingItemsForPaper:.  This function should return an array with
 *  parallel values to the array returned by printingItemsForPaper:.
 * @return An array of black and white preferences for each job, in the same order as the array returned by printingItemsForPaper:
 *  The black and white preferences are BOOL values stored in NSNumber objects.
 * @seealso numberOfPrintingItems
 * @seealso printingItemsForPaper:
 * @seealso pageRangeSelections
 * @seealso numberOfCopiesSelections
 */
- (NSArray *)blackAndWhiteSelections;

/*!
 * @abstract Called to request the number of copies for each job
 * @discussion This function is used in conjunction with printingItemsForPaper:.  This function should return an array with
 *  parallel values to the array returned by printingItemsForPaper:.
 * @return An array of the number of copy preferences for each job, in the same order as the array returned by printingItemsForPaper:
 *  Each number of copies is stored in an NSNumber object.
 * @seealso numberOfPrintingItems
 * @seealso printingItemsForPaper:
 * @seealso pageRangeSelections
 * @seealso blackAndWhiteSelections
 */
- (NSArray *)numberOfCopiesSelections;

@end

/*!
 * @abstract Defines a delegate protocal for reporting that the "add job to print queue" flow has been finished or cancelled
 */
@protocol HPPPAddPrintLaterDelegate <NSObject>

/*!
 * @abstract Called when the "add to print queue" flow finishes successfully
 * @discussion This delegate method is called when the "add to print queue" flow finishes successfully.
 * @param addPrintLaterJobTableViewController The view controller calling the method
 * @returns Nothing
 * @seealso didCancelAddPrintLaterFlow:
 */
- (void)didFinishAddPrintLaterFlow:(UIViewController *)addPrintLaterJobTableViewController;

/*!
 * @abstract Called when the "add to print queue" flow is canceled
 * @discussion This delegate method is called when the "add to print queue" is canceled by the user..
 * @param addPrintLaterJobTableViewController The view controller calling the method
 * @returns Nothing
 * @seealso didFinishAddPrintLaterFlow:
 */
- (void)didCancelAddPrintLaterFlow:(UIViewController *)addPrintLaterJobTableViewController;

@end

/*!
 * @abstract Defines a protocol for adjusting paper settings based on print settings
 */
@protocol HPPPPrintPaperDelegate <NSObject>

@optional

/*!
 * @abstract Indicates whether or not the paper size should be hidden in the UI
 * @discussion This delegate method allows for hiding the paper size field depending on the current print settings (e.g. hide for a specific type of printer)
 * @param printSettings The print settings to use to decide if the paper size should be hidden
 * @returns YES or NO
 * @seealso hidePaperTypeForPrintSettings:
 */
- (BOOL)hidePaperSizeForPrintSettings:(HPPPPrintSettings *)printSettings;


/*!
 * @abstract Indicates whether or not the paper type should be hidden in the UI
 * @discussion This delegate method allows for hiding the paper type field depending on the current print settings (e.g. hide for a specific type of printer)
 * @param printSettings The print settings to use to decide if the paper type should be hidden
 * @returns YES or NO
 * @seealso hidePaperSizeForPrintSettings:
 */
- (BOOL)hidePaperTypeForPrintSettings:(HPPPPrintSettings *)printSettings;

/*!
 * @abstract Allows for changing the default paper for certain print settings
 * @discussion The default paper specified must match one of the supported papers. If the default paper returned is not in the supported paper list, it will be ignored and the default paper will not change.
 * @param printSettings The print settings to use to decide what default paper to use
 * @returns An HPPPPaper object to use as the default paper
 * @seealso supportedPapersForPrintSettings:
 */
- (HPPPPaper *)defaultPaperForPrintSettings:(HPPPPrintSettings *)printSettings;

/*!
 * @abstract Allows for changing the list of supported papers for certain print settings
 * @param printSettings The print settings to use to decide what supported paper list to use
 * @returns An array of HPPPPaper objects to use for the list of supported papers
 * @seealso defaultPaperForPrintSettings:
 * @seealso supportedPapers
 */
- (NSArray *)supportedPapersForPrintSettings:(HPPPPrintSettings *)printSettings;

/*!
 * @abstract Allows for handling of choose paper delegate based on print settings used
 * @discussion This method provides a means of handling the low-level choosePaper delegate that is part of the UIPrintInteractionControllerDelegate protocol.
 * If implemented, the value returned by this method will be used instead of the default processing used by the HPPhotoPrint pod.
 * @param printInteractionController The print interaction controller being used to print
 * @param paperList The list of papers passed to the original low-level method
 * @param printSettings The print settings currently being used
 * @returns A UIPrintPaper object that specifies the desired print geometry
 * @seealso printInteractionController:cutLengthForPaper:forPrintSettings:
 */
- (UIPrintPaper *)printInteractionController:(UIPrintInteractionController *)printInteractionController choosePaper:(NSArray *)paperList forPrintSettings:(HPPPPrintSettings *)printSettings;

/*!
 * @abstract Allows for handling of cut length delegate based on print settings used
 * @discussion This method provides a means of handling the low-level cutLengthForPaper: delegate that is part of the UIPrintInteractionControllerDelegate protocol.
 * If implemented, the value returned by this method will be used instead of the default processing used by the HPPhotoPrint pod.
 * Cut length is used for roll-based printers.
 * @param printInteractionController The print interaction controller being used to print
 * @param paper The paper used to determine the cut length
 * @param printSettings The print settings currently being used
 * @returns An NSNumber object representing the desired cut length in points
 * @seealso printInteractionController:choosePaper:forPrintSettings:
 */
- (NSNumber *)printInteractionController:(UIPrintInteractionController *)printInteractionController cutLengthForPaper:(UIPrintPaper *)paper forPrintSettings:(HPPPPrintSettings *)printSettings;

@end