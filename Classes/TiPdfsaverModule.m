/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiPdfsaverModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation TiPdfsaverModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"f45c1ecc-827f-4fa3-b6d8-dee3ccdb18ab";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.pdfsaver";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
	
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added 
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma Public APIs

CGPDFDocumentRef _templateDocument;
-(void)open:(id)args{
	NSString *pdf = [args objectAtIndex:0];

	CFURLRef url = CFURLCreateWithFileSystemPath (NULL, (CFStringRef)pdf, kCFURLPOSIXPathStyle, 0);
	_templateDocument = CGPDFDocumentCreateWithURL(url);
	CFRelease(url);
}

-(void)close{
	CGPDFDocumentRelease(_templateDocument);
}

-(UIImageView*)getPage:(id)args
{
	NSNumber *pagenum = [args objectAtIndex:0];

	CGPDFPageRef templatePage = CGPDFDocumentGetPage(_templateDocument, [pagenum integerValue]);
	CGRect templatePageBounds = CGPDFPageGetBoxRect(templatePage, kCGPDFCropBox);
	UIGraphicsBeginImageContext(templatePageBounds.size);

	CGContextRef contextRef = UIGraphicsGetCurrentContext();

	CGContextTranslateCTM(contextRef, 0.0, templatePageBounds.size.height);
	CGContextScaleCTM(contextRef, 1.0, -1.0);

	CGContextDrawPDFPage(contextRef, templatePage);

	UIImage *imageToReturn = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return [[[TiBlob alloc] initWithImage:imageToReturn] autorelease];;
}

-(void)saveThumbnail:(id)args{
	NSString *pdf = [args objectAtIndex:0];
	NSString *jpeg = [args objectAtIndex:1];

	CFURLRef url = CFURLCreateWithFileSystemPath (NULL, (CFStringRef)pdf, kCFURLPOSIXPathStyle, 0);
	CGPDFDocumentRef templateDocument = CGPDFDocumentCreateWithURL(url);
	CFRelease(url);

	CGPDFPageRef templatePage = CGPDFDocumentGetPage(templateDocument, 1);
	CGRect templatePageBounds = CGPDFPageGetBoxRect(templatePage, kCGPDFCropBox);
	UIGraphicsBeginImageContext(templatePageBounds.size);

	CGContextRef context = UIGraphicsGetCurrentContext();

	CGContextTranslateCTM(context, 0.0, templatePageBounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);

	CGContextDrawPDFPage(context, templatePage);
	UIImage *imageToReturn = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	CGPDFDocumentRelease(templateDocument);

	[UIImageJPEGRepresentation(imageToReturn, 1.0) writeToFile:jpeg atomically:YES];
}

-(void)saveInExportFileWithDrawings:(id)args{
	NSString *exportpath = [args objectAtIndex:0];
	NSDictionary *drawings = [args objectAtIndex:1];
	NSNumber *all = [args objectAtIndex:2];

	size_t count = CGPDFDocumentGetNumberOfPages(_templateDocument);

	UIGraphicsBeginPDFContextToFile(exportpath, CGRectMake(0, 0, 612, 792), nil);
	for (int pageNumber = 1; pageNumber <= count; pageNumber++) {
		id image = [drawings objectForKey:[NSString stringWithFormat:@"%d",pageNumber ]];
		if(image == nil && [all boolValue] == NO){
			continue;
		}

	    CGPDFPageRef templatePage = CGPDFDocumentGetPage(_templateDocument, pageNumber);
	    CGRect templatePageBounds = CGPDFPageGetBoxRect(templatePage, kCGPDFCropBox);
	    UIGraphicsBeginPDFPageWithInfo(templatePageBounds, nil);
	    CGContextRef context = UIGraphicsGetCurrentContext();
	    CGContextTranslateCTM(context, 0.0, templatePageBounds.size.height);
	    CGContextScaleCTM(context, 1.0, -1.0);

	    CGContextDrawPDFPage(context, templatePage);
	    CGContextTranslateCTM(context, 0.0, templatePageBounds.size.height);
	    CGContextScaleCTM(context, 1.0, -1.0);

	    if(image != nil){
	    	NSURL *url = [NSURL URLWithString:image];    
			NSData *imageData = [NSData dataWithContentsOfURL:url];
			UIImage *ret = [UIImage imageWithData:imageData];

	    	[ret drawInRect:CGRectMake(0, 0, templatePageBounds.size.width, templatePageBounds.size.height)];
	    }
	}
	UIGraphicsEndPDFContext();
}

@end
