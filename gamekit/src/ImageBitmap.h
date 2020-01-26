// Apple GameKit Defold Extension
// ImageBitmap.h

#import <GameKit/GameKit.h>

@interface ImageBitmap : NSObject

#if defined(DM_PLATFORM_IOS)
- (unsigned char *)extractRGBABitmapFromImage:(UIImage *)image;
#else // osx platform
- (unsigned char *)extractRGBABitmapFromImage:(NSImage *)image;
#endif

@end