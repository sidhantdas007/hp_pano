//
//  PanoramaTableViewCell.m
//  HPPano
//
//  Created by P&I Lab on 11/5/15.
//  Copyright © 2015 HP Inc. All rights reserved.
//

#import "PPPanoramaTableViewCell.h"

@implementation PPPanoramaTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setIncluded:(BOOL)included
{
    _included = included;
    NSString *imageName = _included ? @"MPActiveCircle" : @"MPInactiveCircle";
    self.checkmarkImageView.image = [UIImage imageNamed:imageName];
}

- (void)setAsset:(PHAsset *)asset
{
    if (nil != asset && _asset != asset) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.synchronous = NO;
        
        CGFloat desiredHeight = 50.0;
        CGFloat scale = asset.pixelHeight / desiredHeight;
        CGSize size = CGSizeMake(asset.pixelWidth / scale, desiredHeight);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                self.panoImageView.image = result;
            }];
        });
    }
    _asset = asset;
}

- (CGSize)sizeForAsset:(PHAsset *)asset inContainer:(CGRect)rect
{
    CGFloat xScale = (float)asset.pixelWidth / rect.size.width;
    CGFloat yScale = (float)asset.pixelHeight / rect.size.height;
    CGFloat scale = fminf(xScale, yScale);
    return CGSizeMake((float)asset.pixelWidth/ scale, (float)asset.pixelHeight / scale);
}

@end
