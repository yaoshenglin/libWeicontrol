// http://www.wuleilei.com/

#ifndef paixiu_PXISARC_h
#define paixiu_PXISARC_h
#ifndef PX_STRONG
#if __has_feature(objc_arc)
#define PX_STRONG strong
#else
#define PX_STRONG retain
#endif
#endif
#ifndef PX_WEAK
#if __has_feature(objc_arc_weak)
#define PX_WEAK weak
#elif __has_feature(objc_arc)
#define PX_WEAK unsafe_unretained
#else
#define PX_WEAK assign
#endif
#endif

#if __has_feature(objc_arc)
#define PX_AUTORELEASE(expression) expression
#define PX_RELEASE(expression) expression
#define PX_RETAIN(expression) expression
#else
#define PX_AUTORELEASE(expression) [expression autorelease]
#define PX_RELEASE(expression) [expression release]
#define PX_RETAIN(expression) [expression retain]
#endif
#endif

#import <Foundation/Foundation.h>

@interface NSData (Base64)

/*!	
 @function	+dataWithBase64EncodedString:
 @discussion	This method returns an autoreleased NSData object. The NSData object is initialized with the
 contents of the Base 64 encoded string. This is a convenience method.
 @param	string	An NSString object that contains only Base 64 encoded data.
 @result	The NSData object. 
 */
+ (NSData *) dataWithBase64EncodedString:(NSString *) string;

/*!	
 @function	-initWithBase64EncodedString:
 @discussion	The NSData object is initialized with the contents of the Base 64 encoded string.
 This method returns self as a convenience.
 @param	string	An NSString object that contains only Base 64 encoded data.
 @result	This method returns self. 
 */
- (id) initWithBase64EncodedString:(NSString *) string;

/*!	
 @function	-base64EncodingWithLineLength:
 @discussion	This method returns a Base 64 encoded string representation of the data object.
 @param	lineLength A value of zero means no line breaks.  This is crunched to a multiple of 4 (the next
 one greater than inLineLength).
 @result	The base 64 encoded data. 
 */
- (NSString *) base64EncodingWithLineLength:(unsigned int) lineLength;


@end
