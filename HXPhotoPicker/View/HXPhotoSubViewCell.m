//
//  HXPhotoSubViewCell.m
//  照片选择器
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoSubViewCell.h"
#import "HXPhotoModel.h"
#import "HXCircleProgressView.h"
#import "HXPhotoTools.h"
#import "HXPhotoBottomSelectView.h"
#import "HXPhotoEdit.h"
#import "UIColor+HXExtension.h"

@interface HXPhotoSubViewCell ()
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIButton *deleteBtn;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (assign, nonatomic) int32_t requestID;
@property (strong, nonatomic) UILabel *stateLb;
@property (strong, nonatomic) CAGradientLayer *bottomMaskLayer;
@property (assign, nonatomic) BOOL addCustomViewCompletion;
@property (strong, nonatomic) UIView *customView;
@end

@implementation HXPhotoSubViewCell
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            if (self.model.type == HXPhotoModelMediaTypeCamera) {
                if ([HXPhotoCommon photoCommon].isDark) {
                    self.imageView.image = self.model.previewPhoto;
                }else {
                    self.imageView.image = self.model.thumbPhoto;
                }
            }
        }
    }
#endif
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
#pragma mark - < 懒加载 >
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [_imageView.layer addSublayer:self.bottomMaskLayer];
    }
    return _imageView;
}
- (UILabel *)stateLb {
    if (!_stateLb) {
        _stateLb = [[UILabel alloc] init];
        _stateLb.textColor = [UIColor whiteColor];
        _stateLb.textAlignment = NSTextAlignmentRight;
        _stateLb.font = [UIFont hx_mediumSFUITextOfSize:12];
    }
    return _stateLb;
}
- (CAGradientLayer *)bottomMaskLayer {
    if (!_bottomMaskLayer) {
        _bottomMaskLayer = [CAGradientLayer layer]; 
        _bottomMaskLayer.colors = @[
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor ,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.15].CGColor ,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.35].CGColor ,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor
                                    ];
        _bottomMaskLayer.startPoint = CGPointMake(0, 0);
        _bottomMaskLayer.endPoint = CGPointMake(0, 1);
        _bottomMaskLayer.locations = @[@(0.15f),@(0.35f),@(0.6f),@(0.9f)];
        _bottomMaskLayer.borderWidth  = 0.0;
    }
    return _bottomMaskLayer;
}
- (UIButton *)deleteBtn {
    if (!_deleteBtn) {
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteBtn setImage:[UIImage hx_imageNamed:@"hx_compose_delete"] forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(didDeleteClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteBtn;
}
- (HXCircleProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HXCircleProgressView alloc] init];
        _progressView.hidden = YES;
    }
    return _progressView;
}
- (void)setup {
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.stateLb];
    [self.contentView addSubview:self.deleteBtn];
    [self.contentView addSubview:self.progressView];
    [self.contentView addSubview:self.highlightMaskView];
}

- (void)didDeleteClick {
    if (self.model.networkPhotoUrl) {
        if (self.showDeleteNetworkPhotoAlert) {
            HXPhotoBottomViewModel *titleModel = [[HXPhotoBottomViewModel alloc] init];
            titleModel.title = [NSBundle hx_localizedStringForKey:@"是否删除此资源"];;
            titleModel.titleFont = [UIFont systemFontOfSize:13];
            titleModel.titleColor = [UIColor hx_colorWithHexStr:@"#666666"];
            titleModel.cellHeight = 60.f;
            titleModel.canSelect = NO;
            
            HXPhotoBottomViewModel *deleteModel = [[HXPhotoBottomViewModel alloc] init];
            deleteModel.title = [NSBundle hx_localizedStringForKey:@"删除"];
            deleteModel.titleColor = [UIColor redColor];
            HXWeakSelf
            [HXPhotoBottomSelectView showSelectViewWithModels:@[titleModel, deleteModel] selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
                if ([weakSelf.delegate respondsToSelector:@selector(cellDidDeleteClcik:)]) {
                    [weakSelf.delegate cellDidDeleteClcik:weakSelf];
                }
            } cancelClick:nil];
            return;
        }
    }
#if HasYYWebImage
//    [self.imageView yy_cancelCurrentImageRequest];
#elif HasYYKit
//    [self.imageView cancelCurrentImageRequest];
#elif HasSDWebImage
//    [self.imageView sd_cancelCurrentAnimationImagesLoad];
#endif
    if ([self.delegate respondsToSelector:@selector(cellDidDeleteClcik:)]) {
        [self.delegate cellDidDeleteClcik:self];
    }
}

- (void)againDownload {
    self.model.downloadError = NO;
    self.model.downloadComplete = NO;
    HXWeakSelf
    [self.imageView hx_setImageWithModel:self.model original:NO progress:^(CGFloat progress, HXPhotoModel *model) {
        if (weakSelf.model == model) {
            weakSelf.progressView.progress = progress;
        }
    } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
        if (weakSelf.model == model) {
            if (error != nil) {
                weakSelf.model.downloadError = YES;
                weakSelf.model.downloadComplete = YES;
                [weakSelf.progressView showError];
            }else {
                if (image) {
                    weakSelf.progressView.progress = 1;
                    weakSelf.progressView.hidden = YES;
                    weakSelf.imageView.image = image;
                    weakSelf.userInteractionEnabled = YES; 
                }
            }
        }
    }];
}
- (void)setHideDeleteButton:(BOOL)hideDeleteButton {
    _hideDeleteButton = hideDeleteButton;
    if (self.model.type != HXPhotoModelMediaTypeCamera) {
        self.deleteBtn.hidden = hideDeleteButton;
    }
}
- (void)setDeleteImageName:(NSString *)deleteImageName {
    _deleteImageName = deleteImageName;
    [self.deleteBtn setImage:[UIImage hx_imageNamed:deleteImageName] forState:UIControlStateNormal];
}
- (void)resetNetworkImage {
    if (self.model.networkPhotoUrl &&
       (self.model.type == HXPhotoModelMediaTypeCameraPhoto ||
        self.model.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork)) {
        self.model.loadOriginalImage = YES;
        self.model.previewViewSize = CGSizeZero;
        self.model.endImageSize = CGSizeZero;
        HXWeakSelf
        [self.imageView hx_setImageWithModel:self.model original:YES progress:nil completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                if (image.images.count) {
                    weakSelf.imageView.image = nil;
                    weakSelf.imageView.image = image.images.firstObject;
                }else {
                    weakSelf.imageView.image = image;
                }
            }
        }];
    }
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
    self.imageView.image = nil;
    if (model.type == HXPhotoModelMediaTypeCamera) {
        self.deleteBtn.hidden = YES;
        if ([HXPhotoCommon photoCommon].isDark) {
            self.imageView.image = model.previewPhoto;
        }else {
            self.imageView.image = model.thumbPhoto;
        }
    }else {
        if (model.localIdentifier && !model.asset) {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            model.asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[model.localIdentifier] options:options] firstObject];
        }
        self.deleteBtn.hidden = NO;
        if (model.networkPhotoUrl) {
            HXWeakSelf
            self.progressView.hidden = model.downloadComplete;
            if (model.downloadComplete && !model.downloadError) {
                if (model.previewPhoto.images.count) {
                    self.imageView.image = nil;
                    self.imageView.image = model.previewPhoto.images.firstObject;
                }else {
                    self.imageView.image = model.previewPhoto;
                }
            }else {
                [self.imageView hx_setImageWithModel:model original:NO progress:^(CGFloat progress, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        weakSelf.progressView.progress = progress;
                    }
                } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        if (error != nil) {
                            [weakSelf.progressView showError];
                        }else {
                            if (image) {
                                weakSelf.progressView.progress = 1;
                                weakSelf.progressView.hidden = YES;
                                if (image.images.count) {
                                    weakSelf.imageView.image = nil;
                                    weakSelf.imageView.image = image.images.firstObject;
                                }else {
                                    weakSelf.imageView.image = image;
                                }
                            }
                        }
                    }
                }];
            }
        }else {
            if (model.photoEdit) {
                self.imageView.image = model.photoEdit.editPreviewImage;
            }else {
                if (model.previewPhoto) {
                    if (model.previewPhoto.images.count) {
                        self.imageView.image = nil;
                        self.imageView.image = model.previewPhoto.images.firstObject;
                    }else {
                        self.imageView.image = model.previewPhoto;
                    }
                }else if (model.thumbPhoto) {
                    if (model.thumbPhoto.images.count) {
                        self.imageView.image = nil;
                        self.imageView.image = model.thumbPhoto.images.firstObject;
                    }else {
                        self.imageView.image = model.thumbPhoto;
                    }
                }else {
                    HXWeakSelf
                    [self.model requestThumbImageWithSize:CGSizeMake(200, 200) completion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                        if (weakSelf.model == model) {
                            weakSelf.imageView.image = image;
                        }
                    }];
                }
            }
        }
    }
    if (self.customProtocol) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    if (model.type == HXPhotoModelMediaTypePhotoGif && !model.photoEdit) {
        self.stateLb.text = @"GIF";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else if (model.type == HXPhotoModelMediaTypeLivePhoto && !model.photoEdit) {
        self.stateLb.text = @"Live";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else {
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.stateLb.text = model.videoTime;
            self.stateLb.hidden = NO;
            self.bottomMaskLayer.hidden = NO;
        }else {
            if ((model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif ||
                 model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalGif) && !model.photoEdit) {
                self.stateLb.text = @"GIF";
                self.stateLb.hidden = NO;
                self.bottomMaskLayer.hidden = NO;
                return;
            }else if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto && !model.photoEdit) {
                self.stateLb.text = @"Live";
                self.stateLb.hidden = NO;
                self.bottomMaskLayer.hidden = NO;
                return;
            }
            self.stateLb.hidden = YES;
            self.bottomMaskLayer.hidden = YES;
        }
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.index inSection:0];
    if ([self.customProtocol respondsToSelector:@selector(customView:indexPath:)]) {
        if (!self.addCustomViewCompletion) {
            UIView *customView = [self.customProtocol customView:self indexPath:indexPath];
            [self.contentView addSubview:customView];
            self.customView = customView;
            self.addCustomViewCompletion = YES;
        }
    }
    if ([self.customProtocol respondsToSelector:@selector(setCustomViewData:cell:model:indexPath:)]) {
        [self.customProtocol setCustomViewData:self.customView cell:self model:model indexPath:indexPath];
    }
    if ([self.customProtocol respondsToSelector:@selector(shouldHiddenBottomType:indexPath:)]) {
        BOOL hiddenState = [self.customProtocol shouldHiddenBottomType:self indexPath:indexPath];
        if (hiddenState) {
            self.stateLb.hidden = hiddenState;
            self.bottomMaskLayer.hidden = hiddenState;
        }
    }
    if ([self.customProtocol respondsToSelector:@selector(customViewFrame:indexPath:)]) {
        CGRect customViewFrame = [self.customProtocol customViewFrame:self indexPath:indexPath];
        self.customView.frame = customViewFrame;
    }
    if ([self.customProtocol respondsToSelector:@selector(customDeleteButtonFrame:indexPath:)]) {
        CGRect deleteFrame = [self.customProtocol customDeleteButtonFrame:self indexPath:indexPath];
        self.deleteBtn.frame = deleteFrame;
    }
    if (self.customProtocol) {
        [CATransaction commit];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    
    self.stateLb.frame = CGRectMake(0, self.hx_h - 18, self.hx_w - 4, 18);
    self.bottomMaskLayer.frame = CGRectMake(0, self.hx_h - 25, self.hx_w, 25);

    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    if (![self.customProtocol respondsToSelector:@selector(customDeleteButtonFrame:indexPath:)]) {
        CGFloat deleteBtnW = self.deleteBtn.currentImage.size.width;
        CGFloat deleteBtnH = self.deleteBtn.currentImage.size.height;
        self.deleteBtn.frame = CGRectMake(width - deleteBtnW, 0, deleteBtnW, deleteBtnH);
    }
    
    self.progressView.center = CGPointMake(width / 2, height / 2);
    self.highlightMaskView.frame = self.bounds;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (self.model.type == HXPhotoModelMediaTypeCamera || self.canEdit) {
        return;
    }
    self.highlightMaskView.hidden = !highlighted;
}

- (UIView *)highlightMaskView {
    if (!_highlightMaskView) {
        _highlightMaskView = [[UIView alloc] init];
        _highlightMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        _highlightMaskView.hidden = YES;
    }
    return _highlightMaskView;
}

@end
