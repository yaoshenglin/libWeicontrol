// http://www.wuleilei.com/

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

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

#define kChosenCipherBlockSize	kCCBlockSizeAES128
#define kChosenCipherKeySize	kCCKeySizeAES128
#define kChosenDigestLength		CC_SHA1_DIGEST_LENGTH

@interface StringEncryption : NSObject

+ (NSString *)encryptString:(NSString *)plainSourceStringToEncrypt;
+ (NSString *)decryptString:(NSString *)base64StringToDecrypt;
+ (NSString *)decryptString:(NSString *)base64StringToDecrypt encoding:(NSStringEncoding)encoding;
+ (NSData *)encrypt:(NSData *)plainText;
+ (NSData *)decrypt:(NSData *)plainText;
+ (NSData *)doCipher:(NSData *)plainText context:(CCOperation)encryptOrDecrypt;

@end
