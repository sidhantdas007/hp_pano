//
// Hewlett-Packard Company
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*!
 * @abstract Represents the paper used to print
 * @discussion This class represents the paper used by the printer. It includes both the size of the media (e.g. 4 x 6 inch paper) as well as the type (e.g. photo paper).
 */
@interface HPPPPaper : NSObject

/*!
 * @abstract List of default supported paper sizes
 * @const HPPPPaperSize4x5 4" by 5" photo sticker media
 * @const HPPPPaperSize4x6 4" by 6" photo paper
 * @const HPPPPaperSize5x7 5" by 7" photo paper
 * @const HPPPPaperSizeLetter Standard 8.5" x 11" letter paper
 * @const HPPPPaperSizeA4 Standard 210mm x 297mm letter paper
 * @const HPPPPaperSizeA5 Standard 148mm x 210mm
 * @const HPPPPaperSizeA6 Standard 105mm x 148mm
 * @const HPPPPaperSize10x13 HP international equivalent for 4x5 inch
 * @const HPPPPaperSize10x15 HP international equivalent for 4x6 inch
 * @const HPPPPaperSize13x18 HP international equivalent for 5x7 inch
 * @const HPPPPaperSizeCustom Used to indicate last enum value used by the print library. Apps can register custom paper size ID using any value greater than HPPPPaperSizeCustom
 */
typedef enum {
    HPPPPaperSize4x5,
    HPPPPaperSize4x6,
    HPPPPaperSize5x7,
    HPPPPaperSizeLetter,
    HPPPPaperSizeA4,
    HPPPPaperSizeA5,
    HPPPPaperSizeA6,
    HPPPPaperSize10x13,
    HPPPPaperSize10x15,
    HPPPPaperSize13x18,
    HPPPPaperSizeCustom
} HPPPPaperSize;

/*!
 * @abstract List of default supported paper types
 * @const HPPPPaperTypePlain Plain paper
 * @const HPPPPaperTypePhoto Photo paper
 * @const HPPPPaperTypeCustom Used to indicate last enum value used by the print library. Apps can register custom paper type ID using any value greater than HPPPPaperTypeCustom
 */
typedef enum {
    HPPPPaperTypePlain,
    HPPPPaperTypePhoto,
    HPPPPaperTypeCustom
} HPPPPaperType;

/*!
 * @abstract Dictionary key used to specify the paper size ID when registering a paper size
 * @discussion An NSNumber value representing an unsigned integer
 */
extern NSString * const kHPPPPaperSizeIdKey;

/*!
 * @abstract Dictionary key used to specify the paper size ID when registering a paper size
 * @discussion An NSString value used in the UI to represent the paper size
 */
extern NSString * const kHPPPPaperSizeTitleKey;

/*!
 * @abstract Dictionary key used to specify the paper type ID when registering a paper type
 * @discussion An NSNumber value representing an unsigned integer
 */
extern NSString * const kHPPPPaperTypeIdKey;

/*!
 * @abstract Dictionary key used to specify the paper type ID when registering a paper type
 * @discussion An NSString value used in the UI to represent the paper size
 */
extern NSString * const kHPPPPaperTypeTitleKey;

/*!
 * @abstract Dictionary key used to specify whether the paper type being registered is photo paper or not
 * @discussion An NSNumber value representing a boolean value (YES or NO). This key is optional and the default value is NO.
 */
extern NSString * const kHPPPPaperTypePhotoKey;

/*!
 * @abstract Dictionary key used to specify physical width of the paper
 * @discussion An NSNumber value representing a floating point width in inches
 */
extern NSString * const kHPPPPaperSizeWidthKey;

/*!
 * @abstract Dictionary key used to specify physical height of the paper
 * @discussion An NSNumber value representing a floating point height in inches
 */
extern NSString * const kHPPPPaperSizeHeightKey;

/*!
 * @abstract Dictionary key used to specify paper width to report to the printer
 * @discussion An NSNumber value representing a floating point width in inches.
 * If this optional value is not included in the dictionary when the paper size is registered then the actual paper width will be used with the printer.
 * Example: 4x5" paper reports 4x6" to the printer.
 */
extern NSString * const kHPPPPaperSizePrinterWidthKey;

/*!
 * @abstract Dictionary key used to specify paper height to report to the printer
 * @discussion An NSNumber value representing a floating point height in inches. 
 * If this optional value is not included in the dictionary when the paper size is registered then the actual paper height will be used with the printer. 
 * Example: 4x5" paper reports 4x6" to the printer.
 */
extern NSString * const kHPPPPaperSizePrinterHeightKey;

/*!
 * @abstract Label to display for the paper size
 */
@property (nonatomic, strong, readonly) NSString *sizeTitle;

/*!
 * @abstract Label to display for the paper type
 */
@property (nonatomic, strong, readonly) NSString *typeTitle;

/*!
 * @abstract Physical width of the paper in inches
 */
@property (nonatomic, assign, readonly) float width;

/*!
 * @abstract Physical height of the paper in inches
 */
@property (nonatomic, assign, readonly) float height;

/*!
 * @abstract The paper size used by this paper
 * @seealso HPPPPaperSize
 * @seealso registerSize:
 * @seealso registerType:
 * @seealso associatePaperSize:withType:
 */
@property (nonatomic, assign, readonly) NSUInteger paperSize;

/*!
 * @abstract The paper type used by this paper
 * @seealso HPPPPaperType
 * @seealso registerSize:
 * @seealso registerType:
 * @seealso associatePaperSize:withType:
 */
@property (nonatomic, assign, readonly) NSUInteger paperType;

/*!
 * @abstract Indicates that this is photo paper
 */
@property (nonatomic, assign, readonly) BOOL photo;

/*!
 * @abstract Initializer using enums
 * @param paperSize The size of the paper
 * @param paperType The type of the paper
 * @returns The initialized HPPPPaper object
 * @seealso HPPPPaperSize
 * @seealso HPPPPaperType
 * @seealso registerSize:
 * @seealso registerType:
 * @seealso associatePaperSize:withType:
 */
- (id)initWithPaperSize:(NSUInteger)paperSize paperType:(NSUInteger)paperType;


/*!
 * @abstract Initializer using string titles
 * @param paperSize The title of the paper size
 * @param paperType The title of the paper type
 * @seealso titleFromSize:
 * @seealso titleFromType:
 * @returns The initialized HPPPPaper object
 */
- (id)initWithPaperSizeTitle:(NSString *)paperSizeTitle paperTypeTitle:(NSString *)paperTypeTitle;

/*!
 * @abstract Creates a string for the paper width
 * @returns Paper width as a string suitable for display
 */
- (NSString *)paperWidthTitle;

/*!
 * @abstract Creates a string for the paper height
 * @returns Paper height as a string suitable for display
 */
- (NSString *)paperHeightTitle;

/*!
 * @abstract Creates the paper size to be used by AirPrint
 * @returns A reference paper size to be used during the paper size selection process
 */
- (CGSize)printerPaperSize;

/*!
 * @abstract Retrieves the title for a given paper size
 * @discussion This method asserts that the size given is a valid paper size. An exception is raised if an invalid size is passed.
 * @returns Display title for the paper size
 * @seealso sizeFromTitle:
 */
+ (NSString *)titleFromSize:(NSUInteger)paperSize;

/*!
 * @abstract Retrieves the paper size for a given size title
 * @description This method asserts that the string given is a valid paper size. An exception is raised if an invalid string is passed.
 * @returns The paper size ID for the size title
 * @seealso titleFromSize:
 */
+ (NSUInteger)sizeFromTitle:(NSString *)paperSizeTitle;

/*!
 * @abstract Retrieves the title for a given paper type
 * @description This method asserts that the type given is a valid paper type. An exception is raised if an invalid type is passed.
 * @returns Display title for the paper type
 * @seealso typeFromTitle:
 */
+ (NSString *)titleFromType:(NSUInteger)paperType;

/*!
 * @abstract Retrieves the paper type for a given type title
 * @description This method asserts that the string given is a valid paper type. An exception is raised if an invalid string is passed.
 * @returns The paper type ID for the type title
 * @seealso titleFromType:
 */
+ (NSUInteger)typeFromTitle:(NSString *)paperTypeTitle;

/*!
 * @abstract Registers a paper size
 * @param info An NSDictionary containing an ID, title, width, and height. Optionally includes special printer width and height.
 * @returns YES or NO whether the paper size was added successfully
 * @seealso kHPPPPaperSizeIdKey
 * @seealso kHPPPPaperSizeTitleKey
 * @seealso kHPPPPaperSizeWidthKey
 * @seealso kHPPPPaperSizeHeightKey
 * @seealso kHPPPPaperSizePrinterWidthKey
 * @seealso kHPPPPaperSizePrinterHeightKey
 * @seealso registerType:
 * @seealso associatePaperSize:withType:
 */
+ (BOOL)registerSize:(NSDictionary *)info;

/*!
 * @abstract Registers a paper type
 * @param info An NSDictionary containing an ID, title, and flag indicating whether the type is photo paper or not.
 * @returns YES or NO whether the paper type was added successfully
 * @seealso kHPPPPaperTypeIdKey
 * @seealso kHPPPPaperTypeTitleKey
 * @seealso kHPPPPaperTypePhotoKey
 * @seealso registerSize:
 * @seealso associatePaperSize:withType:
 */
+ (BOOL)registerType:(NSDictionary *)info;

/*!
 * @abstract Associates a paper size with a paper type
 * @discussion Paper combinations cannot be used in the supported paper list until they are associated using this method.
 * @param sizeId The ID of the paper size to be associated
 * @param typeId The ID of the paper type to be associated
 * @returns YES or NO whether the paper size and type were associated successfully
 * @seealso registerSize:
 * @seealso registerType:
 */
+ (BOOL)associatePaperSize:(NSUInteger)sizeId withType:(NSUInteger)typeId;

/*!
 * @abstract A list of all paper types
 * @returns An array of HPPPPaper objects representing every registered paper size/type combination
 * @seealso registerSize:
 * @seealso registerType:
 * @seealso associatePaperSize:withType:
 */
+ (NSArray *)availablePapers;

/*!
 * @abstract Standard default paper to use with the USA paper list
 * @returns An HPPPPaper object to use as default paper
 * @seealso standardUSAPapers
 */
+ (HPPPPaper *)standardUSADefaultPaper;

/*!
 * @abstract A list of papers typically used in the the US
 * @returns An array of HPPPPaper objects representing standard US papers
 * @seealso HPPPPaperSize
 * @seealso HPPPPaperType
 * @seealso standardUSADefaultPaper
 */
+ (NSArray *)standardUSAPapers;

/*!
 * @abstract Standard default paper to use with the international paper list
 * @returns An HPPPPaper object to use as default paper
 * @seealso standardInternationalPapers
 */
+ (HPPPPaper *)standardInternationalDefaultPaper;

/*!
 * @abstract A list of papers typically used internationally (outside the US)
 * @returns An array of HPPPPaper objects representing standard internationally papers
 * @seealso HPPPPaperSize
 * @seealso HPPPPaperType
 * @seealso standardInternationalDefaultPaper
 */
+ (NSArray *)standardInternationalPapers;

/*!
 * @abstract Check if a paper combo is valid
 * @discussion A paper size and type combination is valid if it has been registered using associatePaperSize:withType:
 * @param paperSize The ID of the size to check
 * @param paperType The ID of the type to check
 * @returns YES or NO indicating whether the paper combination is valid or not
 * @seealso registerSize:
 * @seealso registerType:
 * @seealso associatePaperSize:withType:
 */
+ (BOOL)validPaperSize:(NSUInteger)paperSize andType:(NSUInteger)paperType;

/*!
 * @abstract Check if a paper combo is supported by this application
 * @discussion A paper size and type combination is supported if it is included in the supportedPapers list of the HPPP object. 
 * Note that not all valid papers are necessarily supported by any given application.
 * @param paperSize The ID of the size to check
 * @param paperType The ID of the type to check
 * @returns YES or NO indicating whether the paper combination is supported
 * @seealso registerSize:
 * @seealso registerType:
 * @seealso associatePaperSize:withType:
 */
+ (BOOL)supportedPaperSize:(NSUInteger)paperSize andType:(NSUInteger)paperType;

/*!
 * @abstract Retrieves the default paper type for a given paper size
 * @param paperSize The size of paper to lookup
 * @returns An NSNumber object representing the unsigned integer ID value of the default type or nil if there are no types associated with the paper size. 
 * First looks for paper size in the supportedPapers property of the HPPP object. 
 * If not found there, looks for size in list of all available papers. This allows app developers to override default by ordering the supportedPapers list.
 */
+ (NSNumber *)defaultTypeForSize:(NSUInteger)paperSize;

/*!
 * @abstract Retrieves a list of paper types supported by the paper size of this instance
 * @returns An array of NSNumber objects representing the unsigned integer ID values of the paper types supported
 */
- (NSArray *)supportedTypes;

/*!
 * @abstract Checks if this paper size supports a given type
 * @returns YES or NO indicating if this paper size supports the type given
 */
- (BOOL)supportsType:(NSUInteger)paperType;

/*!
 * @abstract Restores list of supported sizes, types, and associations to original default values
 * @description Note that this method also resets the HPPP object's supportedPapers and defaultPaper properties to ensure consistency
 */
+ (void)resetPaperList;

@end
