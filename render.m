/*
 *  render.m
 *  render a D64 directory to HTML
 *
 *  Written by Christian Vogelgsang <chris@vogelgsang.org>
 *  under the GNU Public License V2
 *
 *  based on test_dir.c
 *  written by Per Olofsson for diskimage.c
 *  http://www.paradroid.net/diskimage/
 *
 */

#import <Cocoa/Cocoa.h>

#include "render.h"
#include "diskimage.h"

// CBM directory file types
static char *ftype[] = {
  "DEL",
  "SEQ",
  "PRG",
  "USR",
  "DEL",
  "CBM",
  "DIR",
  "???"
};

#define CharWidth    8
#define CharHeight   9
#define BorderWidth  8
#define BorderHeight 8

void addLine(char *line,NSString **result,NSSize *resultSize)
{
  // fix encoding
  int i,l=strlen(line);
  for(i=0;i<l;i++) {
    unsigned char c = (unsigned char)line[i];
    // fix non-breaking space
    if(c==0xa0)
      line[i] = 0x20;
    // fix soft hyphen
    else if(c==0xad)
      line[i]=0xed;
  }

  // convert Latin1 to NSString
  NSString *lineString = [NSString stringWithCString:line encoding:NSISOLatin1StringEncoding];
  if(*result == nil)
    *result = lineString;
  else
    *result = [*result stringByAppendingString:lineString];
    
  // update size of output area
  resultSize->height += CharHeight; // font height
  int width = strlen(line) * CharWidth;
  if(resultSize->width < width)
    resultSize->width = width;
}

void readDiskDirectory(NSString *fileName,NSString **title,NSString **contents,
                       NSSize *resultSize,BOOL thumb)
{
  char line[80];
  char name[17];
  resultSize->width  = 0.0;
  resultSize->height = 0.0;

  // open disk image
  const char *fileNameRaw = [fileName cStringUsingEncoding:NSUTF8StringEncoding];
  DiskImage *di = di_load_image((char *)fileNameRaw);
  if(di==NULL) {
    addLine("ERROR OPENING DISK IMAGE!",title,resultSize);
  } else {
    // read raw disk title
    unsigned char *raw_title = di_title(di);

    // fetch disk name
    di_name_from_rawname(name,raw_title);

    // fetch disk id
    unsigned char did[6];
    int i;
    for(i=0;i<5;i++) {
      did[i] = raw_title[18+i];
    }
    did[5] = 0;
    
    // print directory header
    sprintf(line,"0 \"%-16s\" %s\n", name, did);
    addLine(line,title,resultSize);
  }
  
  // read dir contents
  if(di!=NULL) {
    ImageFile *dh = di_open(di, (unsigned char *)"$", T_PRG, "rb");
    if(dh==NULL) {
      addLine("ERROR OPENING $ FILE",contents,resultSize);
    } else {
      unsigned char buffer[254];
      int ok = 1;
      
      // read BAM
      if (di_read(dh, buffer, 254) != 254) {
        addLine("ERROR OPENING BAM",contents,resultSize);
        ok = 0;
      }

      // read dir blocks
      int num_entries = 0;
      while(ok && (di_read(dh, buffer, 254) == 254)) {
        int offset;
        for(offset = -2; offset < 254; offset += 32) {
          if (buffer[offset+2]) {
            di_name_from_rawname(name, buffer + offset + 5);
            int type = buffer[offset + 2] & 7;
            int closed = buffer[offset + 2] & 0x80;
            int locked = buffer[offset + 2] & 0x40;
            int size = buffer[offset + 31]<<8 | buffer[offset + 30];
            // quote name
            char quotename[19];
            sprintf(quotename, "\"%s\"", name);
            // print entry
            sprintf(line,"%-4d%-18s%c%s%c\n", 
              size, quotename, closed ? ' ' : '*', ftype[type], locked ? '<' : ' ');            
            // add line
            addLine(line,contents,resultSize);
            num_entries++;
            
            // add ellipsis if too many entries in thumbnail mode
            if(thumb) {
              if(num_entries==22) {
                addLine("...\n",contents,resultSize);
                ok = 0;
                break;
              }
            } 
            // illegal directory?
            else {
              if(num_entries==145) {
                addLine("... (TOO MANY!)\n",contents,resultSize);
                ok = 0;
                break;
              }
            }
          }
        }
      }
      // print free blocks
      sprintf(line,"%d BLOCKS FREE\n", di->blocksfree);
      addLine(line,contents,resultSize);
    }
    // close dir file
    di_close(dh);
    // free image
    di_free_image(di);
  }
  
  // adjust border
  if(thumb) {
    addLine("\n",contents,resultSize);
    resultSize->width  += BorderWidth * 2;
    resultSize->height += BorderHeight;
  } else {
    resultSize->height += BorderHeight * 2;
  }
}

NSString *getUrlPath(CFURLRef url)
{
  // return path component of a URL
  NSString *path = [[(NSURL *)url absoluteURL] path];
//  return [path stringByRemovingPercentEncoding:NSUTF8StringEncoding];
    return [path stringByRemovingPercentEncoding];
//  return [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

NSData *diskImageToHtml(CFBundleRef bundle,CFURLRef url,NSSize *resultSize,BOOL thumb)
{ 
  // get bundle resource path
  CFURLRef resDirURL = CFBundleCopyResourcesDirectoryURL(bundle);
  NSString *resPath = getUrlPath(resDirURL);
  CFRelease(resDirURL);
  
  // read template.html
  NSString *templPath = [resPath stringByAppendingPathComponent:@"template.html"];
  NSData *templateData = [NSData dataWithContentsOfFile:templPath];
  NSString *templateString = [[NSString alloc] initWithData:templateData
                                           encoding:NSUTF8StringEncoding];

  // create title and contents
  NSString *title = nil;
  NSString *contents = nil;
  readDiskDirectory(getUrlPath(url),&title,&contents,resultSize,thumb);
  if(title==nil)
    title = [NSString string];
  if(contents==nil)
    contents = [NSString string];

  // fill in template
  NSString *resultString = templateString;
  resultString = [resultString stringByReplacingOccurrencesOfString:@"DIR_TITLE"
                                                           withString:title];
  resultString = [resultString stringByReplacingOccurrencesOfString:@"DIR_CONTENTS"
                                                           withString:contents];

  // return data of string
  return [resultString dataUsingEncoding:NSUTF8StringEncoding];
}

