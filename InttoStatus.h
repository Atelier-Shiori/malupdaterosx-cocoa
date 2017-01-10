//
//  InttoStatus.h
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/10.
//
//

#import <Foundation/Foundation.h>

@interface InttoStatus : NSValueTransformer
+ (Class)transformedValueClass;
-(id)transformedValue:(id)value;
@end
