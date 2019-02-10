//  Copyright (C) 2018 Rob Mayoff <gitup@rob.dqd.com>.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import AppKit

class ToolbarItemWrapperView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Normally, a double-click in a window title bar zooms the window on the second mouse-up. In a unified title/toolbar window, if a mouse-up hit-tests into a subview of a toolbar item, the mouse-up cannot zoom the window. This subclass selectively suppresses hits to allow a double-click to zoom its window.
        guard let hitView = super.hitTest(point) else { return nil }
        
        var childView: NSView? = hitView
        
        while childView != nil, childView != self {
            switch childView {
            case let textField as NSTextField where textField.isEnabled && textField.isSelectable:
                    return hitView
            case let control as NSControl where control.isEnabled:
                    return hitView
            case let textView as NSTextView where textView.isSelectable:
                // The search field adds the field editor, an NSTextView, as a subview when it's being edited.
                    return hitView
            default: break
            }
            
            childView = childView?.superview
        }
        
        return nil
    }
}
