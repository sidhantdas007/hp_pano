//
//  PanoramaTableViewCell.m
//  HPPano
//
//  Created by P&I Lab on 11/5/15.
//  Copyright © 2015 HP Inc. All rights reserved.
//

#import "PPPanoramaTableViewCell.h"

@interface PPPanoramaTableViewCell()

@property (weak, nonatomic) IBOutlet UIView *selectedView;

@end

@implementation PPPanoramaTableViewCell

CGFloat const kPPThumbnailHeight = 50.0;
CGFloat const kPPDeselectedAlpha = 0.5;
CGFloat const kPPFadeDuration = 0.2;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setIncluded:(BOOL)included
{
    if (_included != included) {
        _included = included;
        CGFloat selectedAlpha = included ? 1.0 : 0.0;
        CGFloat imageAlpha = included ? 1.0 : kPPDeselectedAlpha;
        [UIView animateWithDuration:kPPFadeDuration animations:^{
            self.selectedView.alpha = selectedAlpha;
            self.panoImageView.alpha = imageAlpha;
        }];
    }
}

- (void)setAsset:(PHAsset *)asset
{
    if (nil != asset && _asset != asset) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.synchronous = NO;
        
        CGFloat scale = asset.pixelHeight / kPPThumbnailHeight;
        CGSize size = CGSizeMake(asset.pixelWidth / scale, kPPThumbnailHeight);
        
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
