//
//  PKTextTrackStyling.swift
//  PlayKit
//
//  Created by Nilit Danan on 5/16/19.
//

import Foundation
import CoreMedia

struct RGBA: CustomStringConvertible {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
    
    var description: String {
        let desc = "(R:\(red), G:\(green), B:\(blue), Alpha:\(alpha))"
        return desc
    }
}

@objc public enum PKTextMarkupCharacterEdgeStyle: Int, CustomStringConvertible {
    case none
    case raised
    case depressed
    case uniform
    case dropShadow
    
    public var description: String {
        switch self {
        case .none:
            return kCMTextMarkupCharacterEdgeStyle_None as String
        case .raised:
            return kCMTextMarkupCharacterEdgeStyle_Raised as String
        case .depressed:
            return kCMTextMarkupCharacterEdgeStyle_Depressed as String
        case .uniform:
            return kCMTextMarkupCharacterEdgeStyle_Uniform as String
        case .dropShadow:
            return kCMTextMarkupCharacterEdgeStyle_DropShadow as String
        }
    }
}

@objc public class PKTextTrackStyling: NSObject {
    
    private(set) var textColor: RGBA?
    private(set) var backgroundColor: RGBA?
    private(set) var textSize: NSNumber?
    private(set) var edgeStyle: PKTextMarkupCharacterEdgeStyle = .none
    private(set) var edgeColor: RGBA?
    private(set) var fontFamily: String?
    
    public override var description: String {
        var textSizeString: String
        if let size = textSize {
            textSizeString = "\(size)% of the video height"
        } else {
            textSizeString = "[unset]"
        }
        
        let desc = "\(super.description)\n" +
            "TextColor: \(textColor?.description ?? "[unset]")\n" +
            "BackgroundColor: \(backgroundColor?.description ?? "[unset]")\n" +
            "TextSize: \(textSizeString)\n" +
            "EdgeStyle: \(edgeStyle.description)\n" +
            "EdgeColor: \(edgeColor?.description ?? "[unset]")\n" +
            "FontFamily: \(fontFamily?.description ?? "[unset]")\n"
        return  desc
    }
    
    /*!
        @abstract The foreground color for text.
     
        @discussion The color provided will be translated to a RGBA format. Therfore a transparece is accepted.
     
        @param color The desired color to append.
     
        @return Returns the updated object.
     */
    @discardableResult
    @objc public func setTextColor(_ color: UIColor) -> PKTextTrackStyling {
        var colorRGBA = RGBA(red: 0, green: 0, blue: 0, alpha: 0)
        if color.getRed(&colorRGBA.red, green: &colorRGBA.green, blue: &colorRGBA.blue, alpha: &colorRGBA.alpha) {
            textColor = colorRGBA
        } else {
            PKLog.debug("Can't set textColor. The color is not in a compatible color space.")
        }
        
        return self
    }
    
    /*!
        @abstract The background color for the shape holding the text.
     
        @discussion The color provided will be translated to a RGBA format. Therfore a transparece is accepted.
     
        @param color The desired color to append.
     
        @return Returns the updated object.
     */
    @discardableResult
    @objc public func setBackgroundColor(_ color: UIColor) -> PKTextTrackStyling {
        var colorRGBA = RGBA(red: 0, green: 0, blue: 0, alpha: 0)
        if color.getRed(&colorRGBA.red, green: &colorRGBA.green, blue: &colorRGBA.blue, alpha: &colorRGBA.alpha) {
            backgroundColor = colorRGBA
        } else {
            PKLog.debug("Can't set backgroundColor. The color is not in a compatible color space.")
        }
        
        return self
    }
    
    /*!
        @abstract The base font size expressed as a percentage of the video height.
     
        @discussion Value must be a non-negative number. This is a number holding a percentage of the height of the video frame. For example, a value of 5 indicates that the base font size should be 5% of the height of the video.
     
        @param percentageOfVideoHeight The percentage of the video height.
     
        @return Returns the updated object.
     */
    @discardableResult
    @objc public func setTextSize(percentageOfVideoHeight: Int) -> PKTextTrackStyling {
        if percentageOfVideoHeight > 0 {
            textSize = NSNumber(value: percentageOfVideoHeight)
        } else {
            PKLog.debug("Can't set a negative value to textSize.")
        }
        
        return self
    }
    
    /*!
        @abstract   Allows the setting of the style of character edges at render time.
     
        @discussion This controls the shape of the edges of drawn characters. Set a value of something other than PKTextMarkupCharacterEdgeStyle.none. These correspond to text edge styles available with Media Accessibility preferences (see <MediaAccessibility/MACaptionAppearance.h>). Default is PKTextMarkupCharacterEdgeStyle.none.
     
        @param style The desired style to append.
     
        @return Returns the updated object.
     */
    @discardableResult
    @objc public func setEdgeStyle(_ style: PKTextMarkupCharacterEdgeStyle) -> PKTextTrackStyling {
        edgeStyle = style
        
        return self
    }
    
    /*!
        @abstract The background color behind individual text characters.
     
        @discussion The color provided will be translated to a RGBA format. Therfore a transparece is accepted.
     
        @param color The desired color to append.
     
        @return Returns the updated object.
     */
    @discardableResult
    @objc public func setEdgeColor(_ color: UIColor) -> PKTextTrackStyling {
        var colorRGBA = RGBA(red: 0, green: 0, blue: 0, alpha: 0)
        if color.getRed(&colorRGBA.red, green: &colorRGBA.green, blue: &colorRGBA.blue, alpha: &colorRGBA.alpha) {
            edgeColor = colorRGBA
        } else {
            PKLog.debug("Can't set edgeColor. The color is not in a compatible color space.")
        }
        
        return self
    }
    
    /*!
        @abstract The name of the font.
     
        @discussion Value must be a String holding the family name of an installed font (e.g., "Helvetica") that is used to render and/or measure text.
     
        @param family The desired font family to append.
     
        @return Returns the updated object.
     */
    @discardableResult
    @objc public func setFontFamily(_ family: String) -> PKTextTrackStyling {
        if family.isEmpty {
            PKLog.debug("Can't set an empty string to the fontFamily.")
        } else {
            fontFamily = family
        }
        
        return self
    }
}
