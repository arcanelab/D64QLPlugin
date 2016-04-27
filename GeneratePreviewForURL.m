#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>

#include "render.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface,
                               QLPreviewRequestRef preview,
                               CFURLRef url,
                               CFStringRef contentTypeUTI,
                               CFDictionaryRef options)
{
  // create release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
  // convert disk image to HTML
  CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle(preview);
  NSSize size;
  NSData *output = diskImageToHtml(bundle, url, &size, FALSE);

  // give size hint
  CFDictionaryRef properties = 
    (CFDictionaryRef)[[[NSDictionary alloc] 
      initWithObjectsAndKeys:
        [NSNumber numberWithFloat:size.width * 2],
        kQLPreviewPropertyWidthKey,
        [NSNumber numberWithFloat:size.height * 2],
        kQLPreviewPropertyHeightKey,
        nil] autorelease];

  // render as HTML
  QLPreviewRequestSetDataRepresentation(preview,
                                        (CFDataRef)output, 
                                        kUTTypeHTML, 
                                        properties);

  // release pool
  [pool release];
  return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
