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
@property (strong, nonatomic) NSArray *panoramaAssets;
@property (strong, nonatomic) NSMutableArray *selectedPanoramas;
@property (strong, nonatomic) NSMutableArray *printableImages;

@end

@implementation PPPanoramaViewController

NSString * const kPanoramaCellIdentifier = @"Panorama Cell";
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
    self.panoramaAssets = @[];
    self.selectedPanoramas = [NSMutableArray array];
    [self preparePrintIcon];
    [self retrievePanoramas];
    [self configureHPPP];
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
        [self selectItem:indexPath.row];
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
    self.printableImages = [NSMutableArray array];
    [self retrivePrintableImage:0];
}

- (void)retrivePrintableImage:(NSInteger)index
{
    NSInteger row = [self.selectedPanoramas[index] integerValue];
    PPPanoramaTableViewCell *cell = (PPPanoramaTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.synchronous = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize size = CGSizeMake(kStripWidth * kDPI, kStripHeight * kDPI);
        [[PHImageManager defaultManager] requestImageForAsset:cell.asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
                [self.printableImages addObject:result];
                if (index < self.selectedPanoramas.count - 1) {
                    [self retrivePrintableImage:index + 1];
                } else {
                    [self initiatePrint];
                }
            } else {
                NSLog(@"IMAGE FAIL:\n\n%ld\n\n%@\n\n%@", (long)index, cell.asset, info);
            }
        }];
    });
}

- (void)initiatePrint
{
    HPPPPrintItem *printItem = [HPPPPrintItemFactory printItemWithAsset:[self combinedImage]];
    printItem.layout = [HPPPLayoutFactory layoutWithType:[HPPPLayoutFit layoutType] orientation:HPPPLayoutOrientationLandscape assetPosition:[HPPPLayout completeFillRectangle]];
    UIViewController *vc = [[HPPP sharedInstance] printViewControllerWithDelegate:self dataSource:nil printItem:printItem fromQueue:NO settingsOnly:NO];
    [self presentViewController:vc animated:YES completion:nil];
}

- (UIImage *)combinedImage
{
    CGSize overallSize = CGSizeMake(kPaperWidth * kDPI, kPaperHeight * kDPI);
    UIGraphicsBeginImageContext(overallSize);
    
    CGFloat gutter = (kPaperHeight - kMaximumSelections * kStripHeight) / (kMaximumSelections + 1);
    for (int idx = 0; idx < self.printableImages.count; idx++) {
        CGFloat yOffset = gutter * (idx + 1) + kStripHeight * idx;
        CGRect rect = CGRectMake(0, yOffset * kDPI, kStripWidth * kDPI, kStripHeight * kDPI);
        UIImage *panoImage = self.printableImages[idx];
        [panoImage drawInRect:rect];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
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

- (void)selectItem:(NSInteger)item
{
    [self enablePrint:YES];
    NSNumber *itemToAdd = [NSNumber numberWithInteger:item];
    if (![self.selectedPanoramas containsObject:itemToAdd]) {
        [self.selectedPanoramas addObject:itemToAdd];
        if (self.selectedPanoramas.count > kMaximumSelections) {
            [self removeItem:[[self.selectedPanoramas firstObject] integerValue]];
        }
    }
    
}

- (void)removeItem:(NSInteger)item
{
    NSNumber *itemToRemove = [NSNumber numberWithInteger:item];
    [self.selectedPanoramas removeObject:itemToRemove];
    PPPanoramaTableViewCell *cell = (PPPanoramaTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[itemToRemove integerValue] inSection:0]];
    cell.included = NO;
    if (0 == self.selectedPanoramas.count) {
        [self enablePrint:NO];
    }
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

@end
