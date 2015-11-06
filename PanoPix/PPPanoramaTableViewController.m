//
//  PPPanoramaTableViewController.m
//  PanoPix
//
//  Created by James Trask on 11/5/15.
//  Copyright © 2015 HP. All rights reserved.
//


#import "PPPanoramaTableViewController.h"
#import "PPPanoramaTableViewCell.h"
#import <Photos/Photos.h>

@interface PPPanoramaTableViewController ()

@property (strong, nonatomic) IBOutlet UIBarButtonItem *printButton;
@property (strong, nonatomic) NSArray *panoramaAssets;
@property (strong, nonatomic) NSMutableArray *selectedPanoramas;
@property (strong, nonatomic) NSMutableArray *printableImages;

@end

@implementation PPPanoramaTableViewController

NSString * const kPanoramaCellIdentifier = @"Panorama Cell";
CGFloat kHeaderHeight = 30.0;
NSInteger kMaximumSelections = 3;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.panoramaAssets = @[];
    self.selectedPanoramas = [NSMutableArray array];
    [self preparePrintIcon];
    [self retrievePanoramas];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    cell.included = NO;
    cell.asset = self.panoramaAssets[indexPath.row];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.synchronous = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PHImageManager defaultManager] requestImageForAsset:cell.asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            [self.printableImages addObject:result];
            if (index < self.selectedPanoramas.count - 1) {
                [self retrivePrintableImage:index + 1];
            } else {
                // DONE!!
                NSLog(@"%@", self.printableImages);
            }
        }];
    });
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
    self.printButton.enabled = YES;
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
        self.printButton.enabled = NO;
    }
}

@end
