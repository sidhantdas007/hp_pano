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
#import "PPPaperView.h"
#import <Photos/Photos.h>
#import <MP.h>
#import <MPLayout.h>
#import <MPPrintItemFactory.h>
#import <MPLayoutFactory.h>
#import <MPPaper.h>

@interface PPPanoramaViewController () <MPPrintDelegate, PHPhotoLibraryChangeObserver>

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIBarButtonItem *printButton;
@property (strong, nonatomic) NSArray<PHAsset *> *panoramaAssets;
@property (strong, nonatomic) NSMutableArray<NSNumber *> *selectedPanoramas; // table row number of selected items
@property (strong, nonatomic) NSMutableArray<UIImage *> *printableImages;
@property (strong, nonatomic) NSMutableArray<UIImage *> *previewImages;
@property (weak, nonatomic) IBOutlet UIButton *authorizeButton;
@property (weak, nonatomic) IBOutlet UILabel *noPanoLabel;
@property (strong, nonatomic) UIImageView *selectionView;
@property (weak, nonatomic) IBOutlet PPPaperView *paperView;
@property (weak, nonatomic) IBOutlet UIImageView *magnifierImageView;

@end

@implementation PPPanoramaViewController

NSString * const kPanoramaCellIdentifier = @"Pano Cell";
CGFloat kHeaderHeight = 30.0;
CGFloat kPreviewSmallStripHeight = 200.0;
CGFloat kPreviewLargeStripHeight = 200.0;
CGFloat kMaximumStripHeight = MAXFLOAT;
NSInteger kMaximumSelections = 3;
CGFloat kAnimationDuration = 0.61803399; //seconds

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureMP];
    [self preparePrintIcon];
    [self configureGestures];
    self.panoramaAssets = @[];
    self.selectedPanoramas = [NSMutableArray array];
    [self updatePreviewImageWithCompletion:nil];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self verifyAccess];
}

- (void)viewDidLayoutSubviews
{
    [self.paperView drawPerforations:kMaximumSelections stripPercent:kPPStripHeight / kPPPaperHeight];
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
    [self selectedRow:indexPath.row];
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
    
    self.printButton.enabled = NO;
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
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
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
    PPPaperView *printPaper = [[PPPaperView alloc] init];
    printPaper.sourceImages = self.printableImages;
    MPPrintItem *printItem = [MPPrintItemFactory printItemWithAsset:printPaper.combinedImage];
    printItem.layout = [MPLayoutFactory layoutWithType:[MPLayoutFit layoutType] orientation:MPLayoutOrientationLandscape assetPosition:[MPLayout completeFillRectangle]];
    UIViewController *vc = [[MP sharedInstance] printViewControllerWithDelegate:self dataSource:nil printItem:printItem fromQueue:NO settingsOnly:NO];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)initiatePrint
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Preparing to print..." preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:^{
            self.printableImages = [NSMutableArray array];
            [self retrieveImages:self.printableImages height:kMaximumStripHeight completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert dismissViewControllerAnimated:YES completion:^{
                        [self presentPrintController];
                    }];
                });
            }];
        }];
    });
}

- (CGFloat)gutterInches
{
    return (kPPPaperHeight - kMaximumSelections * kPPStripHeight) / (kMaximumSelections + 1);
}

- (CGFloat)offsetInches:(NSUInteger)position
{
    return [self gutterInches] * position + kPPStripHeight * (position - 1);
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
                        NSMutableArray *descending = [NSMutableArray arrayWithCapacity:panoramas.count];
                        for (id obj in [panoramas reverseObjectEnumerator]) {
                            [descending addObject:obj];
                        }
                        self.panoramaAssets = descending;
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

- (void)selectedRow:(NSInteger)row
{
    self.tableView.userInteractionEnabled = NO;
    if (self.selectedPanoramas.count >= kMaximumSelections) {
        [self removeRow:[[self.selectedPanoramas firstObject] integerValue] completion:^{
            [self addRow:row];
        }];
    } else {
        [self addRow:row];
    }
}

- (void)addRow:(NSInteger)row
{
    PPPanoramaTableViewCell *cell = (PPPanoramaTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    cell.included = YES;
    NSNumber *rowToAdd = [NSNumber numberWithInteger:row];
    [self.selectedPanoramas addObject:rowToAdd];
    [self animateSelection:cell];
}

- (void)removeRow:(NSInteger)row completion:(void(^)(void))completion
{
    NSNumber *rowRemoved = [NSNumber numberWithInteger:row];
    [self.selectedPanoramas removeObjectAtIndex:0];
    if (![self.selectedPanoramas containsObject:rowRemoved]) {
        PPPanoramaTableViewCell *cell = (PPPanoramaTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        cell.included = NO;
    }
    [self updatePreviewImageWithCompletion:^{
        if (completion) {
            completion();
        }
    }];
}


- (void)animateSelection:(PPPanoramaTableViewCell *)cell
{
    [self animateSelectedCell:cell completion:^{
        [self updatePreviewImageWithCompletion:^{
            [self.selectionView removeFromSuperview];
            self.selectionView = nil;
            self.tableView.userInteractionEnabled = YES;
            self.printButton.enabled = YES;
            self.magnifierImageView.hidden = NO;
        }];
    }];
}

- (void)updatePreviewImageWithCompletion:(void(^)(void))completion
{
    NSMutableArray *thumbnailImages = [NSMutableArray array];
    [self retrieveImages:thumbnailImages height:kPreviewSmallStripHeight completion:^{
        self.paperView.sourceImages = thumbnailImages;
        if (completion) {
            completion();
        }
    }];
}

- (void)animateSelectedCell:(PPPanoramaTableViewCell *)cell completion:(void(^)(void))completion
{
    CGRect sourceFrame = [cell.panoImageView convertRect:cell.panoImageView.bounds toView:self.view];
    self.selectionView = [[UIImageView alloc] initWithFrame:sourceFrame];
    self.selectionView.clipsToBounds = YES;
    self.selectionView.contentMode = UIViewContentModeScaleAspectFill;
    self.selectionView.image = cell.panoImageView.image;
    [self.view addSubview:self.selectionView];
    
    CGRect destinationFrame = [self.paperView convertRect:self.paperView.bounds toView:self.view];
    CGFloat offsetY = [self offsetInches:self.selectedPanoramas.count];
    destinationFrame.origin.y += destinationFrame.size.height * (offsetY / kPPPaperHeight);
    destinationFrame.size.height *= kPPStripHeight / kPPPaperHeight;
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.selectionView.frame = destinationFrame;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
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
    [self.paperView addGestureRecognizer:tapRecognizer];
}

- (void)handlePreviewTap:(UIGestureRecognizer *)gestureRecognizer
{
    self.previewImages = [NSMutableArray array];
    [self retrieveImages:self.previewImages height:kPreviewLargeStripHeight completion:^{
        if (self.previewImages.count > 0) {
            [self performSegueWithIdentifier:@"Show Preview" sender:self];
        } else {
            [self showTip];
        }
    }];
}

- (void)showTip
{
    self.tableView.userInteractionEnabled = NO;
    CGFloat step = 0.1;
    CGFloat duration = 0.2;
    for (int idx = 0; idx < [self.tableView visibleCells].count ; idx++) {
        PPPanoramaTableViewCell *cell = [self.tableView visibleCells][idx];
        CGFloat start = idx * step;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(start * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            cell.included = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                cell.included = NO;
                if (idx == [self.tableView visibleCells].count - 1) {
                    self.tableView.userInteractionEnabled = YES;
                }
            });
        });
    }
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    [self retrievePanoramas];
}

@end
