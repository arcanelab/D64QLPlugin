#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <WebKit/WebKit.h>

#include "render.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface,
                                 QLThumbnailRequestRef thumbnail,
                                 CFURLRef url,
                                 CFStringRef contentTypeUTI,
                                 CFDictionaryRef options,
                                 CGSize maxSize)
{
  // ignore icon mode rendering in Finder
  NSDictionary *d = (NSDictionary *)options;
  id iconMode = [d valueForKey:@"IconMode"];
  if(iconMode!=nil)
    return noErr;
  
  // alloc pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // render disk directory to HTML and estimate size
  CFBundleRef bundle = QLThumbnailRequestGetGeneratorBundle(thumbnail);
  NSSize size;
  NSData *data = diskImageToHtml(bundle, url, &size, TRUE);

  // calc thumb size
  float scaleX = maxSize.width  / size.width;
  float scaleY = maxSize.height / size.height;
  if(scaleX > 1.0f)
    scaleX = 1.0f;
  if(scaleY > 1.0f)
    scaleY = 1.0f;
  float scale = fmin(scaleX,scaleY);
  CGSize thumbSize = CGSizeMake(size.width  * scale,
                                size.height * scale);
#ifdef DEBUG
  NSLog(@"html size  %f %f",size.width,size.height);
  NSLog(@"scale      %f %f",scaleX,scaleY);
  NSLog(@"max size   %f %f",maxSize.width,maxSize.height);
  NSLog(@"thumb size %f %f",thumbSize.width,thumbSize.height);
#endif

  // prepare WebKit
  NSRect renderRect = NSMakeRect(0.0f,0.0f,size.width,size.height);
  WebView* webView = [[WebView alloc] initWithFrame:renderRect];
  [webView scaleUnitSquareToSize:NSMakeSize(scale,scale)];
  [[[webView mainFrame] frameView] setAllowsScrolling:NO];
  
  // load HTML into WebKit
  [[webView mainFrame] loadData:data MIMEType:@"text/html"
                 textEncodingName:@"UTF-8" baseURL:nil];
  while([webView isLoading]) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true);
  }
    
  // get a render context and draw onto it
  CGContextRef context = 
    QLThumbnailRequestCreateContext(thumbnail, thumbSize, false, NULL);
  if(context != NULL) {
    NSGraphicsContext* nsContext = [NSGraphicsContext
                        graphicsContextWithGraphicsPort:(void *)context 
                                                flipped:[webView isFlipped]];
    [webView displayRectIgnoringOpacity:[webView bounds]
                              inContext:nsContext];
    QLThumbnailRequestFlushContext(thumbnail, context);
    CFRelease(context);
  }
  
  // release pool
  [pool release];
  return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
