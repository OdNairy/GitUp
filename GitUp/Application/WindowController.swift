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

import Foundation

class WindowController: GIWindowController, NSWindowDelegate {
  override func windowDidLoad() {
    super.windowDidLoad()
    
    self.window.delegate = self
  }
  
  override func synchronizeWindowTitleWithDocumentName() {
    super.synchronizeWindowTitleWithDocumentName()
    
    print(#function)
    guard let document = document as? Document else { return }
    
    document.titleTextField?.stringValue = document.displayTitle
  }
  
  func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
    guard let document = document as? Document else { return nil }
    
    return document.undoManager
  }
}

private extension Document {
  var displayTitle: String {
    let title: String
    switch (displayName, windowMode) {
    case let (displayName?, windowMode?):
      title = "\(displayName) • \(windowMode)"
    case let (displayName?, _):
      title = displayName
    case let (_, windowMode?):
      title = windowMode
    default:
      title = ""
    }
    return title
  }
}
