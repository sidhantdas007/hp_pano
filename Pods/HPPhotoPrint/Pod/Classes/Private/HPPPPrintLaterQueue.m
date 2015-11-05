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
#import "HPPPPageRange.h"
#import "HPPPPrintLaterQueue.h"
#import "HPPPPrintLaterActivity.h"
#import "HPPPAnalyticsManager.h"
#import "HPPPPrintItem.h"

@interface HPPPPrintLaterQueue()

@property (nonatomic, strong) NSString *printLaterJobsDirectoryPath;

@end

@implementation HPPPPrintLaterQueue

#define PRINT_LATER_JOBS_DIRECTORY_NAME @"PrintLaterJobs"

NSString * const kHPPPPrintLaterJobNextAvailableId = @"kHPPPPrintLaterJobNextAvailableId";

NSString * const kHPPPOfframpAddToQueueShare = @"AddToQueueFromShare";
NSString * const kHPPPOfframpAddToQueueCustom = @"AddToQueueFromClientUI";
NSString * const kHPPPOfframpAddToQueueDirect = @"AddToQueueWithNoUI";
NSString * const kHPPPOfframpDeleteFromQueue = @"DeleteFromQueue";

+ (HPPPPrintLaterQueue *)sharedInstance
{
    static HPPPPrintLaterQueue *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HPPPPrintLaterQueue alloc] init];
    });
    
    return sharedInstance;
}

- (NSString *)retrievePrintLaterJobNextAvailableId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger printLaterJobNextAvailableId = [defaults integerForKey:kHPPPPrintLaterJobNextAvailableId];
    
    printLaterJobNextAvailableId++;
    
    [defaults setInteger:printLaterJobNextAvailableId forKey:kHPPPPrintLaterJobNextAvailableId];
    [defaults synchronize];
    
    return [NSString stringWithFormat:@"ID%08lX", (long)printLaterJobNextAvailableId];
}

#pragma mark - Getter methods

-(NSString *)printLaterJobsDirectoryPath
{
    if (nil == _printLaterJobsDirectoryPath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _printLaterJobsDirectoryPath = [documentsDirectory stringByAppendingPathComponent: PRINT_LATER_JOBS_DIRECTORY_NAME];
        
        [self createDirectory:PRINT_LATER_JOBS_DIRECTORY_NAME atPath:documentsDirectory];
    }
    
    return _printLaterJobsDirectoryPath;
}

#pragma mark - Utils methods

- (BOOL)addPrintLaterJob:(HPPPPrintLaterJob *)printLaterJob fromController:(HPPPPageSettingsTableViewController *)controller
{
    NSString *fileName = [self.printLaterJobsDirectoryPath stringByAppendingPathComponent:printLaterJob.id];
    BOOL success = [NSKeyedArchiver archiveRootObject:printLaterJob toFile:fileName];
    
    if (success) {

        [[NSNotificationCenter defaultCenter] postNotificationName:kHPPPPrintJobAddedToQueueNotification object:printLaterJob userInfo:nil];
        
        NSString *offramp = kHPPPOfframpAddToQueueCustom;
        if (!controller) {
            offramp = kHPPPOfframpAddToQueueDirect;
        } else if ([controller.printLaterDelegate class] == [HPPPPrintLaterActivity class]) {
            offramp = kHPPPOfframpAddToQueueShare;
        }
        
        [printLaterJob prepareMetricswithOfframp:offramp];
        
        if ([HPPP sharedInstance].handlePrintMetricsAutomatically) {
            [[HPPPAnalyticsManager sharedManager] trackShareEventWithPrintItem:printLaterJob.defaultPrintItem andOptions:printLaterJob.extra];
        }
    }
    
    return success;
}

- (BOOL)deletePrintLaterJob:(HPPPPrintLaterJob *)printLaterJob
{
    BOOL success = [self deleteFile:printLaterJob.id atPath:self.printLaterJobsDirectoryPath];
    
    if (success) {
    
        [printLaterJob prepareMetricswithOfframp:kHPPPOfframpDeleteFromQueue];
        
        NSDictionary *values = @{
                                 kHPPPPrintQueueActionKey:kHPPPOfframpDeleteFromQueue,
                                 kHPPPPrintQueueJobKey:printLaterJob,
                                 kHPPPPrintQueuePrintItemKey:printLaterJob.defaultPrintItem };

        [[NSNotificationCenter defaultCenter] postNotificationName:kHPPPPrintQueueNotification object:values];
        [[NSNotificationCenter defaultCenter] postNotificationName:kHPPPPrintJobRemovedFromQueueNotification object:printLaterJob userInfo:nil];
        if ([self retrieveNumberOfPrintLaterJobs] == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kHPPPAllPrintJobsRemovedFromQueueNotification object:self userInfo:nil];
        }

        if ([HPPP sharedInstance].handlePrintMetricsAutomatically) {
            [[HPPPAnalyticsManager sharedManager] trackShareEventWithPrintItem:printLaterJob.defaultPrintItem andOptions:printLaterJob.extra];
        }
    }
    
    return  success;
}

- (BOOL)deleteAllPrintLaterJobs
{
    BOOL success = [self deleteAllFilesAtPath:self.printLaterJobsDirectoryPath];
    
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kHPPPAllPrintJobsRemovedFromQueueNotification object:self userInfo:nil];
    }
    
    return  success;
}

- (HPPPPrintLaterJob *)retrievePrintLaterJobWithID:(NSString *)id
{
    NSString *fileName = [self.printLaterJobsDirectoryPath stringByAppendingPathComponent:id];
    
    return [NSKeyedUnarchiver unarchiveObjectWithFile:fileName];
}

- (NSArray *)retrieveAllPrintLaterJobs
{
    NSMutableArray *printLaterJobs = [NSMutableArray array];
    
    NSArray *fileArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.printLaterJobsDirectoryPath error:nil];
    
    for (NSString *filename in fileArray)  {
        NSString *completeFileName = [self.printLaterJobsDirectoryPath stringByAppendingPathComponent:filename];
        
        HPPPPrintLaterJob *printLaterJob = [NSKeyedUnarchiver unarchiveObjectWithFile:completeFileName];
        [printLaterJobs addObject:printLaterJob];
    }
    
    // Last one added first in the list
    return [[printLaterJobs reverseObjectEnumerator] allObjects];
}

- (NSInteger)retrieveNumberOfPrintLaterJobs
{
    NSArray *fileArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.printLaterJobsDirectoryPath error:nil];
    
    return fileArray.count;
}

#pragma mark - Filesystem manipulation methods

- (BOOL)createDirectory:(NSString *)directoryName atPath:(NSString *)path
{
    BOOL success = YES;
    
    NSString *pathAndDirectory = [path stringByAppendingPathComponent:directoryName];
    NSError *error;
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:pathAndDirectory
                                   withIntermediateDirectories:NO
                                                    attributes:nil
                                                         error:&error]) {
        HPPPLogError(@"Create directory error: %@", error);
        success = NO;
    }
    
    return success;
}

- (BOOL)deleteFile:(NSString *)fileName atPath:(NSString *)path
{
    BOOL success = YES;
    
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
        HPPPLogError(@"Delete file error: %@", error);
        success = NO;
    }
    
    return success;
}

- (BOOL)deleteAllFilesAtPath:(NSString *)path
{
    BOOL success = YES;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:nil];
    for (NSString *filename in files)  {
        NSError *error = nil;
        if (![fileManager removeItemAtPath:[path stringByAppendingPathComponent:filename] error:&error]) {
            HPPPLogError(@"Delete file error: %@", error);
            success = NO;
        }
    }
    
    return success;
}

@end
