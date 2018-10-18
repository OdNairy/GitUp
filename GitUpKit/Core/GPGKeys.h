#import <Foundation/Foundation.h>
#include <gpgme.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPGKey : NSObject
@property (readonly) NSString* email;
@property (readonly) NSString* name;
@property (readonly) NSString* keyId;

+(NSArray<GPGKey *> *)allSecretKeys;

-(NSString*)signSignature:(NSString*)document;

@end

NS_ASSUME_NONNULL_END
