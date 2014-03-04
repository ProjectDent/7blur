//
// Copyright (c) 2013 Justin M Fischer
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  UBLRView.m
//  7blur
//
//  Created by JUSTIN M FISCHER on 9/02/13.
//  Copyright (c) 2013 Justin M Fischer. All rights reserved.
//

#import "BLRView.h"
#import "UIImage+ImageEffects.h"

@interface BLRView ()

@property(nonatomic, assign) BlurType blurType;
@property(nonatomic, strong) BLRColorComponents *colorComponents;
@property(nonatomic, strong) IBOutlet UIImageView *backgroundImageView;
@property(nonatomic, strong) dispatch_source_t timer;

@end

@implementation BLRView

-(id)init {
    self = [super init];
    if (self) {
        [self initialSetupBLRView];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialSetupBLRView];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialSetupBLRView];
    }
    return self;
}

-(void)initialSetupBLRView {
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.frame = self.bounds;
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.backgroundImageView];
    
    self.userInteractionEnabled = NO;
}

- (void) blurBackground {
    UIGraphicsBeginImageContextWithOptions(self.targetView.frame.size, NO, 1);
    
    //Snapshot finished in 0.051982 seconds.
    self.alpha = 0;
    [self.targetView drawViewHierarchyInRect:self.targetView.frame afterScreenUpdates:NO];

    __block UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    self.alpha = 1;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //Blur finished in 0.004884 seconds.
        CGRect bounds = CGRectMake(0, 0, snapshot.size.width, snapshot.size.height);
        
        snapshot = [snapshot applyBlurWithCrop:bounds resize:bounds.size blurRadius:self.colorComponents.radius tintColor:self.colorComponents.tintColor saturationDeltaFactor:self.colorComponents.saturationDeltaFactor maskImage:self.colorComponents.maskImage];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.backgroundImageView.image = snapshot;
        });
    });
}

-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    self.backgroundImageView.frame = self.bounds;
}

- (void) blurWithColor:(BLRColorComponents *) components {
    if(self.blurType == KBlurUndefined) {
        
        self.blurType = KStaticBlur;
        self.colorComponents = components;
    }
    
    [self blurBackground];
}

- (void) blurWithColor:(BLRColorComponents *) components updateInterval:(float) interval {
    self.blurType = KLiveBlur;
    self.colorComponents = components;
    
    self.timer = CreateDispatchTimer(interval * NSEC_PER_SEC, 1ull * NSEC_PER_SEC, dispatch_get_main_queue(), ^{[self blurWithColor:components];});
}

dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block) {
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        
        dispatch_resume(timer);
    }
    
    return timer;
}

-(void)setTargetView:(UIView *)targetView {
    _targetView = targetView;
    
    [targetView.superview addSubview:self];
}

@end

@interface BLRColorComponents()
@end

@implementation BLRColorComponents

+ (BLRColorComponents *) lightEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 6;
    components.tintColor = [UIColor colorWithWhite:.8f alpha:.2f];
    components.saturationDeltaFactor = 1.8f;
    components.maskImage = nil;
    
    return components;
}

+ (BLRColorComponents *) darkEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 8;
    components.tintColor = [UIColor colorWithRed:0.0f green:0.0 blue:0.0f alpha:.5f];
    components.saturationDeltaFactor = 3.0f;
    components.maskImage = nil;
    
    return components;
}

+ (BLRColorComponents *) coralEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 8;
    components.tintColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:.1f];
    components.saturationDeltaFactor = 3.0f;
    components.maskImage = nil;
    
    return components;
}

+ (BLRColorComponents *) neonEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 8;
    components.tintColor = [UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:.1f];
    components.saturationDeltaFactor = 3.0f;
    components.maskImage = nil;
    
    return components;
}

+ (BLRColorComponents *) skyEffect {
    BLRColorComponents *components = [[BLRColorComponents alloc] init];
    
    components.radius = 8;
    components.tintColor = [UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:.1f];
    components.saturationDeltaFactor = 3.0f;
    components.maskImage = nil;
    
    return components;
}

// ...

@end
