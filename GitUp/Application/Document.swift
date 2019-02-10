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

enum RepositoryErorr: Error {
    case bareRepoIsNotSupported
}

enum CloneMode {
    case none
    case `default`
    case recursive
}

class HelpData {
    enum HelpIdentifier: String {
        case map
        case commit
        case stashes
        case config
        case quickview
        case diff
        case search
        case tags
        case ancestors
        case snapshots
        case reflog
        case rewrite
        case split
        case resolve
    }
    
    static let shared = HelpData()
    
    private let data: [String: Any]
    private static let shouldLoadData = true
    
    private init() {
        guard let helpURL = Bundle.main.url(forResource: "Help", withExtension: "plist") else {
            assertionFailure()
            data = [:]
            return
        }
        
        do {
            let plistData = try Data(contentsOf: helpURL)
            data = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as! [String: Any]
        } catch {
            assertionFailure()
            data = [:]
        }
    }
    
    func prepareData() {
        // This function does nothing but still need to force call shared init
    }
    
    func help(for identifier: HelpIdentifier) -> String {
        #warning("Not implemented")
        return ""
    }
}


class Document2: NSDocument {
    enum WindowMode: Equatable {
        enum Tab: Int {
            case map
            case commit
            case stashes
            
            var index: Int {
                return rawValue
            }
            
            var mode: WindowMode {
                switch self {
                case .map: return .map
                case .commit: return .commit
                case .stashes: return .stashes
                }
            }
        }
        
        case map
        case mapQuickView
        case mapDiff
        case mapRewrite
        case mapSplit
        case mapResolve
        case mapConfig
        case commit
        case stashes
        
        static var mapChilds: [WindowMode] = [.mapQuickView, .mapDiff, .mapRewrite, .mapSplit, .mapResolve, .mapConfig]
        
        var tabIdentifier: String {
            switch self {
            case .map: return "map"
            case .mapQuickView: return "quickview"
            case .mapDiff: return "diff"
            case .mapRewrite: return "rewrite"
            case .mapSplit: return "split"
            case .mapResolve: return "resolve"
            case .mapConfig: return "config"
                
            case .commit: return "commit"
            case .stashes: return "stashes"
            }
        }
        
        var tab: Tab {
            switch self {
            case .map, .mapQuickView, .mapDiff, .mapRewrite, .mapSplit, .mapResolve, .mapConfig:
                return .map
            case .commit:
                return .commit
            case .stashes:
                return .stashes
            }
        }
        
        init?(tag: Int) {
            switch tag {
            case 0: self = .map
            case 1: self = .commit
            case 2: self = .stashes
            default: return nil
            }
        }
    }
    
    enum SideView {
        case search
        case tags
        case snapshots
        case reflog
        case ancestors
        
        var helpIdentifier: String {
            switch self {
            case .search: return "search"
            case .tags: return "tags"
            case .snapshots: return "snapshots"
            case .reflog: return "reflog"
            case .ancestors: return "ancestors"
            }
        }
    }
    
    private static let maxProgressRefreshRate = 10.0
    private static let sideViewAnimationDuration: TimeInterval = 0.15
    
    @IBOutlet private var mainWindow: NSWindow!
    @IBOutlet open var contentView: NSView!
    
    @IBOutlet open var toolbar: NSToolbar!
    
    @IBOutlet weak open var helpView: NSView!
    @IBOutlet weak open var helpTextField: NSTextField!
    @IBOutlet weak open var helpContinueButton: NSButton!
    @IBOutlet weak open var helpDismissButton: NSButton!
    @IBOutlet weak open var helpOpenButton: NSButton!
    
    @IBOutlet weak open var mainTabView: NSTabView!
    @IBOutlet weak open var mapContainerView: NSView!
    
    @IBOutlet open var titleView: NSView!
    @IBOutlet weak open var titleTextField: NSTextField!
    @IBOutlet weak open var infoTextField0: NSTextField!
    
    
    @IBOutlet open var leftView: NSView!
    @IBOutlet weak open var modeControl: NSSegmentedControl!
    @IBOutlet weak open var previousButton: NSButton!
    @IBOutlet weak open var nextButton: NSButton!
    
    @IBOutlet open var rightView: NSView!
    @IBOutlet weak open var snapshotsButton: NSButton!
    @IBOutlet weak open var searchField: NSSearchField!
    @IBOutlet weak open var exitButton: NSButton!
    
    @IBOutlet open var mapView: NSView!
    @IBOutlet weak open var mapControllerView: NSView! // Temporary placeholder replaced by actual controller view at load time
    @IBOutlet weak open var showMenu: NSMenu!
    @IBOutlet weak open var infoTextField1: NSTextField!
    @IBOutlet weak open var infoTextField2: NSTextField!
    @IBOutlet weak open var progressTextField: NSTextField!
    @IBOutlet weak open var progressIndicator: NSProgressIndicator!
    @IBOutlet weak open var pullButton: NSButton!
    @IBOutlet weak open var pushButton: NSButton!
    @IBOutlet weak open var hiddenWarningView: NSView!
    
    @IBOutlet open var tagsView: NSView!
    @IBOutlet weak open var tagsControllerView: NSView! // Temporary placeholder replaced by actual controller view at load time
    
    
    @IBOutlet open var snapshotsView: NSView!
    @IBOutlet weak open var snapshotsControllerView: NSView! // Temporary placeholder replaced by actual controller view at load time
    
    
    @IBOutlet open var reflogView: NSView!
    @IBOutlet weak open var reflogControllerView: NSView! // Temporary placeholder replaced by actual controller view at load time
    
    
    @IBOutlet open var searchView: NSView!
    @IBOutlet weak open var searchControllerView: NSView! // Temporary placeholder replaced by actual controller view at load time
    
    
    @IBOutlet open var ancestorsView: NSView!
    @IBOutlet weak open var ancestorsControllerView: NSView! // Temporary placeholder replaced by actual controller view at load time
    
    
    @IBOutlet open var rewriteView: NSView!
    @IBOutlet weak open var rewriteControllerView: NSView! // Temporary placeholder replaced by actual controller view at load time
    
    
    @IBOutlet open var splitView: NSView!
    @IBOutlet weak open var splitControllerView: NSView! // Temporary placeholder replaced by actual controller view at load time
    
    
    @IBOutlet open var resolveView: NSView!
    @IBOutlet weak open var resolveControllerView: NSView! // Temporary placeholder replaced by actual controller view at load time
    
    
    @IBOutlet open var resetView: NSView!
    @IBOutlet weak open var untrackedButton: NSButton!
    
    
    @IBOutlet open var settingsWindow: NSWindow!
    @IBOutlet weak open var indexDiffsButton: NSButton!
    
    var cloneMode: CloneMode = .none
    var windowMode: WindowMode!
    
    
    private let unifiedToolbal: Bool // Replace with #available(OSX 10.10, *)
    private let numberFormatter: NumberFormatter
    private let dateFormatter: DateFormatter
    
    private var repository: GCLiveRepository?
    private let checkTimer: CFRunLoopTimer

    private var quickViewAncestors: GCHistoryWalker?
    private var quickViewDescendants: GCHistoryWalker?
    private var quickViewCommits: [GCHistoryCommit]?
    private var quickViewIndex: Int = 0
    private var resolvingConflicts: Int = 0
    
    private var windowController: WindowController!
    private var mapViewController: GIMapViewController!
    private var tagsViewController: GICommitListViewController!
    private var snapshotListViewController: GISnapshotListViewController!
    private var unifiedReflogViewController: GIUnifiedReflogViewController!
    private var searchResultsViewController: GICommitListViewController!
    private var ancestorsViewController: GICommitListViewController!
    private var quickViewController: GIQuickViewController!
    private var diffViewController: GIDiffViewController!
    private var commitRewriterViewController: GICommitRewriterViewController!
    private var commitSplitterViewController: GICommitSplitterViewController!
    private var conflictResolverViewController: GIConflictResolverViewController!
    private var commitViewController: GICommitViewController!
    private var stashListViewController: GIStashListViewController!
    private var configViewController: GIConfigViewController!
    
    private var updatedReferences: [String: String]?
    private var savedFirstResponder: NSResponder?
    private var lastHEADBranch: GCHistoryLocalBranch?
    
    private var ready = false
    private var indexing = false
    private var abortIndexing = false
    private var searchReady = false
    private var helpHEADDisabled = false
    private var preventSelectionLoopback = false
    private var checkingForChanges = false
    
    private static var userDefaultsObserverContext = 0
    
    
    
    static let help: [String: Any] = {
        guard let helpURL = Bundle.main.url(forResource: "Help", withExtension: "plist") else {
            assertionFailure()
            return [:]
        }
        
        do {
            let plistData = try Data(contentsOf: helpURL)
            return try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as! [String: Any]
        } catch {
            assertionFailure()
            return [:]
        }
    }()
    
    override init() {
        
        if #available(OSX 10.10, *) {
            unifiedToolbal = NSWindow.instancesRespond(to: #selector(setter: NSWindow.titleVisibility))
        } else {
            unifiedToolbal = false
        }
        
        numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.numberStyle = .decimal
        
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        
        var runloopTimerContext = CFRunLoopTimerContext()
        checkTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, .greatestFiniteMagnitude, .greatestFiniteMagnitude, 0, 0, { (_, pointer) in
            autoreleasepool{
                pointer?.assumingMemoryBound(to: Document2.self).pointee.checkForChanges(nil)
            }
        }, nil)
        
        super.init()
        
        HelpData.shared.prepareData()
        
        runloopTimerContext.info = Unmanaged.passUnretained(self).toOpaque()
        
        UserDefaults.standard.addObserver(self, forKeyPath: kUserDefaultsKey_DiffWhitespaceMode, options: [], context: &Document2.userDefaultsObserverContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(_didBecomeActive(_:)), name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_didResignActive(_:)), name: NSApplication.didResignActiveNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSApplication.didResignActiveNotification, object: nil)
        UserDefaults.standard.removeObserver(self, forKeyPath: kUserDefaultsKey_DiffWhitespaceMode)
        
        CFRunLoopTimerInvalidate(checkTimer)
        
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            assert(GCLiveRepository.allocatedCount() == NSDocumentController.shared.documents.count)
        }
        #endif
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &Document2.userDefaultsObserverContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        assert(keyPath == kUserDefaultsKey_DiffWhitespaceMode)
        repository?.diffWhitespaceMode = UserDefaults.standard.diffWhitespaceMode
    }
    
    override func read(from url: URL, ofType typeName: String) throws {
        let repository = try GCLiveRepository(existingLocalRepository: url.path)
        defer { self.repository = repository }
        
        guard repository.isBare else { throw RepositoryErorr.bareRepoIsNotSupported }
        
        #if DEBUG
        if NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option) {
            try FileManager.default.removeItem(atPath: repository.privateAppDirectoryPath())
        }
        #endif
        
        repository.delegate = self
        repository.undoManager = undoManager
        repository.areSnapshotsEnabled = true
        
        if NSApp.isActive {
            repository.notifyChanged() // Otherwise -didBecomeActive: will take care of it
        } else {
            repository.areAutomaticSnapshotsEnabled = true // TODO: Is this a good idea?
        }
        
        repository.diffWhitespaceMode = UserDefaults.standard.diffWhitespaceMode // UserDefaults returns 0 if no value so guarantee to exist enum case
        
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            assert(GCLiveRepository.allocatedCount() == NSDocumentController.shared.documents.count)
        }
        #endif
    }
    
    override func close() {
        super.close()
        
        CFRunLoopTimerSetNextFireDate(checkTimer, .greatestFiniteMagnitude)
        
        assert(mainWindow != nil)
        repository?.setUserInfo(mainWindow!.frameDescriptor, forKey: kRepositoryUserInfoKey_MainWindowFrame)
        
        repository?.delegate = nil
        repository = nil
    }
    
    override func makeWindowControllers() {
        assert(windowController == nil)
        
        windowController = WindowController(windowNibName: "Document", owner: self)
        windowController.delegate = self
        addWindowController(windowController)
    }
    
    // This is called when opening documents or attempting to open a document already opened
    override func showWindows() {
        super.showWindows()
        
        if !ready {
            DispatchQueue.main.async {
                self._documentDidOpen(nil)
            }
            ready = true
        }
    }
    
    private var stateAttributes: [NSAttributedString.Key:Any]?
    override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        let fontSize = infoTextField2.font!.pointSize
        
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        stateAttributes = [.paragraphStyle: style, .foregroundColor: NSColor.red, .font: NSFont.boldSystemFont(ofSize: fontSize)]
        
        // Restore window frame
        if let frameString = repository?.userInfo(forKey: kRepositoryUserInfoKey_MainWindowFrame) as? NSWindow.PersistableFrameDescriptor {
            mainWindow.setFrame(from: frameString)
        }
        
        mainWindow.backgroundColor = .white
        mainWindow.toolbar = toolbar
        
        if #available(OSX 10.10, *) {
            mainWindow.titleVisibility = .hidden
        }
        
        contentView.wantsLayer = true
        leftView.wantsLayer = true
        titleView.wantsLayer = true
        rightView.wantsLayer = true
        
        // Text fields must be drawn on an opaque background to avoid subpixel antialiasing issues during animation.
        for field in [infoTextField1, infoTextField2, progressTextField] {
            field?.drawsBackground = true
            field?.backgroundColor = mainWindow.backgroundColor
        }
        
        mapViewController = GIMapViewController(repository: repository)
        mapViewController.delegate = self
        mapControllerView.replace(with: mapViewController.view)
        
        mapView.frame = mapContainerView.bounds
        mapContainerView.addSubview(mapView)
        assert(mapContainerView.subviews.first == mapView)
        
        _updateStatusBar()
        
        tagsViewController = GICommitListViewController(repository: repository)
        tagsViewController.delegate = self
        tagsViewController.emptyLabel = NSLocalizedString("No Tags", comment: "")
        tagsControllerView.replace(with: tagsViewController.view)
        
        snapshotListViewController = GISnapshotListViewController(repository: repository)
        snapshotListViewController.delegate = self
        snapshotsControllerView.replace(with: snapshotListViewController.view)
        
        unifiedReflogViewController = GIUnifiedReflogViewController(repository: repository)
        unifiedReflogViewController.delegate = self
        reflogControllerView.replace(with: unifiedReflogViewController.view)
        
        ancestorsViewController = GICommitListViewController(repository: repository)
        ancestorsViewController.delegate = self
        ancestorsControllerView.replace(with: ancestorsViewController.view)
        
        searchResultsViewController = GICommitListViewController(repository: repository)
        searchResultsViewController.delegate = self
        searchResultsViewController.emptyLabel = NSLocalizedString("No Results", comment: "")
        searchControllerView.replace(with: searchResultsViewController.view)
        
        quickViewController = GIQuickViewController(repository: repository)
        mainTabView.tabView(withIdentifier: WindowMode.mapQuickView)?.view = quickViewController.view
        
        diffViewController = GIDiffViewController(repository: repository)
        mainTabView.tabView(withIdentifier: WindowMode.mapDiff)?.view = diffViewController.view
        
        commitRewriterViewController = GICommitRewriterViewController(repository: repository)
        rewriteControllerView.replace(with: commitRewriterViewController.view)
        mainTabView.tabView(withIdentifier: WindowMode.mapRewrite)?.view = rewriteView
        
        commitSplitterViewController = GICommitSplitterViewController(repository: repository)
        commitSplitterViewController.delegate = self
        splitControllerView.replace(with: commitSplitterViewController.view)
        mainTabView.tabView(withIdentifier: WindowMode.mapSplit)?.view = splitView
        
        conflictResolverViewController = GIConflictResolverViewController(repository: repository)
        conflictResolverViewController.delegate = self
        resolveControllerView.replace(with: conflictResolverViewController.view)
        mainTabView.tabView(withIdentifier: WindowMode.mapResolve)?.view = resolveView
        
        if UserDefaults.standard.bool(forKey: kUserDefaultsKey_SimpleCommit) {
            commitViewController = GISimpleCommitViewController(repository: repository)
        } else {
            commitViewController = GIAdvancedCommitViewController(repository: repository)
        }
        commitViewController.delegate = self
        mainTabView.tabView(withIdentifier: WindowMode.commit)?.view = commitViewController.view
        
        stashListViewController = GIStashListViewController(repository: repository)
        mainTabView.tabView(withIdentifier: WindowMode.stashes)?.view = stashListViewController.view
        
        configViewController = GIConfigViewController(repository: repository)
        mainTabView.tabView(withIdentifier: WindowMode.mapConfig)?.view = configViewController.view
        
        hiddenWarningView.layer?.backgroundColor = NSColor(white: 0, alpha: 0.5).cgColor
        hiddenWarningView.layer?.cornerRadius = 10
        
        
        _setSearchField(placeholder: NSLocalizedString("Preparing Search…", comment: ""))
        searchField.isEnabled = false
        
        for item in showMenu.items where !item.isSeparatorItem {
            item.target = mapViewController
        }
        
        pullButton.target = mapViewController
        pushButton.target = mapViewController
        
        updateWindowMode(.map)
    }
    
    // Override -updateChangeCount: which is trigged by NSUndoManager to do nothing and not mark document as updated
    override func updateChangeCount(_ change: NSDocument.ChangeType) {
        
    }
    
    override func presentError(_ error: Error) -> Bool {
        let nsError = error as NSError
        
        if (nsError.domain == GCErrorDomain && nsError.code == GCErrorCode.userCancelled.rawValue) ||
            nsError.code == GCErrorCode.user.rawValue {
            return false
        }
        
        if nsError.domain == GCErrorDomain, nsError.code == -1, error.localizedDescription == "authentication required but no callback set" { // TODO: Avoid hardcoding libgit2 error
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Unable to authenticate with remote!", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.informativeText = NSLocalizedString("If using an SSH remote, make sure you have added your key to the ssh-agent, then try again.", comment: "")
            alert.setType(.stop)
            alert.beginSheetModal(for: mainWindow, withCompletionHandler: nil)
            return false
        }
        
        return super.presentError(error)
    }
    
    override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
        guard !shouldCloseDocument(),
            let nsDelegate = delegate as? NSObject,
            let closeSelector = shouldCloseSelector,
            let imp = nsDelegate.method(for: closeSelector) else {
                return super.canClose(withDelegate: delegate, shouldClose: shouldCloseSelector, contextInfo: contextInfo)
        }
        
        typealias CanCloseMethod = @convention(c) (Any, Selector?, UnsafeMutableRawPointer?) -> Void
        let delegateMethod = unsafeBitCast(imp, to: CanCloseMethod.self)
        delegateMethod(delegate, closeSelector, contextInfo)
    }
    
    
    
    
    
    func shouldCloseDocument() -> Bool {
        guard !windowController.hasModalView else {
            NSSound.beep()
            return false
        }
        
        guard ![.mapRewrite, .mapSplit, .mapResolve].contains(windowMode) else {
            windowController.showOverlay(with: .warning, message: NSLocalizedString("You must finish or cancel before closing the repository", comment: ""))
            return false
        }
        
        if repository?.hasBackgroundOperationInProgress == true {
            windowController.showOverlay(with: .warning, message: NSLocalizedString("The repository cannot be closed while a remote operation is in progress", comment: ""))
            return false
        }
        
        if indexing {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Are you sure you want to close the repository?", comment: "")
            alert.informativeText = String(format: NSLocalizedString("The repository \"%@\" is still being prepared for search. This can take up to a few minutes for large repositories.", comment: ""), displayName)
            alert.addButton(withTitle: NSLocalizedString("Close", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
            alert.setType(.caution)
            
            if alert.runModal() == .alertSecondButtonReturn {
                return false
            }
            abortIndexing = true
        }

        return true
    }
    
    @IBAction
    func checkForChanges(_ sender: Any!) {
        assert(repository != nil)
        guard let repository = repository else { return } // Not sure how this can happen but it has in the field
        
        CFRunLoopTimerSetNextFireDate(checkTimer, .greatestFiniteMagnitude)
        checkingForChanges = true
        let path = repository.repositoryPath // Avoid race-condition in case _repository is set to nil before block is executed
        
        let queue: DispatchQueue
        if #available(OSX 10.10, *) {
            queue = DispatchQueue.global(qos: .default)
        } else {
            queue = DispatchQueue.global(priority: .default)
        }
        
        queue.async {
            
            do {
                let repo = try GCRepository(existingLocalRepository: path)
//                repository.delegate = (id<GCRepositoryDelegate>)self.class;  // Don't use self as we don't want to show progress UI nor authentication prompts
                let remotes = try repo.listRemotes() as! [GCRemote]
                var updatedReferences: [String: String] = [:]
                
                for remote in remotes {
                    try autoreleasepool {
                        var added: NSDictionary?
                        var modified: NSDictionary?
                        var deleted: NSDictionary?
                        try repo.checkForChanges(in: remote, with: .includeBranches, addedReferences: &added, modifiedReferences: &modified, deletedReferences: &deleted)
                        for update in [added, modified, deleted] as! [[String: String]] {
                            for (key, value) in update {
                                updatedReferences[key] = value
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    guard let _ = self.repository else { return debugPrint("Remote check completed after document was closed") }
                    
                    self.updatedReferences = updatedReferences
                    if !updatedReferences.isEmpty {
                        self.windowController.showOverlay(with: .informational, message: NSLocalizedString("New commits are available from the repository remotes - Use Fetch to retrieve them", comment: ""))
                        debugPrint("Repository is out-of-sync with its remotes: %@", updatedReferences.keys)
                    } else {
                        if let _ = sender {
                            self.windowController.showOverlay(with: .informational, message: NSLocalizedString("Repository is up-to-date", comment: ""))
                        }
                        debugPrint("Repository is up-to-date with its remotes")
                    }
                    
                    self.checkingForChanges = false
                    self._resetCheckTimer()
                    self._updateStatusBar()
                }
            } catch {
                
            }
        }
    }
    
    @IBAction
    func dismissHelp(_ sender: Any!) {
        hideHelp(false)
    }
    
    @IBAction
    func openHelp(_ sender: Any!) {
        hideHelp(true)
    }
    
    @IBAction
    func openSubmoduleMenu(_ sender: Any!) {
        assertionFailure() // This action only exists to populate the menu in -validateUserInterfaceItem:
    }
    
    @IBAction
    func openSubmodule(_ sender: Any!) {
        if let menuItem = sender as? NSMenuItem, let path = menuItem.representedObject as? String {
            mapViewController.openSubmodule(withApp: path)
        }
    }
    
    @IBAction
    func editSettings(_ sender: Any!) {
        #warning("Debug behaviour, complete implementation")
//        indexDiffsButton.state =
        let indexDiffs = (repository?.userInfo(forKey: kRepositoryUserInfoKey_IndexDiffs) as? Bool) ?? false
        
        NSApp.beginSheet(settingsWindow, modalFor: mainWindow, modalDelegate: nil, didEnd: nil, contextInfo: nil)
    }
    
    @IBAction
    func saveSettings(_ sender: Any!) {
        NSApp.endSheet(settingsWindow)
        settingsWindow.orderOut(nil)
        
//        repository?.setUserInfo(<#T##info: Any!##Any!#>, forKey: <#T##String!#>)
    }
    
    @IBAction
    func openInHostingService(_ sender: Any!) {
        do {
            if let url = try repository?.hostingURL(forProject: nil) {
                NSWorkspace.shared.open(url)
            }
        } catch {
            _ = presentError(error)
        }
    }
    
    @IBAction
    func openInTerminal(_ sender: Any!) {
        assert(repository != nil)
        guard let repository = repository else { return }
        
        let script = String(format: "tell application \"Terminal\" to do script \"cd \\\"%@\\\"\"", repository.workingDirectoryPath)
        NSAppleScript(source: script)?.executeAndReturnError(nil)
        NSWorkspace.shared.launchApplication("Terminal")
    }
    
    @IBAction
    func openInFinder(_ sender: Any!) {
        assert(repository != nil)
        guard let repository = repository else { return }
        
        NSWorkspace.shared.open(URL(fileURLWithPath: repository.workingDirectoryPath, isDirectory: true))
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        if item.action == #selector(editSettings(_:)) {
            return true
        }
        
        if item.action == #selector(openInTerminal(_:)) || item.action == #selector(openInFinder(_:)) {
            return true
        }
        
        if item.action == #selector(openInHostingService(_:)) {
            do {
                var service: GCHostingService = .unknown
                try repository!.hostingURL(forProject: &service)
                switch service {
                case .unknown:
                    if let menuItem = item as? NSMenuItem {
                        menuItem.title = NSLocalizedString("Open in Hosting Service…", comment: "")
                    }
                    return false // Must match title in the NIB
                default:
                    if let menuItem = item as? NSMenuItem, let serviceName = service.name {
                        menuItem.title = String(format: NSLocalizedString("Open in %@…", comment: ""), serviceName)
                    }
                    return true
                }
            } catch {
                _ = presentError(error)
            }
        }
        
        if item.action == #selector(openSubmoduleMenu(_:)) {
            assert(item is NSMenuItem)
            
            let submenu = (item as! NSMenuItem).submenu
            submenu?.removeAllItems()
            
            if case let submodules?? = try? repository?.listSubmodules() as? [GCSubmodule], submodules.count > 0 {
                for submodule in submodules {
                    let menuItem = NSMenuItem(title: submodule.name, action: #selector(openSubmodule(_:)), keyEquivalent: "")
                    menuItem.representedObject = submodule.name // Don't use "submodule" to avoid retaining it forever
                    menuItem.target = self
                    submenu?.addItem(menuItem)
                }
            } else {
                submenu?.addItem(withTitle: NSLocalizedString("No Submodules in Repository", comment: ""), action: nil, keyEquivalent: "")
            }
            
            return true
        }
        
        guard !windowController.hasModalView else { return false }
        
        switch item.action {
        case #selector(focusSearch(_:)), #selector(performSearch(_:)):
            return windowMode == .map && tagsView.superview == nil && snapshotsView.superview == nil && reflogView.superview == nil && ancestorsView.superview == nil && searchReady
        case #selector(toggleTags(_:)):
            return windowMode == .map && searchView.superview == nil && snapshotsView.superview == nil && reflogView.superview == nil && ancestorsView.superview == nil
        case #selector(toggleSnapshots(_:)):
            return windowMode == .map && searchView.superview == nil && tagsView.superview == nil && reflogView.superview == nil && ancestorsView.superview == nil && repository!.snapshots.count > 0
        case #selector(toggleReflog(_:)):
            return windowMode == .map && searchView.superview == nil && tagsView.superview == nil && snapshotsView.superview == nil && ancestorsView.superview == nil
        case #selector(toggleAncestors(_:)):
            return windowMode == .map && searchView.superview == nil && tagsView.superview == nil && snapshotsView.superview == nil && reflogView.superview == nil && repository!.history.headCommit != nil
        default: break
        }
        
        if let repository = repository, repository.hasBackgroundOperationInProgress {
            return false
        }
        
        switch item.action {
        case #selector(resetHard(_:)):
            return repository!.history.headCommit != nil
        case #selector(switchMode(_:)):
            guard ![.mapQuickView, .mapDiff, .mapRewrite, .mapConfig, .mapResolve].contains(windowMode) else { return false }
            if let menuItem = item as? NSMenuItem {
                let equalTab = menuItem.tag == windowMode.tab.index
                menuItem.state = equalTab ? .on : .off
            }
            return true
        case #selector(selectPreviousCommit(_:)):
            return windowMode == .mapQuickView && hasPreviousQuickView()
        case #selector(selectNextCommit(_:)):
            return windowMode == .mapQuickView && hasNextQuickView()
        case #selector(checkForChanges(_:)):
            return checkingForChanges
        case #selector(editConfiguration(_:)):
            return windowMode == .map
        default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    @IBAction
    func resetHard(_ sender: Any!) {
        untrackedButton.state = .off
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Are you sure you want to reset the index and working directory to the current checkout?", comment: "")
        alert.informativeText = NSLocalizedString("Any operation in progress (merge, rebase, etc...) will be aborted, and any uncommitted change, including in submodules, will be discarded.\n\nThis action cannot be undone.", comment: "")
        alert.accessoryView = resetView
        alert.addButton(withTitle: NSLocalizedString("Reset", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.setType(.stop)
        
        alert.beginSheetModal(for: mainWindow) { (response: NSApplication.ModalResponse) in
            guard response == .alertFirstButtonReturn, let repository = self.repository else { return }
            do {
                try repository.reset(toHEAD: .hard)
                #warning("WTF? What should I do with this?")
            } catch {
                
            }
        }
    }
    
    func add(sideView: NSView, identifier: String, completion: (() -> Void)?) {
        let contentFrame = mapContainerView.bounds
        let mapFrame = mapView.frame
        let viewFrame = sideView.frame
        let newMapFrame = NSMakeRect(0, mapFrame.origin.y, contentFrame.width - viewFrame.width, mapFrame.height)
        let newViewFrame = NSMakeRect(contentFrame.width - viewFrame.width, mapFrame.origin.y, viewFrame.width, mapFrame.height)
        
        sideView.frame = newViewFrame.offsetBy(dx: viewFrame.width, dy: 0)
        mapContainerView.addSubview(sideView, positioned: .above, relativeTo: mapView)
        
        if (false) { // TODO: On 10.13, the first time the view is shown after animating, it is completely empty
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = Document2.sideViewAnimationDuration
            NSAnimationContext.current.completionHandler = completion
            mapView.animator().frame = newMapFrame
            sideView.animator().frame = newViewFrame
            NSAnimationContext.endGrouping()
        } else {
            mapView.frame = newMapFrame
            sideView.frame = newViewFrame
            completion?()
        }
        
        _updateToolbar()
        showHelp(with: identifier)
    }
    
    func remove(sideView: NSView, completion: (() -> Void)?) {
        let contentFrame = mapContainerView.bounds
        let mapFrame = mapView.frame
        let newMapFrame = NSMakeRect(0, mapFrame.origin.y, contentFrame.width, mapFrame.height)
        let viewFrame = sideView.frame
        let newViewFrame = viewFrame.offsetBy(dx: viewFrame.width, dy: 0)
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = Document2.sideViewAnimationDuration
        NSAnimationContext.current.completionHandler = completion
        mapView.animator().frame = newMapFrame
        sideView.animator().frame = newViewFrame
        NSAnimationContext.endGrouping()
        
        showHelp(with: windowMode.tabIdentifier)
    }
    
    func reloadTagsView() {
        tagsViewController.results = repository?.history.tags // TODO: Should we resort the tags?
        
        preventSelectionLoopback = true
        tagsViewController.selectedCommit = mapViewController.selectedCommit
        preventSelectionLoopback = false
    }
    
    @IBAction
    func toggleTags(_ sender: Any!) {
        if let _ = tagsView.superview {
            remove(sideView: tagsView, completion: {
                self.tagsViewController.results = nil
            })
            hiddenWarningView.isHidden = true // Hide immediately
            mainWindow.makeFirstResponder(mapViewController.preferredFirstResponder)
        } else {
            reloadTagsView()
            
            mainWindow.makeFirstResponder(nil) // Force end-editing in search field to avoid close button remaining around
            add(sideView: tagsView, identifier: SideView.tags.helpIdentifier, completion: nil)
            mainWindow.makeFirstResponder(tagsViewController.preferredFirstResponder)
        }
    }
    
    @IBAction
    func toggleSnapshots(_ sender: Any!) {
        if let _ = snapshotsView.superview {
            mapViewController.previewHistory = nil
            remove(sideView: snapshotsView, completion: nil)
            mainWindow.makeFirstResponder(mapViewController.preferredFirstResponder)
        } else {
            mainWindow.makeFirstResponder(nil) // Force end-editing in search field to avoid close button remaining around
            add(sideView: snapshotsView, identifier: SideView.snapshots.helpIdentifier, completion: nil)
            mainWindow.makeFirstResponder(snapshotListViewController.preferredFirstResponder)
        }
    }
    
    @IBAction
    func toggleReflog(_ sender: Any!) {
        if let _ = reflogView.superview {
            mapViewController.forceShowAllTips = false
            remove(sideView: reflogView, completion: nil)
            mainWindow.makeFirstResponder(mapViewController.preferredFirstResponder)
        } else {
            mainWindow.makeFirstResponder(nil) // Force end-editing in search field to avoid close button remaining around
            mapViewController.forceShowAllTips = true
            add(sideView: reflogView, identifier: SideView.reflog.helpIdentifier, completion: nil)
            mainWindow.makeFirstResponder(unifiedReflogViewController.preferredFirstResponder)
        }
    }
    
    func reloadAncestorsView() {
        assert(repository != nil)
        guard let repository = repository else { return }
        
        var commits = [repository.history.headCommit!]
        repository.history.walkAncestors(ofCommits: [repository.history.headCommit],
                                         using: { (commit, stopPointer) in
                                            if let commit = commit {
                                                commits.append(commit)
                                            }
                                            if commits.count == .maximumAncestorCommitsCount {
                                                stopPointer?.pointee = ObjCBool(true)
                                            }
        })
    }
    
    
    @IBAction
    func switchMode(_ sender: Any!) {
        if let menuItem = sender as? NSMenuItem, let mode = WindowMode(tag: menuItem.tag) {
            updateWindowMode(mode)
        } else if let mode = WindowMode(tag: modeControl.selectedSegment) {
            updateWindowMode(mode)
        }
    }
    
    @IBAction
    func toggleAncestors(_ sender: Any!) {
        if let _ = ancestorsView.superview {
            remove(sideView: ancestorsView, completion: {
                self.ancestorsViewController.results = nil
            })
            hiddenWarningView.isHidden = true // Hide immediately
            mainWindow.makeFirstResponder(mapViewController.preferredFirstResponder)
        } else {
            reloadAncestorsView()
            
            mainWindow.makeFirstResponder(nil) // Force end-editing in search field to avoid close button remaining around
            add(sideView: ancestorsView, identifier: SideView.ancestors.helpIdentifier, completion: nil)
            mainWindow.makeFirstResponder(ancestorsViewController.preferredFirstResponder)
        }
    }
    
    @IBAction
    func editConfiguration(_ sender: Any!) {
        enterConfig()
    }
    
    func _setSearchField(placeholder: String) {
        var correctedPlaceholder: String
        
        // 10.11 and earlier: search placeholders have the same length to work around incorrect centering.
        if #available(OSX 10.12, *) {
            // Workaround is not needed
            correctedPlaceholder = placeholder
        } else {
            correctedPlaceholder = placeholder.padding(toLength: 18, withPad: " ", startingAt: 0)
        }
        
        if let searchTextField = searchField.cell as? NSTextFieldCell {
            searchTextField.placeholderString = correctedPlaceholder
        }
        
        // 10.12: there are more centering issues, and all are fixed by triggering a layout pass.
        if #available(OSX 10.12, *) {
            searchField.needsLayout = true
        }
    }
    
    @IBAction
    func performSearch(_ sender: Any!) {
        assert(repository != nil)
        guard let repository = repository else { return }
        
        let query = searchField.stringValue
        
        if !query.isEmpty {
            let time = CFAbsoluteTimeGetCurrent()
            let results = repository.findCommits(matching: query)
            
            
            debugPrint("Searched %lu commits in \"%@\" for \"%@\" in %.3f seconds finding %lu matches", repository.history.allCommits.count, repository.repositoryPath, searchField.stringValue, CFAbsoluteTimeGetCurrent() - time, results?.count ?? 0)
            
            searchResultsViewController.results = results
            if searchView.superview == nil {
                add(sideView: searchView, identifier: SideView.search.helpIdentifier, completion: nil)
            }
        } else {
            if let _ = searchView.superview {
                hiddenWarningView.isHidden = true
                remove(sideView: searchView, completion: {
                    self.searchResultsViewController.results = nil
                })
            }
            mainWindow.makeFirstResponder(mapViewController.preferredFirstResponder)
        }
    }
    
    @IBAction
    func focusSearch(_ sender: Any!) {
        mainWindow.makeFirstResponder(searchField)
    }
    
    @IBAction
    func closeSearch(_ sender: Any!) {
        searchField.stringValue = ""
        performSearch(nil)
    }
    
    @IBAction
    func exit(_ sender: Any!) {
        switch windowMode! {
        case .mapQuickView:
            exitQuickView()
        case .mapDiff:
            exitDiff()
        case .mapConfig:
            exitConfig()
        default: assertionFailure()
        }
    }
    
    @IBAction
    func selectPreviousCommit(_ sender: Any!) {
        previousQuickView()
    }
    
    @IBAction
    func selectNextCommit(_ sender: Any!) {
        nextQuickView()
    }
}

extension Int {
    static let maximumAncestorCommitsCount = 1000
}

extension GCHostingService {
    var name: String? {
        switch self {
        case .bitBucket: return "BitBucket"
        case .gitHub: return "GitHub"
        case .gitLab: return "GitLab"
        case .unknown: return nil
        }
    }
}

extension NSTabView {
    func tabView(withIdentifier identifier: Any) -> NSTabViewItem? {
        let index = indexOfTabViewItem(withIdentifier: identifier)
        guard index != NSNotFound else { return nil }
        return tabViewItem(at: index)
    }
}

extension NumberFormatter {
    func string(from commitCount: Int) -> String {
        switch commitCount {
        case 0:
            return NSLocalizedString("0 commits", comment: "")
        case 1:
            return NSLocalizedString("1 commit", comment: "")
        default:
            return String(format: NSLocalizedString("%@ commits", comment: ""), string(from: commitCount as NSNumber)!)
        }
    }
}

extension GCRepositoryState {
    var stringValue: String? {
        switch self {
        case .none:
            return nil
        case .merge:
            return NSLocalizedString("merge", comment: "")
        case .revert:
            return NSLocalizedString("revert", comment: "")
        case .cherryPick:
            return NSLocalizedString("cherry-pick", comment: "")
        case .bisect:
            return NSLocalizedString("bisect", comment: "")
        case .rebase, .rebaseInteractive, .rebaseMerge:
            return NSLocalizedString("rebase", comment: "")
        case .applyMailbox, .applyMailboxOrRebase:
            return NSLocalizedString("apply mailbox", comment: "")
        }
    }
}

private extension Document2 {
    @objc
    func _didBecomeActive(_ notification: Notification) {
        repository?.notifyWorkingDirectoryChanged() // Make sure we are up-to-date right now
        
        if repository?.areAutomaticSnapshotsEnabled == true {
            repository?.setUndoActionName(NSLocalizedString("External Changes", comment: ""))
            repository?.areAutomaticSnapshotsEnabled = false
        }
        
        _updateToolbar()
    }
    
    @objc
    func _didResignActive(_ notification: Notification) {
        // Don't take automatic snapshots while conflict resolver is on screen
        if windowMode != .mapResolve {
            repository?.areAutomaticSnapshotsEnabled = true
        }
        _updateToolbar()
    }
    
    func _resetCheckTimer() {
        let checkInterval = UserDefaults.standard.checkInterval
        guard checkInterval > 0 else { return }
        
        CFRunLoopTimerSetNextFireDate(checkTimer, CFAbsoluteTimeGetCurrent() + checkInterval)
    }
    
    func performClone(using remote: GCRemote, recursive isRecursive: Bool) {
        assert(repository != nil)
        guard let repository = repository else { return }
        
        repository.setUndoActionName(NSLocalizedString("Clone", comment: ""))
        repository.suspendHistoryUpdates()
        repository.performOperationInBackground(withReason: "clone",
                                                argument: nil,
                                                usingOperationBlock: { (repo, outError) -> Bool in
                                                    do {
                                                        try repo!.clone(using: remote, recursive: isRecursive)
                                                        return true
                                                    } catch {
                                                        outError?.pointee = error as NSError
                                                        return false
                                                    }
        }, completionBlock: { (_, error) in
            repository.resumeHistoryUpdates()
            if let error = error {
                _ = self.presentError(error)
            }
            
            self._prepareSearch()
            self._resetCheckTimer()
        })
    }
    
    func _initializeSubmodules() {
        repository?.performOperationInBackground(withReason: nil,
                                                 argument: nil,
                                                 usingOperationBlock: { (repo, outError) -> Bool in
                                                    do {
                                                        try repo!.initializeAllSubmodules(true)
                                                        return true
                                                    } catch {
                                                        outError?.pointee = error as NSError
                                                        return false
                                                    }
        }, completionBlock: { (success, error) in
            if let error = error {
                _ = self.presentError(error)
            }
            
            self._resetCheckTimer()
        })
    }
    
    
    func _prepareSearch() {
        assert(repository != nil)
        guard let repository = repository else { return }
        
        indexing = true
        abortIndexing = false
        ProcessInfo.processInfo.disableSuddenTermination()
        
        let commitsCount = repository.history.allCommits.count
        var lastProgress: Double = 0
        var lastTime: CFAbsoluteTime = 0
        
        let runInBackground = repository.userInfo(forKey: kRepositoryUserInfoKey_IndexDiffs) as? Bool
        repository.prepareSearch(inBackground: runInBackground ?? false,
                                 withProgressHandler: { (isFirstUpdate, addedCommits, removedCommits) -> Bool in
                                    guard isFirstUpdate else { return !self.abortIndexing }
                                    
                                    let progress = min(round((1000 * Double(addedCommits) / Double(commitsCount) / 10)), 100)
                                    guard progress > lastProgress else { return !self.abortIndexing }
                                    
                                    let time = CFAbsoluteTimeGetCurrent()
                                    guard time > lastTime + 1/Document2.maxProgressRefreshRate else { return !self.abortIndexing }
                                    
                                    DispatchQueue.main.async {
                                        if progress >= 100 {
                                            self._setSearchField(placeholder: NSLocalizedString("Finishing…", comment: ""))
                                        } else {
                                            self._setSearchField(placeholder: String(format: "%@", NSLocalizedString("Preparing (%.1f%%)…", comment: ""), progress))
                                        }
                                    }
                                    
                                    lastProgress = progress
                                    lastTime = time
                                    
                                    return !self.abortIndexing
        },
                                 completion: { (success, error) in
                                    guard !self.abortIndexing else { return }
                                    // If indexing has been aborted, this means the document has already been closed, so don't attempt to do *anything*
                                    
                                    if success {
                                        self.searchReady = true
                                        self._setSearchField(placeholder: NSLocalizedString("Search Repository…", comment: ""))
                                        self.searchField.isEnabled = true
                                    } else {
                                        self._setSearchField(placeholder: NSLocalizedString("Search Unavailable", comment: ""))
                                        
                                        if let error = error {
                                            _ = self.presentError(error)
                                        }
                                    }
                                    ProcessInfo.processInfo.enableSuddenTermination()
                                    self.indexing = false
        })
    }
    
    // TODO: Search field placeholder strings must all be about the same length since NSSearchField doesn't recenter updated placeholder strings properly
    func _documentDidOpen(_ restored: Any!) {
        assert(mainWindow.isVisible)
        assert(repository != nil)
        guard let repository = repository else { return }
        
        // Work around a bug of NSSearchField which is always enabled after restoration even if set to disabled during restoration
        _updateToolbar()
        
        // Check if a clone is needed
        if cloneMode != .none {
            assert(repository.isEmpty && restored == nil)
            do {
                let remote = try repository.lookupRemote(withName: "origin")
                performClone(using: remote, recursive: cloneMode == .recursive)
            } catch {
                _ = presentError(error)
                return
            }
        }
        
        _prepareSearch()
        
        // Check for uninitialized submodules
        let skipSubmoduleCheck = (repository.userInfo(forKey: kRepositoryUserInfoKey_SkipSubmoduleCheck) as? Bool) ?? false
        if restored != nil, skipSubmoduleCheck {
            var error: NSError?
            if !repository.checkAllSubmodulesInitialized(true, error: &error) {
                guard let actualError = error,
                    actualError.domain == GCErrorDomain, actualError.code == GCErrorCode.submoduleUninitialized.rawValue else {
                        if let error = error {
                            _ = presentError(error)
                        }
                        return
                }
                
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Do you want to initialize submodules?", comment: "")
                alert.informativeText = NSLocalizedString("One or more submodules in this repository are uninitialized.", comment: "")
                alert.addButton(withTitle: NSLocalizedString("Initialize", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                alert.setType(.caution)
                alert.showsSuppressionButton = true
                
                alert.beginSheetModal(for: mainWindow) { (response: NSApplication.ModalResponse) in
                    switch response {
                    case NSApplication.ModalResponse.alertFirstButtonReturn:
                        self._initializeSubmodules()
                    case NSApplication.ModalResponse.alertSecondButtonReturn:
                        repository.setUserInfo(true, forKey: kRepositoryUserInfoKey_SkipSubmoduleCheck)
                    
                    default: break
                    }
                }
                
                return
            }
            
        }
        
        if !UserDefaults.standard.checkInterval.isZero {
            checkForChanges(nil)
        }
        
    }
    
    func _updateTitleBar() {
        assert(repository != nil)
        guard let repository = repository else { return }
        
        windowController.synchronizeWindowTitleWithDocumentName()
        infoTextField0.stringValue = numberFormatter.string(from: repository.history.allCommits.count)
    }
    
    func _updateStatusBar() {
        if mapViewController.previewHistory != nil {
            infoTextField1.font = .boldSystemFont(ofSize: 11)
            infoTextField1.stringValue = NSLocalizedString("Snapshot Preview", comment: "")
            if let date = snapshotListViewController.selectedSnapshot.date() {
                infoTextField2.stringValue = dateFormatter.string(from: date)
            } else {
                infoTextField2.stringValue = NSLocalizedString("No snapshot selected", comment: "")
            }
            pullButton.isHidden = true
            pushButton.isHidden = true
            return
        }
        
        assert(repository != nil)
        guard let repository = repository else { return }
        
        var isBehind = false
        let state = repository.state.stringValue?.appending(NSLocalizedString(" in progress", comment: ""))
        let stateAttributedString = state.map({ NSAttributedString(string: $0, attributes: self.stateAttributes) })
        
        if repository.history.isHEADDetached {
            infoTextField1.font = .boldSystemFont(ofSize: 11)
            infoTextField1.stringValue = NSLocalizedString("Not on any branch", comment: "")
            
            if let stateAttributedString = stateAttributedString {
                infoTextField2.attributedStringValue = stateAttributedString
            } else if let headCommit = repository.history.headCommit {
                infoTextField2.stringValue = String(format: NSLocalizedString("Detached HEAD at commit %@", comment: ""), headCommit.shortSHA1)
            } else {
                infoTextField2.stringValue = NSLocalizedString("Repository is empty", comment: "")
            }
        } else {
            let branch = repository.history.headBranch!
            
            if let upstream = branch.upstream as? GCHistoryLocalBranch {
                let fontSize = infoTextField1.font!.pointSize
                let string = NSMutableAttributedString()
                
                string.beginEditing()
                string.append(.init(string: NSLocalizedString("On branch ", comment: ""), attributes: [.font: NSFont.systemFont(ofSize: fontSize)]))
                string.append(.init(string: branch.name, attributes: [.font: NSFont.boldSystemFont(ofSize: fontSize)]))
                string.append(.init(string: NSLocalizedString(" • tracking upstream ", comment: ""), attributes: [.font: NSFont.systemFont(ofSize: fontSize)]))
                string.append(.init(string: upstream.name, attributes: [.font: NSFont.boldSystemFont(ofSize: fontSize)]))
                string.setAlignment(.center, range: NSMakeRange(0, string.length))
                string.endEditing()
                
                infoTextField1.attributedStringValue = string
                
                if let stateAttributedString = stateAttributedString {
                    infoTextField2.attributedStringValue = stateAttributedString
                } else {
                    let localTip = repository.history.headCommit!
                    let upstreamTip = upstream.tipCommit!
                    
                    if localTip.isEqual(to: upstreamTip) {
                        infoTextField2.stringValue = NSLocalizedString("Up-to-date", comment: "")
                    } else {
                        let commit = try? repository.findMergeBase(forCommits: [localTip, upstreamTip])
                        
                        if let ancestor = commit.flatMap({ repository.history.historyCommit(for: $0) }) {
                            if ancestor.isEqual(to: localTip) {
                                let commitsCount = repository.history.countAncestorCommits(from: upstreamTip, to: localTip)
                                infoTextField2.stringValue = String(format: NSLocalizedString(" %@ behind", comment: ""), numberFormatter.string(from: Int(commitsCount)))
                                isBehind = true
                            } else if ancestor.isEqual(to: upstreamTip) {
                                let commitsCount = repository.history.countAncestorCommits(from: localTip, to: upstreamTip)
                                infoTextField2.stringValue = String(format: NSLocalizedString(" %@ ahead", comment: ""), numberFormatter.string(from: Int(commitsCount)))
                            } else {
                                let aheadCount = repository.history.countAncestorCommits(from: localTip, to: upstreamTip)
                                let behindCount = repository.history.countAncestorCommits(from: upstreamTip, to: localTip)
                                infoTextField2.stringValue = String(format: NSLocalizedString(" %@ ahead, %@ behind", comment: ""), numberFormatter.string(from: Int(aheadCount)), numberFormatter.string(from: Int(behindCount)))
                                isBehind = true
                            }
                        } else {
                            infoTextField2.stringValue = ""
                            assertionFailure()
                        }
                    }
                }
                
                //
                if let upstreamSHA1 = updatedReferences?[upstream.fullName], upstreamSHA1 != upstream.tipCommit.sha1 {
                    isBehind = true
                }
            } else {
                // upstream == nil
                
                let fontSize = infoTextField1.font!.pointSize
                let string = NSMutableAttributedString()
                
                string.beginEditing()
                string.append(.init(string: NSLocalizedString("On branch ", comment: ""), attributes: [.font: NSFont.systemFont(ofSize: fontSize)]))
                string.append(.init(string: branch.name, attributes: [.font: NSFont.boldSystemFont(ofSize: fontSize)]))
                string.setAlignment(.center, range: NSMakeRange(0, string.length))
                string.endEditing()
                
                infoTextField1.attributedStringValue = string
                
                if let stateAttributedString = stateAttributedString {
                    infoTextField2.attributedStringValue = stateAttributedString
                } else {
                    infoTextField2.stringValue = NSLocalizedString("No upstream configured", comment: "")
                }
                
            }
        }
        
        pullButton.isHidden = false
        pullButton.isEnabled = mapViewController.validateUserInterfaceItem(pullButton)
        let frame = pullButton.frame
        if isBehind {
            pullButton.image = NSImage(named: "icon_action_fetch_new")
            pullButton.frame.origin = CGPoint(x: frame.origin.x + frame.width - 44, y: frame.origin.y)
            pullButton.frame.size = CGSize(width: 44, height: frame.size.height)
        } else {
            pullButton.image = NSImage(named: "icon_action_fetch")
            pullButton.frame.origin = CGPoint(x: frame.origin.x + frame.width - 27, y: frame.origin.y)
            pullButton.frame.size = CGSize(width: 27, height: frame.size.height)
        }
        
        pushButton.isHidden = false
        pushButton.isEnabled = mapViewController.validateUserInterfaceItem(pushButton)
    }
    
    // NSToolbar automatic validation fires very often and at unpredictable times so we just do everything by hand
    func _updateToolbar() {
        if WindowMode.mapChilds.contains(windowMode) {
            modeControl.isHidden = true
            
            if let _ = quickViewCommits {
                previousButton.isHidden = false
                previousButton.isEnabled = validateUserInterfaceItem(previousButton)
                nextButton.isHidden = false
                nextButton.isEnabled = validateUserInterfaceItem(nextButton)
            } else {
                previousButton.isHidden = true
                nextButton.isHidden = true
            }
            
            snapshotsButton.isHidden = true
            searchField.isHidden = true
            exitButton.isHidden = [.mapRewrite, .mapSplit, .mapResolve].contains(windowMode)
        } else {
            modeControl.isHidden = false
            modeControl.isEnabled = !windowController.hasModalView && !repository!.hasBackgroundOperationInProgress
            previousButton.isHidden = true
            nextButton.isHidden = true
            
            if windowMode == .map {
                snapshotsButton.isHidden = false
                if !validateUserInterfaceItem(snapshotsButton) {
                    snapshotsButton.image = NSImage(named: "icon_nav_snapshot_disable")
                    snapshotsButton.alternateImage = NSImage(named: "icon_nav_snapshot_disable")
                    snapshotsButton.isEnabled = false
                } else if let _ = snapshotsView.superview {
                    snapshotsButton.image = NSImage(named: "icon_nav_snapshot_active")
                    snapshotsButton.alternateImage = NSImage(named: "icon_nav_snapshot_active_pressed")
                    snapshotsButton.isEnabled = true
                } else {
                    snapshotsButton.image = NSImage(named: "icon_nav_snapshot")
                    snapshotsButton.alternateImage = NSImage(named: "icon_nav_snapshot_pressed")
                    snapshotsButton.isEnabled = true
                }
                searchField.isHidden = false
                searchField.isEnabled = validateUserInterfaceItem(searchField)
            } else {
                snapshotsButton.isHidden = true
                searchField.isHidden = true
            }
            exitButton.isHidden = true
        }
        
    }
    
    func updateWindowMode(_ mode: WindowMode) {
        guard windowMode != mode else { return }
        
        if windowMode == .map {
            if mainWindow.firstResponder?.isKind(of: NSWindow.self) == false {
                savedFirstResponder = mainWindow.firstResponder
            } else {
                savedFirstResponder = nil
            }
        }
        
        windowMode = mode
        
        mainTabView.selectTabViewItem(withIdentifier: windowMode.tabIdentifier)
        modeControl.selectSegment(withTag: windowMode.tab.index)
        
        // Don't let AppKit guess / restore first responder
        switch mode {
        case .map:
            mainWindow.makeFirstResponder(savedFirstResponder ?? mapViewController.preferredFirstResponder)
        case .mapRewrite:
            mainWindow.makeFirstResponder(commitRewriterViewController.preferredFirstResponder)
        case .mapSplit:
            mainWindow.makeFirstResponder(commitSplitterViewController.preferredFirstResponder)
        case .mapResolve:
            mainWindow.makeFirstResponder(conflictResolverViewController.preferredFirstResponder)
        default:
            let viewController = (mainTabView.selectedTabViewItem?.view as? GIView)?.viewController
            mainWindow.makeFirstResponder(viewController?.preferredFirstResponder)
        }
        
        _updateTitleBar()
        _updateToolbar()
        
        if mode == .map {
            if let _ = searchView.superview {
                showHelp(with: SideView.search.helpIdentifier)
            } else if let _ = tagsView.superview {
                showHelp(with: SideView.tags.helpIdentifier)
            } else if let _ = snapshotsView.superview {
                showHelp(with: SideView.snapshots.helpIdentifier)
            } else if let _ = reflogView.superview {
                showHelp(with: SideView.reflog.helpIdentifier)
            } else if let _ = ancestorsView.superview {
                showHelp(with: SideView.ancestors.helpIdentifier)
            } else {
                #warning("Improve help identifier types")
                showHelp(with: "map")
            }
        }
    }
    
    @discardableResult
    func updateWindowModeTab(_ tab: WindowMode.Tab) -> Bool {
        if mainWindow.attachedSheet == nil, !modeControl.isHidden, modeControl.isEnabled {
            updateWindowMode(tab.mode)
            return true
        }
        return false
    }
    
    func showHelp(with identifier: String){
        #warning("Not implemented yet")
    }
    
    func hideHelp(_ shouldOpenURL: Bool) {
        
    }
    
    func loadMoreAncestors() {
        assert(quickViewAncestors != nil)
        guard let quickViewAncestors = quickViewAncestors else { return }
        
        let success = quickViewAncestors.iterate { (commit, _) in
            commit.map({ self.quickViewCommits?.append($0) })
        }
        if !success {
            self.quickViewAncestors = nil
        }
    }
    
    func loadMoreDescendats() {
        assert(quickViewDescendants != nil)
        guard let quickViewDescendants = quickViewDescendants else { return }
        
        let success = quickViewDescendants.iterate { (commit, _) in
            commit.map({ self.quickViewCommits?.insert($0, at: 0) })
            self.quickViewIndex += 1
        }
        
        if !success {
            self.quickViewDescendants = nil
        }
    }
    
    func enterQuickView(with commit: GCHistoryCommit, commitList: [GCHistoryCommit]?) {
        repository?.suspendHistoryUpdates() // We don't want the the history to change while in QuickView because of the walkers
        
        quickViewCommits = []
        
        if let commitList = commitList {
            quickViewCommits?.append(contentsOf: commitList)
            if let index = quickViewCommits?.index(of: commit) {
                quickViewIndex = index
            } else {
                assertionFailure()
            }
        } else {
            quickViewCommits?.append(commit)
            quickViewIndex = 0
            
            quickViewAncestors = repository?.history.walkerForAncestors(ofCommits: [commit])
            loadMoreAncestors()
            
            quickViewDescendants = repository?.history.walkerForDescendants(ofCommits: [commit])
            loadMoreDescendats()
        }
        
        quickViewController.commit = commit
        
        updateWindowMode(.mapQuickView)
    }
    
    func hasPreviousQuickView() -> Bool {
        return quickViewIndex + 1 < (quickViewCommits?.count ?? 0)
    }
    
    func previousQuickView() {
        assert(quickViewCommits != nil)
        guard let quickViewCommits = quickViewCommits else { return }
        
        quickViewIndex += 1
        let commit = quickViewCommits[quickViewIndex]
        quickViewController.commit = commit
        
        if let _ = searchView.superview {
            searchResultsViewController.selectedCommit = commit
        } else {
            mapViewController.select(commit)
        }
        
        if quickViewIndex == quickViewCommits.count - 1 {
            loadMoreAncestors()
        }
        _updateToolbar()
    }
    
    func hasNextQuickView() -> Bool {
        return quickViewIndex > 0
    }
    
    func nextQuickView() {
        assert(quickViewCommits != nil)
        guard let quickViewCommits = quickViewCommits else { return }
        
        quickViewIndex -= 1
        let commit = quickViewCommits[quickViewIndex]
        quickViewController.commit = commit
        if let _ = searchView.superview {
            searchResultsViewController.selectedCommit = commit
        } else {
            mapViewController.select(commit)
        }
        
        if quickViewIndex == 0 {
            loadMoreDescendats()
        }
        
        _updateToolbar()
    }
    
    func exitQuickView() {
        quickViewCommits = nil
        quickViewAncestors = nil
        quickViewDescendants = nil
        
        repository?.resumeHistoryUpdates()
        
        updateWindowMode(.map)
    }
}

// Diff
extension Document2 {
    func enterDiff(with commit: GCCommit, parent: GCCommit) {
        diffViewController.setCommit(commit, withParentCommit: parent)
        updateWindowMode(.mapDiff)
    }
    
    func exitDiff() {
        updateWindowMode(.map)
        
        diffViewController.setCommit(nil, withParentCommit: nil)
    }
}

// Rewrite
extension Document2 {
    func enterRewrite(with commit: GCHistoryCommit) {
        helpHEADDisabled = true
        
        do {
            try commitRewriterViewController.startRewriting(commit)
            ProcessInfo.processInfo.disableSuddenTermination()
            updateWindowMode(.mapRewrite)
        } catch {
            _ = presentError(error)
            helpHEADDisabled = false
        }
    }
    
    // TODO: Rather than a convoluted API to ensure we can remove the GICommitRewriterViewController from the view hierarchy before doing the actual rewrite in case we need to show the GIConflictResolverViewController,
    // we should have a proper view controller system allowing to stack multiple view controllers
    func exitRewrite(with message: String?) {
        updateWindowMode(.map)
        ProcessInfo.processInfo.enableSuddenTermination()
        
        do {
            if let message = message {
                try commitRewriterViewController.finishRewritingCommit(withMessage: message)
            } else {
                try commitRewriterViewController.cancelRewritingCommit()
            }
            helpHEADDisabled = false
        } catch {
            _ = presentError(error)
        }
    }
}

// Split
extension Document2 {
    func enterSplit(with commit: GCHistoryCommit) {
        do {
            try commitSplitterViewController.startSplittingCommit(commit)
            ProcessInfo.processInfo.disableSuddenTermination()
            updateWindowMode(.mapSplit)
        } catch {
            _ = presentError(error)
        }
    }
    
    // TODO: Rather than a convoluted API to ensure we can remove the GICommitSplitterViewController from the view hierarchy before doing the actual rewrite in case we need to show the GIConflictResolverViewController,
    // we should have a proper view controller system allowing to stack multiple view controllers
    func exitSplit(with oldMessage: String?, _ newMessage: String?) {
        updateWindowMode(.map)
        ProcessInfo.processInfo.enableSuddenTermination()
        
        if let oldMessage = oldMessage, let newMessage = newMessage {
            do {
                try commitSplitterViewController.finishSplittingCommit(withOldMessage: oldMessage, newMessage: newMessage)
            } catch {
                _ = presentError(error)
            }
        } else {
            commitSplitterViewController.cancelSplittingCommit()
        }
    }
}

// Resolve
extension Document2 {
    func enterResolve(with ourCommit: GCCommit, their theirCommit: GCCommit) {
        helpHEADDisabled = true
        
        conflictResolverViewController.ourCommit = ourCommit
        conflictResolverViewController.theirCommit = theirCommit
        
        ProcessInfo.processInfo.disableSuddenTermination()
        updateWindowMode(.mapResolve)
    }
    
    func exitResolve() {
        updateWindowMode(.map)
        ProcessInfo.processInfo.enableSuddenTermination()
        
        conflictResolverViewController.ourCommit = nil
        conflictResolverViewController.theirCommit = nil
        
        helpHEADDisabled = false
    }
}

// Config
extension Document2 {
    func enterConfig() {
        updateWindowMode(.mapConfig)
    }
    
    func exitConfig() {
        updateWindowMode(.map)
    }
}

private let RestorableStateWindowMode = "windowMode"

// Restoration
extension Document2 {
    // This appears to be called by the NSDocumentController machinery whenever quitting the app even if -invalidateRestorableState was never called
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        // Restrict to non-modal modes
        coder.encode(windowMode.tab.index, forKey: RestorableStateWindowMode)
    }
    
    override func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
        
        let tabIndex = coder.decodeInteger(forKey: RestorableStateWindowMode)
        if let tab = WindowMode.Tab.init(rawValue: tabIndex) {
            updateWindowMode(tab.mode)
        } else {
            assertionFailure()
        }
        
        if !ready {
            DispatchQueue.main.async {
                self._documentDidOpen(NSNull())
            }
            ready = true
        } else {
            assertionFailure()
        }
        
    }
}

extension NSToolbarItem.Identifier {
    static let left = NSToolbarItem.Identifier("left")
    static let title = NSToolbarItem.Identifier("title")
    static let right = NSToolbarItem.Identifier("right")
}

extension Document2: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        switch itemIdentifier {
        case .title:
            item.view = titleView
            item.minSize = NSMakeSize(100, titleView.frame.height)
            item.maxSize = NSMakeSize(.greatestFiniteMagnitude, titleView.frame.height)
        case .left:
            item.view = leftView
        case .right:
            item.view = rightView
        default:
            assertionFailure()
        }
        
        return item
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        if #available(OSX 10.10, *) {
            return [.left, .title, .right]
        } else {
            return [.left, .flexibleSpace, .right]
        }
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }
}

extension Document2: NSTextFieldDelegate {
    // TODO: Should we do something with -insertNewline: i.e. Return key?
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.insertTab(_:)):
            mainWindow.selectNextKeyView(nil)
        case #selector(NSResponder.insertBacktab(_:)):
            mainWindow.selectPreviousKeyView(nil)
        case #selector(NSResponder.moveDown(_:)) where searchResultsViewController.results.count > 0:
            mainWindow.makeFirstResponder(searchResultsViewController.preferredFirstResponder)
            searchResultsViewController.selectedResult = searchResultsViewController.results.first as AnyObject
        default:
            return false
        }

        return true
    }
}

extension Document2: GCRepositoryDelegate {
    func repository(_ repository: GCRepository!, willStartTransferWith url: URL!) {
        AppDelegate.shared()?.repository(repository, willStartTransferWith: url) // Forward to AppDelegate
        
        infoTextField1.isHidden = true
        infoTextField2.isHidden = true
        progressTextField.isHidden = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 1.0
        progressIndicator.isIndeterminate = true
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
    }
    
    func repository(_ repository: GCRepository!, requiresPlainTextAuthenticationFor url: URL!, user: String!, username: AutoreleasingUnsafeMutablePointer<NSString?>!, password: AutoreleasingUnsafeMutablePointer<NSString?>!) -> Bool {
        return AppDelegate.shared()!.repository(repository, requiresPlainTextAuthenticationFor: url, user: user, username: username, password: password)
    }
    
    func repository(_ repository: GCRepository!, updateTransferProgress progress: Float, transferredBytes bytes: UInt) {
        if progress > 0 {
            progressIndicator.isIndeterminate = false
            progressIndicator.doubleValue = Double(progress)
        }
    }
    
    func repository(_ repository: GCRepository!, didFinishTransferWith url: URL!, success: Bool) {
        progressIndicator.stopAnimation(nil)
        progressTextField.isHidden = true
        progressIndicator.isHidden = true
        infoTextField1.isHidden = false
        infoTextField2.isHidden = false
        
        AppDelegate.shared()!.repository(repository, didFinishTransferWith: url, success: success) // Forward to AppDelegate
    }
}

extension Document2: GCLiveRepositoryDelegate {
    func repositoryDidUpdateState(_ repository: GCLiveRepository!) {
        _updateStatusBar()
    }
    
    func repositoryDidUpdateHistory(_ repository: GCLiveRepository!) {
        _updateTitleBar()
        if let _ = tagsView.superview {
            reloadTagsView()
        } else if let _ = ancestorsView.superview {
            reloadAncestorsView()
        }
    }
    
    func repository(_ repository: GCLiveRepository!, historyUpdateDidFailWithError error: Error!) {
        _ = presentError(error)
    }
    
    func repository(_ repository: GCLiveRepository!, stashesUpdateDidFailWithError error: Error!) {
        _ = presentError(error)
    }
    
    func repository(_ repository: GCLiveRepository!, statusUpdateDidFailWithError error: Error!) {
        _ = presentError(error)
    }
    
    func repository(_ repository: GCLiveRepository!, snapshotsUpdateDidFailWithError error: Error!) {
        _ = presentError(error)
    }
    
    func repository(_ repository: GCLiveRepository!, searchUpdateDidFailWithError error: Error!) {
        _ = presentError(error)
    }
    
    func repository(_ repository: GCLiveRepository!, undoOperationDidFailWithError error: Error!) {
        _ = presentError(error)
    }
    
    func repositoryDidUpdateSearch(_ repository: GCLiveRepository!) {
        if let _ = searchView.superview {
            performSearch(nil)
        }
    }
    
    func repositoryBackgroundOperation(inProgressDidChange repository: GCLiveRepository!) {
        _updateToolbar()
        _updateStatusBar()
    }
}

extension Document2: GIWindowControllerDelegate {
    
    func windowController(_ controller: GIWindowController!, handleKeyDown event: NSEvent!) -> Bool {
        var handled = false
        guard !event.isARepeat else { return handled }
        let characters = event.charactersIgnoringModifiers
        
        switch windowMode! {
        case .mapQuickView where event.keyCode == GIKeyCode.esc.rawValue || characters == " ",
             .mapDiff      where event.keyCode == GIKeyCode.esc.rawValue || characters == "i",
             .mapConfig    where event.keyCode == GIKeyCode.esc.rawValue:
            
            exit(nil)
            handled = true
        case .map:
            if event.keyCode == GIKeyCode.esc.rawValue {
                if let _ = tagsView.superview {
                    toggleTags(nil)
                    handled = true
                } else if let _ = snapshotsView.superview {
                    toggleSnapshots(nil)
                    handled = true
                } else if let _ = reflogView.superview {
                    toggleReflog(nil)
                    handled = true
                } else if let _ = searchView.superview {
                    closeSearch(nil)
                    handled = true
                } else if let _ = ancestorsView.superview {
                    toggleAncestors(nil)
                    handled = true
                }
            } else if characters == " " {
                if let _ = searchView.superview {
                    if let commit = searchResultsViewController.selectedCommit {
                        
                        if event.modifierFlags.contains(.option), let otherCommit = commit.parents.first as? GCCommit {
                            mapViewController.launchDiffTool(with: commit, otherCommit: otherCommit) // Use main-line
                        } else {
                            enterQuickView(with: commit, commitList: searchResultsViewController.commits as? [GCHistoryCommit])
                        }
                        handled = true
                    }
                } else if let _ = tagsView.superview {
                    if let commit = tagsViewController.selectedCommit {
                        
                        if event.modifierFlags.contains(.option), let otherCommit = commit.parents.first as? GCCommit {
                            mapViewController.launchDiffTool(with: commit, otherCommit: otherCommit) // Use main-line
                        } else {
                            enterQuickView(with: commit, commitList: tagsViewController.commits as? [GCHistoryCommit])
                        }
                        handled = true
                    }
                } else if let _ = reflogView.superview {
                    if event.modifierFlags.contains(.option) {
                        windowController.showOverlay(with: .help, message: NSLocalizedString("External Diff is not available for reflog entries", comment: ""))
                    } else {
                        windowController.showOverlay(with: .help, message: NSLocalizedString("Quick View is not available for reflog entries", comment: ""))
                    }
                    handled = true
                } else if let _ = ancestorsView.superview {
                    if let commit = tagsViewController.selectedCommit {
                        
                        if event.modifierFlags.contains(.option), let otherCommit = commit.parents.first as? GCCommit {
                            mapViewController.launchDiffTool(with: commit, otherCommit: otherCommit) // Use main-line
                        } else {
                            enterQuickView(with: commit, commitList: ancestorsViewController.commits as? [GCHistoryCommit])
                        }
                        handled = true
                    }
                }
            } else if characters == "i", let _ = reflogView.superview,
                let entry = unifiedReflogViewController.selectedReflogEntry {
                
                if let fromCommit = entry.fromCommit, let toCommit = entry.toCommit {
                    enterDiff(with: toCommit, parent: fromCommit)
                    handled = true
                }
            }
            
        default: break
        }
        
        return handled
    }
    
    func windowControllerDidChangeHasModalView(_ controller: GIWindowController!) {
        _updateToolbar()
    }
}

extension Document2: GIMapViewControllerDelegate {
    
    func mapViewControllerDidReloadGraph(_ controller: GIMapViewController!) {
        assert(repository == nil)
        guard let repository = repository else { return }
        
        _updateStatusBar()
        
        if let _ = searchView.superview {
            commitListViewControllerDidChangeSelection(nil)
        }
        
        let headBranch = repository.history.headBranch

        if lastHEADBranch != headBranch {
            if !helpHEADDisabled {
                if let headBranch = headBranch {
                    windowController.showOverlay(with: .informational, message: String(format: NSLocalizedString("You are now on branch \"%@\"", comment: ""), headBranch.name))
                } else  {
                    windowController.showOverlay(with: .informational, message: NSLocalizedString("You are not on any branch anymore", comment: ""))
                }
            }
            
            lastHEADBranch = headBranch
        }
        
    }
    
    func mapViewControllerDidChangeSelection(_ controller: GIMapViewController!) {
        if let _ = searchView.superview {
            if !preventSelectionLoopback {
                preventSelectionLoopback = true
                searchResultsViewController.selectedCommit = mapViewController.selectedCommit
                preventSelectionLoopback = false
            }
        } else if let _ = tagsView.superview {
            if !preventSelectionLoopback {
                preventSelectionLoopback = true
                tagsViewController.selectedCommit = mapViewController.selectedCommit
                preventSelectionLoopback = false
            }
        } else if let _ = ancestorsView.superview {
            if !preventSelectionLoopback {
                preventSelectionLoopback = true
                ancestorsViewController.selectedCommit = mapViewController.selectedCommit
                preventSelectionLoopback = false
            }
        }
        if windowMode != .mapQuickView {
            quickViewController.commit = nil
        }
    }
    
    func mapViewController(_ controller: GIMapViewController!, quickViewCommit commit: GCHistoryCommit!) {
        enterQuickView(with: commit, commitList: nil)
    }
    
    func mapViewController(_ controller: GIMapViewController!, diffCommit commit: GCHistoryCommit!, withOtherCommit otherCommit: GCHistoryCommit!) {
        enterDiff(with: commit, parent: otherCommit)
    }
    
    func mapViewController(_ controller: GIMapViewController!, rewrite commit: GCHistoryCommit!) {
        enterRewrite(with: commit)
    }
    
    func mapViewController(_ controller: GIMapViewController!, splitCommit commit: GCHistoryCommit!) {
        enterSplit(with: commit)
    }
    
}

extension Document2: GISnapshotListViewControllerDelegate {
    func snapshotListViewControllerDidChangeSelection(_ controller: GISnapshotListViewController!) {
        if let snapshot = snapshotListViewController.selectedSnapshot {
            do {
                mapViewController.previewHistory = try repository!.loadHistory(from: snapshot, using: .none)
            } catch {
                _ = presentError(error)
            }
        } else {
            assertionFailure()
            mapViewController.previewHistory = nil
        }
    }
    
    func snapshotListViewController(_ controller: GISnapshotListViewController!, didRestore snapshot: GCSnapshot!) {
        toggleSnapshots(nil)
    }
    
}

extension Document2: GIUnifiedReflogViewControllerDelegate {
    func unifiedReflogViewControllerDidChangeSelection(_ controller: GIUnifiedReflogViewController!) {
        if let entry = unifiedReflogViewController.selectedReflogEntry {
            mapViewController.select(entry.toCommit)
        }
    }
    
    func unifiedReflogViewController(_ controller: GIUnifiedReflogViewController!, didRestore entry: GCReflogEntry!) {
        toggleReflog(nil)
    }
    
}

extension Document2: GICommitListViewControllerDelegate {
    func commitListViewControllerDidChangeSelection(_ controller: GICommitListViewController!) {
        if !preventSelectionLoopback {
            let commit: GCHistoryCommit?
            if let _ = searchView.superview {
                commit = searchResultsViewController.selectedCommit
            } else if let _ = tagsView.superview {
                commit = tagsViewController.selectedCommit
            } else if let _ = ancestorsView.superview {
                commit = ancestorsViewController.selectedCommit
            } else {
                commit = nil
            }
            
            if let commit = commit { // Don't deselect commit in map if no commit is selected in the list
                preventSelectionLoopback = true
                mapViewController.select(commit)
                preventSelectionLoopback = false
            }
        }
        
        if mapViewController.selectedCommit == nil {
            if (searchView.superview != nil && searchResultsViewController.selectedResult != nil) ||
               (tagsView.superview != nil && tagsViewController.selectedResult != nil) ||
               (ancestorsView.superview != nil && ancestorsViewController.selectedResult != nil){
                
                hiddenWarningView.isHidden = false
            } else {
                hiddenWarningView.isHidden = true
            }
        } else {
            hiddenWarningView.isHidden = true
        }
    }
    
}

extension Document2: GICommitViewControllerDelegate {
    func commitViewController(_ controller: GICommitViewController!, didCreateCommit commit: GCCommit!) {
        
    }
}

extension Document2: GICommitRewriterViewControllerDelegate {
    func commitRewriterViewControllerShouldFinish(_ controller: GICommitRewriterViewController!, withMessage message: String!) {
        exitRewrite(with: message)
    }
    
    func commitRewriterViewControllerShouldCancel(_ controller: GICommitRewriterViewController!) {
        exitRewrite(with: nil)
    }
}

extension Document2: GICommitSplitterViewControllerDelegate {
    func commitSplitterViewControllerShouldFinish(_ controller: GICommitSplitterViewController!, withOldMessage oldMessage: String!, newMessage: String!) {
        exitSplit(with: oldMessage, newMessage)
    }
    
    func commitSplitterViewControllerShouldCancel(_ controller: GICommitSplitterViewController!) {
        exitSplit(with: nil, nil)
    }
    
}

extension Document2: GIConflictResolverViewControllerDelegate {
    func conflictResolverViewControllerShouldCancel(_ controller: GIConflictResolverViewController!) {
        resolvingConflicts = -1
    }
    
    func conflictResolverViewControllerDidFinish(_ controller: GIConflictResolverViewController!) {
        resolvingConflicts = 1
    }
}

extension Document2: GIMergeConflictResolver {
    func resolveMergeConflicts(withOurCommit ourCommit: GCCommit!, theirCommit: GCCommit!) -> Bool {
        enterResolve(with: ourCommit, their: theirCommit)
        
        // TODO: Is re-entering NSApp's event loop really AppKit-safe (it appears to partially break NSAnimationContext animations for instance)?
        resolvingConflicts = 0
        while resolvingConflicts != 0 {
            if let event = NSApp.nextEvent(matching: .any, until: .distantFuture, inMode: .modalPanel, dequeue: true) {
                NSApp.sendEvent(event)
            }
        }
        
        exitResolve()
        
        return resolvingConflicts > 0
    }
}

extension NSButton: NSValidatedUserInterfaceItem { }
extension NSSearchField: NSValidatedUserInterfaceItem { }
