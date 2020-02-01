// Apple GameKit Defold Extension
// ImageBitmap.mm

#import "ImageBitmap.h"

@implementation ImageBitmap
{
	uint32_t *pixelsData;
}

#if defined(DM_PLATFORM_IOS)
- (unsigned char *)extractRGBABitmapFromImage:(UIImage *)image
{
	// NSLog(@"DEBUG:NSLog [ImageBitmap.mm] iOS extractRGBABitmapFromImage called");
    CGImageRef imageRef = [image CGImage];
#else // osx platform
- (unsigned char *)extractRGBABitmapFromImage:(NSImage *)image 
{
	// NSLog(@"DEBUG:NSLog [ImageBitmap.mm] OSX extractRGBABitmapFromImage called");
	NSRect imageRect = NSMakeRect(0.0, 0.0, image.size.width, image.size.height);
	CGImageRef imageRef = [image CGImageForProposedRect:&imageRect context:NULL hints:nil];
#endif
	size_t pixelsWidth = CGImageGetWidth(imageRef);
	size_t pixelsHeight = CGImageGetHeight(imageRef);
	uint8_t bytesPerPixel = 4; // RGBA
	size_t bitsPerComponent = 8; // 4 channels 32-bit RGBA
	size_t bytesPerRow = bytesPerPixel * pixelsWidth;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast; // create context with premultiplied RGBA
	pixelsData = (uint32_t *)calloc(bytesPerRow * pixelsHeight, sizeof(uint32_t));

	if(!pixelsData) {
		NSLog(@"DEBUG:NSLog [ImageBitmap.mm] error allocating memory for pixels data");
		return NULL;
	}
	
	// create bitmap context
	CGContextRef context = CGBitmapContextCreate(pixelsData, pixelsWidth, pixelsHeight, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);

	if(!context) {
		NSLog(@"DEBUG:NSLog [ImageBitmap.mm] error bitmap context not created");
		CGColorSpaceRelease(colorSpace);
		return NULL;
	}

	CGFloat width = image.size.width;
	CGFloat height = image.size.height;
	CGRect rect = CGRectMake(0.0, 0.0, width, height);

	// draws imageRef into context
	CGContextDrawImage(context, rect, imageRef);

	// pointer to the specified bitmap context’s image data	
	unsigned char *bitmap = (unsigned char *)CGBitmapContextGetData(context);

	if(bitmap) {
		// Core Graphics returns upside down image, UIImage is top-left cordinates and Core Graphics is bottom-left
		// flip bitmap vertically
		for (int yi=0; yi < (pixelsHeight / 2); yi++) {
			for (int xi=0; xi < pixelsWidth; xi++) {
				unsigned int offset1 = (xi + (yi * pixelsWidth)) * bytesPerPixel;
				unsigned int offset2 = (xi + ((pixelsHeight - 1 - yi) * pixelsWidth)) * bytesPerPixel;
				for (int bi=0; bi < bytesPerPixel; bi++) {
					unsigned char byte1 = bitmap[offset1 + bi];
					unsigned char byte2 = bitmap[offset2 + bi];
					bitmap[offset1 + bi] = byte2;
					bitmap[offset2 + bi] = byte1;
				}
			}
		}
	} else {
		NSLog(@"DEBUG:NSLog [ImageBitmap.mm] error bitmap not extracted from context");
		CGColorSpaceRelease(colorSpace);
		CGContextRelease(context);
		return NULL;
	}
	
	// clean up
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);

	return bitmap;
}

- (void)dealloc 
{
	free(pixelsData);
	[super dealloc];
}

@end