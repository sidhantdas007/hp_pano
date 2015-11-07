//
//  PPPanoramaViewController.m
//  PanoPix
//
//  Created by James Trask on 11/6/15.
//  Copyright © 2015 HP. All rights reserved.
//

#import "PPPanoramaViewController.h"
#import "PPPanoramaTableViewCell.h"
#import <Photos/Photos.h>
#import <HPPP.h>
#import <HPPPLayout.h>
#import <HPPPPrintItemFactory.h>
#import <HPPPLayoutFactory.h>
#import <HPPPPaper.h>

@interface PPPanoramaViewController () <HPPPPrintDelegate>

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

@end

@implementation PPPanoramaViewController

NSString * const kPanoramaCellIdentifier = @"Pano Scroll Cell";
CGFloat kHeaderHeight = 30.0;
CGFloat kPreviewHeight = 140.0;
CGFloat kPreviewImageHeight = 120.0;
NSInteger kMaximumSelections = 3;
CGFloat kDPI = 300.0;
CGFloat kPaperWidth = 7.0; // inches
CGFloat kPaperHeight = 5.0; // inches
CGFloat kStripWidth = 7.0; // inches
CGFloat kStripHeight = 1.375; // inches
CGFloat kAnimationDuration = 0.61803399; //seconds

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureHPPP];
    [self preparePrintIcon];
    [self configureGestures];
    self.panoramaAssets = @[];
    self.selectedPanoramas = [NSMutableArray array];
    [self retrievePanoramas];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureHPPP
{
    HPPPPaper *paper = [[HPPPPaper alloc] initWithPaperSize:HPPPPaperSize5x7 paperType:HPPPPaperTypePhoto];
    [HPPP sharedInstance].defaultPaper = paper;
    [HPPP sharedInstance].supportedPapers = @[ paper ];
    [HPPP sharedInstance].hidePaperSizeOption = YES;
    [HPPP sharedInstance].hidePaperTypeOption = YES;
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
- (void)retrieveImages:(NSMutableArray *)images resolution:(CGFloat)resolution Completion:(void(^)(void))completion
{
    if (0 == self.selectedPanoramas.count) {
        if (completion) {
            completion();
        }
        return;
    }
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.synchronous = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize size = CGSizeMake(kStripWidth * resolution, kStripHeight * resolution);
        NSInteger item = [self.selectedPanoramas[images.count] integerValue];
        [[PHImageManager defaultManager] requestImageForAsset:self.panoramaAssets[item] targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
                [images addObject:result];
                if (images.count < self.selectedPanoramas.count) {
                    [self retrieveImages:images resolution:resolution Completion:completion];
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
    HPPPPrintItem *printItem = [HPPPPrintItemFactory printItemWithAsset:image];
    printItem.layout = [HPPPLayoutFactory layoutWithType:[HPPPLayoutFit layoutType] orientation:HPPPLayoutOrientationLandscape assetPosition:[HPPPLayout completeFillRectangle]];
    UIViewController *vc = [[HPPP sharedInstance] printViewControllerWithDelegate:self dataSource:nil printItem:printItem fromQueue:NO settingsOnly:NO];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)initiatePrint
{
    self.printableImages = [NSMutableArray array];
    [self retrieveImages:self.printableImages resolution:kDPI Completion:^{
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
            [assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                [panoramas addObject:asset];
                if (asset == [assets lastObject]) {
                    self.panoramaAssets = panoramas;
                    [self.tableView reloadData];
                }
            }];
        }
    }];
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
    [self retrieveImages:thumbnailImages resolution:kDPI Completion:^{
        UIImage *image = [self combinedImages:thumbnailImages resolution:kDPI showLines:YES];
        self.previewImageView.image = image;
    }];
}

#pragma mark - HPPPPrintDelegate

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
    [self initiatePrint];
}

@end
