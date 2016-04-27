/*
 *  render.h
 *  render a D64 directory to HTML
 *
 *  Written by Christian Vogelgsang <chris@vogelgsang.org>
 *  under the GNU Public License V2 
 *
 */

// convert a disk image directory to HTML
NSData *diskImageToHtml(CFBundleRef bundle,CFURLRef url,NSSize *resultSize,BOOL thumb);
