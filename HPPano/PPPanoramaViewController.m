//
//  PPPanoramaViewController.m
//  HPPano
//
//  Created by P&I Lab on 11/6/15.
//  Copyright © 2015 HP Inc. All rights reserved.
//

#import "PPPanoramaViewController.h"
#import "PPPanoramaTableViewCell.h"
#import "PPPreviewViewController.h"
#import <Photos/Photos.h>
#import <MP.h>
#import <MPLayout.h>
#import <MPPrintItemFactory.h>
#import <MPLayoutFactory.h>
#import <MPPaper.h>

@interface PPPanoramaViewController () <MPPrintDelegate>

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewImageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewImageWidthConstraint;
@property (strong, nonatomic) UIBarButtonItem *printButton;
@property (strong, nonatomic) NSArray<PHAsset *> *panoramaAssets;
@property (strong, nonatomic) NSMutableArray<NSNumber *> *selectedPanoramas; // table row number of selected items
@property (strong, nonatomic) NSMutableArray<UIImage *> *printableImages;
@property (strong, nonatomic) NSMutableArray<UIImage *> *previewImages;
@property (weak, nonatomic) IBOutlet UIButton *authorizeButton;
@property (weak, nonatomic) IBOutlet UILabel *noPanoLabel;

@end

@implementation PPPanoramaViewController

NSString * const kPanoramaCellIdentifier = @"Pano Cell";
CGFloat kHeaderHeight = 30.0;
CGFloat kPreviewHeight = 140.0;
CGFloat kPreviewImageHeight = 120.0;
CGFloat kPreviewSmallStripHeight = 50.0;
CGFloat kPreviewLargeStripHeight = 200.0;
CGFloat kMaximumStripHeight = MAXFLOAT;
NSInteger kMaximumSelections = 3;
CGFloat kDPI = 300.0;
CGFloat kPaperWidth = 7.0; // inches
CGFloat kPaperHeight = 5.0; // inches
CGFloat kStripWidth = 7.0; // inches
CGFloat kStripHeight = 1.375; // inches
CGFloat kAnimationDuration = 0.61803399; //seconds

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureMP];
    [self preparePrintIcon];
    [self configureGestures];
    self.panoramaAssets = @[];
    self.selectedPanoramas = [NSMutableArray array];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self verifyAccess];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureMP
{
    MPPaper *paper = [[MPPaper alloc] initWithPaperSize:MPPaperSize5x7 paperType:MPPaperTypePhoto];
    [MP sharedInstance].defaultPaper = paper;
    [MP sharedInstance].supportedPapers = @[ paper ];
    [MP sharedInstance].hidePaperSizeOption = YES;
    [MP sharedInstance].hidePaperTypeOption = YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

 #pragma mark - Navigation
 
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
    PPPreviewViewController *vc = (PPPreviewViewController *)navController.topViewController;
    vc.images = self.previewImages;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.panoramaAssets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PPPanoramaTableViewCell *cell = (PPPanoramaTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kPanoramaCellIdentifier forIndexPath:indexPath];
    NSNumber *row = [NSNumber numberWithInteger:indexPath.row];
    cell.included = [self.selectedPanoramas containsObject:row];
    cell.asset = self.panoramaAssets[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PPPanoramaTableViewCell *cell = (PPPanoramaTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.included = !cell.included;
    if (cell.included) {
        [self addItem:indexPath.row];
    } else {
        [self removeItem:indexPath.row];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kHeaderHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    view.tintColor = [UIColor whiteColor];
}

#pragma mark - Action buttons

- (void)preparePrintIcon
{
    self.printButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"printIcon"]
                        style:UIBarButtonItemStylePlain
                        target:self
                        action:@selector(printTapped:)];
    
    [self enablePrint:NO];
    self.navigationItem.rightBarButtonItem = self.printButton;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0 green:150.0 / 255.0 blue:214.0 / 255.0 alpha:1.0];
}

- (void)printTapped:(id)sender
{
    [self initiatePrint];
}

#pragma mark - Print utilities
- (void)retrieveImages:(NSMutableArray *)images height:(CGFloat)height completion:(void(^)(void))completion
{
    if (0 == self.selectedPanoramas.count) {
        if (completion) {
            completion();
        }
        return;
    }
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.synchronous = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger item = [self.selectedPanoramas[images.count] integerValue];
        
        PHAsset *asset = self.panoramaAssets[item];
        CGSize size = PHImageManagerMaximumSize;
        if (kMaximumStripHeight != height) {
            CGFloat scale = asset.pixelHeight / height;
            size = CGSizeMake(asset.pixelWidth / scale, height);
        }
        
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
                [images addObject:result];
                if (images.count < self.selectedPanoramas.count) {
                    [self retrieveImages:images height:height completion:completion];
                } else {
                    if (completion) {
                        completion();
                    }
                }
            } else {
                NSLog(@"IMAGE FAIL:\n\n%ld\n\n%@\n\n%@", (long)images.count, self.panoramaAssets[images.count], info);
            }
        }];
    });
 
}

- (void)presentPrintController
{
    UIImage *image = [self combinedImages:self.printableImages resolution:kDPI showLines:NO];
    MPPrintItem *printItem = [MPPrintItemFactory printItemWithAsset:image];
    printItem.layout = [MPLayoutFactory layoutWithType:[MPLayoutFit layoutType] orientation:MPLayoutOrientationLandscape assetPosition:[MPLayout completeFillRectangle]];
    UIViewController *vc = [[MP sharedInstance] printViewControllerWithDelegate:self dataSource:nil printItem:printItem fromQueue:NO settingsOnly:NO];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)initiatePrint
{
    self.printableImages = [NSMutableArray array];
    [self retrieveImages:self.printableImages height:kMaximumStripHeight completion:^{
        [self presentPrintController];
    }];
}

- (UIImage *)combinedImages:(NSArray *)images resolution:(CGFloat)resolution showLines:(BOOL)showLines
{
    CGSize overallSize = CGSizeMake(kPaperWidth * resolution, kPaperHeight * resolution);
    UIGraphicsBeginImageContext(overallSize);

    if (showLines) {
        [self drawLinesWithResolution:resolution];
    }
    
    CGFloat gutter = (kPaperHeight - kMaximumSelections * kStripHeight) / (kMaximumSelections + 1);
    for (int idx = 0; idx < images.count; idx++) {
        CGFloat yOffset = gutter * (idx + 1) + kStripHeight * idx;
        CGRect rect = CGRectMake(0, yOffset * resolution, kStripWidth * kDPI, kStripHeight * resolution);
        UIImage *panoImage = images[idx];
        [panoImage drawInRect:rect];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)drawLinesWithResolution:(CGFloat)resolution
{
    CGSize overallSize = CGSizeMake(kPaperWidth * resolution, kPaperHeight * resolution);
    CGFloat gutter = (kPaperHeight - kMaximumSelections * kStripHeight) / (kMaximumSelections + 1);

    for (int idx = 0; idx < kMaximumSelections; idx++) {
        
        CGFloat yOffset = gutter * (idx + 1) + kStripHeight * idx;
       
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 10.0);
        CGContextSetStrokeColorWithColor(context, [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3] CGColor]);
        
        CGFloat y2 = yOffset * resolution;
        CGFloat y1 = (yOffset + kStripHeight) * resolution;
        
        CGContextMoveToPoint(context, 0, y1);
        CGContextAddLineToPoint(context, overallSize.width, y1);
        CGContextStrokePath(context);

        CGContextMoveToPoint(context, 0, y2);
        CGContextAddLineToPoint(context, overallSize.width, y2);
        CGContextStrokePath(context);
    }
}

- (void)enablePrint:(BOOL)enabled
{
    [self.view layoutIfNeeded];
    
    if (enabled) {
        self.previewHeightConstraint.constant = kPreviewHeight;
        self.previewImageHeightConstraint.constant = kPreviewImageHeight;
        self.previewImageWidthConstraint.constant = kPreviewImageHeight * kPaperWidth / kPaperHeight;
    } else {
        self.previewHeightConstraint.constant = 0;
        self.previewImageHeightConstraint.constant = 0;
        self.previewImageWidthConstraint.constant = 0;
    }
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.printButton.enabled = enabled;
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Photo library

- (void)retrievePanoramas
{
    NSMutableArray *panoramas = [NSMutableArray array];
    PHFetchResult<PHAssetCollection *> * collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumPanoramas options:nil];
    [collections enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        if (collection) {
            PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            if (0 == assets.count) {
                [self showNoPhotos];
            } else {
                [assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                    [panoramas addObject:asset];
                    if (asset == [assets lastObject]) {
                        self.panoramaAssets = panoramas;
                        [self showPhotos];
                    }
                }];
            }
            
        }
    }];
}

- (void)verifyAccess
{
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (PHAuthorizationStatusAuthorized == authorizationStatus) {
        [self retrievePanoramas];
    } else if (PHAuthorizationStatusNotDetermined == authorizationStatus) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            [self verifyAccess];
        }];
    } else if (PHAuthorizationStatusDenied == authorizationStatus) {
        [self noAccessWithCaption:@"No Access" andMessage:@"Access to photos has been denied on this device."];
    } else if (PHAuthorizationStatusRestricted == authorizationStatus) {
        [self noAccessWithCaption:@"Restricted Access" andMessage:@"Access to photos is restricted by a policy on this device."];
    }
}

- (void)noAccessWithCaption:(NSString *)caption andMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:caption
                                                                   message:[NSString stringWithFormat:@"%@ The HP Pano app needs access to pano photos in order to work. Please check your settings.\n\nSettings → HP Pano → Photos", message]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self showNoAccess];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openSettings];
    }]];
    [self presentViewController:alert animated:YES completion:nil];

}

- (void)openSettings
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    });
}

- (IBAction)authorizeButtonTapped:(id)sender {
    [self openSettings];
}

- (void)showPhotos
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.noPanoLabel.hidden = YES;
        self.previewView.hidden = NO;
        self.tableView.hidden = NO;
        self.authorizeButton.hidden = YES;
        [self.tableView reloadData];
    });
}

- (void)showNoPhotos
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.noPanoLabel.hidden = NO;
        self.previewView.hidden = YES;
        self.tableView.hidden = YES;
        self.authorizeButton.hidden = YES;
    });
}

- (void)showNoAccess
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.noPanoLabel.hidden = YES;
        self.previewView.hidden = YES;
        self.tableView.hidden = YES;
        self.authorizeButton.hidden = NO;
    });
}

#pragma mark - Selection handling

- (void)addItem:(NSInteger)item
{
    NSNumber *itemToAdd = [NSNumber numberWithInteger:item];
    if (![self.selectedPanoramas containsObject:itemToAdd]) {
        [self.selectedPanoramas addObject:itemToAdd];
        if (self.selectedPanoramas.count > kMaximumSelections) {
            [self removeItem:[[self.selectedPanoramas firstObject] integerValue]];
        }
    }
    [self updatePreviewImage];
    [self enablePrint:YES];
}

- (void)removeItem:(NSInteger)item
{
    NSNumber *itemToRemove = [NSNumber numberWithInteger:item];
    [self.selectedPanoramas removeObject:itemToRemove];
    PPPanoramaTableViewCell *cell = (PPPanoramaTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[itemToRemove integerValue] inSection:0]];
    cell.included = NO;
    [self updatePreviewImage];
    if (0 == self.selectedPanoramas.count) {
        [self enablePrint:NO];
    }
}

- (void)updatePreviewImage
{
    NSMutableArray *thumbnailImages = [NSMutableArray array];
    [self retrieveImages:thumbnailImages height:kPreviewSmallStripHeight completion:^{
        UIImage *image = [self combinedImages:thumbnailImages resolution:kDPI showLines:YES];
        self.previewImageView.image = image;
    }];
}

#pragma mark - MPPrintDelegate

- (void)didFinishPrintFlow:(UIViewController *)printViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didCancelPrintFlow:(UIViewController *)printViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Gesture handling

- (void)configureGestures
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePreviewTap:)];
    tapRecognizer.cancelsTouchesInView = YES;
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.previewImageView addGestureRecognizer:tapRecognizer];
}

- (void)handlePreviewTap:(UIGestureRecognizer *)gestureRecognizer
{
    self.previewImages = [NSMutableArray array];
    [self retrieveImages:self.previewImages height:kPreviewLargeStripHeight completion:^{
        [self performSegueWithIdentifier:@"Show Preview" sender:self];
    }];
}

@end
