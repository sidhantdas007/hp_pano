//
//  PanoramaTableViewCell.m
//  PanoPix
//
//  Created by James Trask on 11/5/15.
//  Copyright © 2015 HP. All rights reserved.
//

#import "PPPanoramaTableViewCell.h"

@implementation PPPanoramaTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setIncluded:(BOOL)included
{
    _included = included;
    NSString *imageName = _included ? @"ActiveCircle" : @"InactiveCircle";
    self.checkmarkImageView.image = [UIImage imageNamed:imageName];
}

- (void)setAsset:(PHAsset *)asset
{
    if (nil != asset && _asset != asset) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        options.synchronous = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:self.panoramaImageView.frame.size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                self.panoramaImageView.image = result;
            }];
        });
    }
    _asset = asset;
}

@end
