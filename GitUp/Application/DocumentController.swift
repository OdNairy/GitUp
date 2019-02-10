//  Copyright (C) 2015-2018 Pierre-Olivier Latour <info@pol-online.net>
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

class DocumentController: NSDocumentController {
    override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes inTypes: [String]?, completionHandler: @escaping (Int) -> Void) {
        precondition(inTypes == ["public.directory"])
        
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.treatsFilePackagesAsDirectories = true
        super.beginOpenPanel(openPanel, forTypes: inTypes, completionHandler: completionHandler)
    }
    
    override func willPresentError(_ error: Error) -> Error {
        if error.isLocalChangesOverwriteError {
            let gcError = GCNewError(GCErrorCode.checkoutConflicts.rawValue, "Local changes would be overwritten by checkout")!
            return super.willPresentError(gcError)
            
        } else if let underlyingError = error.underlyingError, underlyingError.domain == GCErrorDomain {
            return super.willPresentError(underlyingError)
        }
        
        return super.willPresentError(error)
    }
    
    override func addDocument(_ document: NSDocument) {
        super.addDocument(document)
        
        AppDelegate.shared()?.handleDocumentCountChanged()
    }
    
    override func removeDocument(_ document: NSDocument) {
        super.removeDocument(document)
        
        AppDelegate.shared()?.handleDocumentCountChanged()
    }
    
    
}

fileprivate extension Error {
    var isLocalChangesOverwriteError: Bool {
        let nsError = self as NSError
        
        return nsError.domain == GCErrorDomain && nsError.code == GCErrorCode.checkoutConflicts.rawValue
            && nsError.localizedDescription.hasSuffix(" checkout")
    }
}

extension Error {
    var underlyingError: NSError? {
        return (self as NSError).userInfo[NSUnderlyingErrorKey] as? NSError
    }
}
