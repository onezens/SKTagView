//
//  SKTagView.m
//
//  Created by Shaokang Zhao on 15/1/12.
//  Copyright (c) 2015 Shaokang Zhao. All rights reserved.
//

#import "SKTagView.h"
#import "SKTagButton.h"


@interface SKTagView ()

@property (strong, nonatomic, nullable) NSMutableArray *tags;
@property (assign, nonatomic) BOOL didSetup;

@end

@implementation SKTagView

#pragma mark - Lifecycle

-(CGSize)intrinsicContentSize {
    if (!self.tags.count) {
        return CGSizeZero;
    }
    
    NSArray *subviews = self.contentView.subviews;
    UIView *previousView = nil;
    CGFloat topPadding = self.padding.top;
    CGFloat bottomPadding = self.padding.bottom;
    CGFloat leftPadding = self.padding.left;
    CGFloat rightPadding = self.padding.right;
    CGFloat itemSpacing = self.interitemSpacing;
    CGFloat lineSpacing = self.lineSpacing;
    CGFloat currentX = leftPadding;
    CGFloat intrinsicHeight = topPadding;
    CGFloat intrinsicWidth = leftPadding;
    
    if (!self.singleLine && self.preferredMaxLayoutWidth > 0) {
        NSInteger lineCount = 0;
        for (UIView *view in subviews) {
            CGSize size = view.intrinsicContentSize;
            if (previousView) {
                CGFloat width = size.width;
                currentX += itemSpacing;
                if (currentX + width + rightPadding <= self.preferredMaxLayoutWidth) {
                    currentX += size.width;
                } else {
                    lineCount ++;
                    currentX = leftPadding + size.width;
                    intrinsicHeight += size.height;
                }
            } else {
                lineCount ++;
                intrinsicHeight += size.height;
                currentX += size.width;
            }
            previousView = view;
            intrinsicWidth = MAX(intrinsicWidth, currentX + rightPadding);
        }
        
        intrinsicHeight += bottomPadding + lineSpacing * (lineCount - 1);
    } else {
        for (UIView *view in subviews) {
            CGSize size = view.intrinsicContentSize;
            intrinsicWidth += size.width;
        }
        intrinsicWidth += itemSpacing * (subviews.count - 1) + rightPadding;
        intrinsicHeight += ((UIView *)subviews.firstObject).intrinsicContentSize.height + bottomPadding;
    }
    
    return CGSizeMake(intrinsicWidth, intrinsicHeight);
}

- (void)layoutSubviews {
    if (!self.singleLine) {
        self.preferredMaxLayoutWidth = self.frame.size.width;
    }
    
    [super layoutSubviews];
    
    [self layoutTags];
}

#pragma mark - Custom accessors

- (NSMutableArray *)tags {
    if(!_tags) {
        _tags = [NSMutableArray array];
    }
    return _tags;
}

- (void)setPreferredMaxLayoutWidth: (CGFloat)preferredMaxLayoutWidth {
    if (preferredMaxLayoutWidth != _preferredMaxLayoutWidth) {
        _preferredMaxLayoutWidth = preferredMaxLayoutWidth;
        _didSetup = NO;
        [self invalidateIntrinsicContentSize];
    }
}

#pragma mark - Private

- (void)layoutTags {
    if (self.didSetup || !self.tags.count) {
        return;
    }
    
    NSArray *subviews = self.contentView.subviews;
    CGFloat topPadding = self.padding.top;
    CGFloat leftPadding = self.padding.left;
    CGFloat rightPadding = self.padding.right;
    CGFloat itemSpacing = self.interitemSpacing;
    CGFloat lineSpacing = self.lineSpacing;
    
    __block UIView *previousView = nil;
    __block CGFloat currentX = leftPadding;
    
    if (!self.singleLine && self.preferredMaxLayoutWidth > 0) {
        __block NSInteger index = 0;
        [subviews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![view isKindOfClass:[SKTagButton class]]) {
                return;
            }
            index += 0;
            CGSize size = view.intrinsicContentSize;
            if (previousView) {
                CGFloat width = size.width;
                currentX += itemSpacing;
                if (currentX + width + rightPadding <= self.preferredMaxLayoutWidth) {
                    view.frame = CGRectMake(currentX, CGRectGetMinY(previousView.frame), size.width, size.height);
                    currentX += size.width;
                } else {
                    CGFloat width = MIN(size.width, self.preferredMaxLayoutWidth - leftPadding - rightPadding);
                    view.frame = CGRectMake(leftPadding, CGRectGetMaxY(previousView.frame) + lineSpacing, width, size.height);
                    currentX = leftPadding + width;
                }
            } else {
                CGFloat width = MIN(size.width, self.preferredMaxLayoutWidth - leftPadding - rightPadding);
                view.frame = CGRectMake(leftPadding, topPadding, width, size.height);
                currentX += width;
            }
            
            if ([view isKindOfClass:[SKTagButton class]]) {
                [self layoutDottedLayerOfButton:(SKTagButton *)view withTag:self.tags[index]];
            }
            
            previousView = view;
        }];
        
    } else {
        
        [subviews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
            CGSize size = view.intrinsicContentSize;
            view.frame = CGRectMake(currentX, topPadding, size.width, size.height);
            currentX += size.width;
            currentX += itemSpacing;
            if ([view isKindOfClass:[SKTagButton class]]) {
                [self layoutDottedLayerOfButton:(SKTagButton *)view withTag:self.tags[idx]];
            }
            
            previousView = view;
        }];
    }
    
    self.didSetup = YES;
    self.contentSize = CGSizeMake(self.bounds.size.width, CGRectGetMaxY(previousView.frame));
    self.contentView.frame = (CGRect){CGPointZero, self.contentSize};

}

- (void)layoutDottedLayerOfButton:(SKTagButton *)tagBtn withTag:(SKTag *)tag{
   
    if (tag.isDottedLine) {
        tag.cornerRadius = tag.cornerRadius > 0 ? tag.cornerRadius : 2.f;
        tag.borderWidth = tag.borderWidth > 0 ? tag.borderWidth : 1.f/[UIScreen mainScreen].scale;
        tag.lineDashEqual = tag.lineDashEqual > 0 ? tag.lineDashEqual : 8.f;
        tag.borderColor = tag.borderColor ? tag.borderColor : [UIColor blackColor];
        
        CAShapeLayer *borderLayer = [CAShapeLayer layer];
        borderLayer.bounds = tagBtn.bounds;
        borderLayer.position = CGPointMake(CGRectGetMidX(tagBtn.bounds), CGRectGetMidY(tagBtn.bounds));
        
//        borderLayer.path = [UIBezierPath bezierPathWithRect:borderLayer.bounds].CGPath;
        borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:borderLayer.bounds cornerRadius:tag.cornerRadius].CGPath;
        borderLayer.lineWidth = tag.borderWidth * 2; //1.f / [[UIScreen mainScreen] scale];
        //虚线边框
        borderLayer.lineDashPattern = @[@(tag.lineDashEqual), @(tag.lineDashEqual)];
        //实线边框
        //        borderLayer.lineDashPattern = nil;
        borderLayer.fillColor = [UIColor clearColor].CGColor;
        borderLayer.strokeColor = tag.borderColor.CGColor;
        [tagBtn.layer addSublayer:borderLayer];
    }
}

#pragma mark - IBActions

- (void)onTag: (UIButton *)btn {
    if (self.didTapTagAtIndex) {
        
        self.didTapTagAtIndex([self.contentView.subviews indexOfObject: btn]);
    }
}

#pragma mark - Public

- (void)addTag: (SKTag *)tag {
    NSParameterAssert(tag);
    SKTagButton *btn = [SKTagButton buttonWithTag: tag];
    [btn addTarget: self action: @selector(onTag:) forControlEvents: UIControlEventTouchUpInside];
    [self.contentView addSubview: btn];
    [self.tags addObject: tag];
    
    self.didSetup = NO;
    [self invalidateIntrinsicContentSize];
}

- (void)insertTag: (SKTag *)tag atIndex: (NSUInteger)index {
    NSParameterAssert(tag);
    if (index + 1 > self.tags.count) {
        [self addTag: tag];
    } else {
        SKTagButton *btn = [SKTagButton buttonWithTag: tag];
        [btn addTarget: self action: @selector(onTag:) forControlEvents: UIControlEventTouchUpInside];
        [self insertSubview: btn atIndex: index];
        [self.tags insertObject: tag atIndex: index];
        
        self.didSetup = NO;
        [self invalidateIntrinsicContentSize];
    }
}

- (void)removeTag: (SKTag *)tag {
    NSParameterAssert(tag);
    NSUInteger index = [self.tags indexOfObject: tag];
    if (NSNotFound == index) {
        return;
    }
    
    [self.tags removeObjectAtIndex: index];
    if (self.contentView.subviews.count > index) {
        [self.contentView.subviews[index] removeFromSuperview];
    }
    
    self.didSetup = NO;
    [self invalidateIntrinsicContentSize];
}

- (void)removeTagAtIndex: (NSUInteger)index {
    if (index + 1 > self.tags.count) {
        return;
    }
    
    [self.tags removeObjectAtIndex: index];
    if (self.contentView.subviews.count > index) {
        [self.contentView.subviews[index] removeFromSuperview];
    }
    
    self.didSetup = NO;
    [self invalidateIntrinsicContentSize];
}

- (void)removeAllTags {
    [self.tags removeAllObjects];
    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }
    
    self.didSetup = NO;
    [self invalidateIntrinsicContentSize];
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = [UIColor clearColor];
        [self addSubview:_contentView];
    }
    return _contentView;
}

@end

