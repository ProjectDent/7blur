/*
 File: UIImage+ImageEffects.m
 Abstract: This is a category of UIImage that adds methods to apply blur and tint effects to an image. This is the code you’ll want to look out to find out how to use vImage to efficiently calculate a blur.
 Version: 1.0
 
 Version: 1.1
 Created by JUSTIN M FISCHER on 9/02/13.
 Copyright (c) 2013 Justin M Fischer. All rights reserved.
 
 Abstract: This category crops and scales image efficiently using vImage prior to applying blur.
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 Copyright © 2013 Apple Inc. All rights reserved.
 WWDC 2013 License
 
 NOTE: This Apple Software was supplied by Apple as part of a WWDC 2013
 Session. Please refer to the applicable WWDC 2013 Session for further
 information.
 
 IMPORTANT: This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and
 your use, installation, modification or redistribution of this Apple
 software constitutes acceptance of these terms. If you do not agree with
 these terms, please do not use, install, modify or redistribute this
 Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple
 Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple. Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis. APPLE MAKES
 NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
 IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 EA1002
 5/3/2013
 
 JMF
 9/2/2013
 */

#import "UIImage+ImageEffects.h"
#import <Accelerate/Accelerate.h>

@implementation UIImage (ImageEffects)

- (UIImage *)applyBlurWithBlurRadius:(CGFloat) blurRadius tintColor:(UIColor *) tintColor saturationDeltaFactor:(CGFloat) saturationDeltaFactor blurredEdges:(BOOL)blurredEdges {
    return [self applyBlurWithBlurRadius:blurRadius tintColor:tintColor saturationDeltaFactor:saturationDeltaFactor blurredEdges:blurredEdges maskImage:nil];
}

- (UIImage *)applyBlurWithBlurRadius:(CGFloat) blurRadius tintColor:(UIColor *) tintColor saturationDeltaFactor:(CGFloat) saturationDeltaFactor blurredEdges:(BOOL)blurredEdges maskImage:(UIImage *) maskImage {
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    return [self applyBlurWithCrop:rect resize:rect.size blurRadius:blurRadius tintColor:tintColor saturationDeltaFactor:saturationDeltaFactor blurredEdges:blurredEdges maskImage:maskImage];
}

- (UIImage *)applyBlurWithCrop:(CGRect) bounds resize:(CGSize) size blurRadius:(CGFloat) blurRadius tintColor:(UIColor *) tintColor saturationDeltaFactor:(CGFloat) saturationDeltaFactor blurredEdges:(BOOL)blurredEdges maskImage:(UIImage *) maskImage {
    
    if (self.size.width < 1 || self.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return nil;
    }
    
    if (!self.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    
    if (maskImage && !maskImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }
    
    //Crop
    UIImage *outputImage = nil;
    if (bounds.origin.x != 0 || bounds.origin.y != 0 || bounds.size.width != self.size.width || bounds.size.height != self.size.height) {
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], bounds);
        outputImage = [UIImage imageWithCGImage:imageRef];
        
        CGImageRelease(imageRef);
    }
    else {
        outputImage = self;
    }
    
    //Re-Size
    
    if (size.width != self.size.width && size.height != self.size.height) {
        
        CGImageRef sourceRef = [outputImage CGImage];
        NSUInteger sourceWidth = CGImageGetWidth(sourceRef);
        NSUInteger sourceHeight = CGImageGetHeight(sourceRef);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        unsigned char *sourceData = (unsigned char*) calloc(sourceHeight * sourceWidth * 4, sizeof(unsigned char));
        
        NSUInteger bytesPerPixel = 4;
        NSUInteger sourceBytesPerRow = bytesPerPixel * sourceWidth;
        NSUInteger bitsPerComponent = 8;
        
        CGContextRef context = CGBitmapContextCreate(sourceData, sourceWidth, sourceHeight, bitsPerComponent, sourceBytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
        
        CGContextDrawImage(context, CGRectMake(0, 0, sourceWidth, sourceHeight), sourceRef);
        CGContextRelease(context);
        
        NSUInteger destBytesPerRow = bytesPerPixel * size.width;
        
        unsigned char *destData = (unsigned char*) calloc(size.height * size.width * 4, sizeof(unsigned char));
        
        vImage_Buffer src = {
            .data = sourceData,
            .height = sourceHeight,
            .width = sourceWidth,
            .rowBytes = sourceBytesPerRow
        };
        
        vImage_Buffer dest = {
            .data = destData,
            .height = size.height,
            .width = size.width,
            .rowBytes = destBytesPerRow
        };
        
        vImageScale_ARGB8888 (&src, &dest, NULL, kvImageNoInterpolation);
        
        free(sourceData);
        
        CGContextRef destContext = CGBitmapContextCreate(destData, size.width, size.height, bitsPerComponent, destBytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
        
        CGImageRef destRef = CGBitmapContextCreateImage(destContext);
        
        outputImage = [UIImage imageWithCGImage:destRef];
        
        CGImageRelease(destRef);
        
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(destContext);
        
        free(destData);
    }
    
    CGRect originalImageRect = { CGPointZero, outputImage.size };
    
    if (tintColor && tintColor != [UIColor clearColor]) {
        UIGraphicsBeginImageContextWithOptions(outputImage.size, NO, 0.f);
        [tintColor set];
        UIRectFill(CGRectMake(0, 0, outputImage.size.width, outputImage.size.height));
        outputImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil);
    
    CGRect imageRect;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    BOOL opaque = YES;
    
    if (hasBlur && blurredEdges) {
        opaque = NO;
        CGSize size = outputImage.size;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width + (blurRadius * 8), size.height + (blurRadius * 8)), NO, 0);
        [outputImage drawInRect:CGRectMake(blurRadius * 4, blurRadius * 4, size.width, size.height)];
        outputImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        imageRect = CGRectMake(0, 0, outputImage.size.width, outputImage.size.height);
    } else {
        imageRect = originalImageRect;
    }
    
    //Blur
    
    if (hasBlur || hasSaturationChange) {
        
        UIGraphicsBeginImageContextWithOptions(outputImage.size, opaque, 1);
        
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -outputImage.size.height);
        CGContextDrawImage(effectInContext, imageRect, outputImage.CGImage);
        
        vImage_Buffer effectInBuffer;
        
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(outputImage.size, opaque, 1);
        
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            CGFloat inputRadius = blurRadius * 1;
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            
            if (radius % 2 != 1) {
                radius += 1;
            }
            
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        
        BOOL effectImageBuffersAreSwapped = NO;
        
        if (hasSaturationChange) {
            
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            } else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        
        if (!effectImageBuffersAreSwapped)
            outputImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            outputImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContextWithOptions(imageRect.size, opaque, 1.0);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -imageRect.size.height);
    
    CGContextDrawImage(outputContext, imageRect, outputImage.CGImage);
    
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, outputImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
//    
//    if (tintColor) {
//        CGContextSaveGState(outputContext);
//        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
//        CGContextFillRect(outputContext, imageRect);
//        CGContextRestoreGState(outputContext);
//    }
    
    outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end
