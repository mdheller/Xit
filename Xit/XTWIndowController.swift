import Cocoa

/// XTDocument's main window controller.
class XTWindowController: NSWindowController {
  
  @IBOutlet var historyController: XTHistoryViewController!
  @IBOutlet var activity: NSProgressIndicator!
  var xtDocument: XTDocument?
  var selectedCommitSHA: String?
  var selectedModel: XTFileChangesModel?
  var inStagingView: Bool { return self.selectedCommitSHA == XTStagingSHA }
  
  var fetchController: XTFetchController?
  
  override var document: AnyObject? {
    didSet {
      xtDocument = document as! XTDocument?
    }
  }
  
  override func windowDidLoad()
  {
    super.windowDidLoad()
    self.window!.contentViewController = self.historyController
    self.window!.makeFirstResponder(self.historyController.historyTable)
    
    let repo = self.xtDocument!.repository
    
    repo.addObserver(self, forKeyPath:"activeTasks", options:.New, context:nil)
    self.historyController.windowDidLoad()
    self.historyController.setRepo(repo)
  }
  
  deinit
  {
    self.xtDocument!.repository.removeObserver(self, forKeyPath:"actaiveTasks")
    fetchController?.canceled = true
  }
  
  override func observeValueForKeyPath(
      keyPath: String?,
      ofObject object: AnyObject?,
      change: [String : AnyObject]?,
      context: UnsafeMutablePointer<Void>)
  {
    guard (keyPath != nil) && (keyPath! == "activeTasks")
    else {
      super.observeValueForKeyPath(
          keyPath, ofObject:object, change:change, context:context)
      return
    }
    
    if let tasks = change?[NSKeyValueChangeNewKey] {
      if tasks.count > 0 {
        self.activity.startAnimation(self)
        return
      }
    }
    self.activity.stopAnimation(self)
  }
  
  @IBAction func showHideSidebar(sender: AnyObject)
  {
    historyController.toggleSideBar(sender)
  }
  
  @IBAction func verticalLayout(sender: AnyObject)
  {
    self.historyController.mainSplitView.vertical = true
    self.historyController.mainSplitView.adjustSubviews()
  }
  
  @IBAction func horizontalLayout(sender: AnyObject)
  {
    self.historyController.mainSplitView.vertical = false
    self.historyController.mainSplitView.adjustSubviews()
  }
  
  @IBAction func refresh(_: AnyObject)
  {
    NSNotificationCenter.defaultCenter().postNotificationName(
        XTRepositoryChangedNotification, object: self.xtDocument!.repository)
  }
  
  @IBAction func newTag(_: AnyObject) {}
  @IBAction func newBranch(_: AnyObject) {}
  @IBAction func addRemote(_: AnyObject) {}

  @IBAction func fetch(_: AnyObject)
  {
    if fetchController == nil {
      fetchController = XTFetchController(windowController: self)
      
      fetchController!.start()
    }
  }
  @IBAction func pull(_: AnyObject) {}
  @IBAction func push(_: AnyObject) {}
  
  @IBAction func networkSegmentClicked(sender: AnyObject)
  {
    switch (sender as! NSSegmentedControl).selectedSegment {
      case 0:
        fetch(sender)
      case 1:
        pull(sender)
      case 2:
        push(sender)
      default:
        break
    }
  }
  
  func fetchEnded()
  {
    fetchController = nil
  }
  
  override func validateMenuItem(menuItem: NSMenuItem) -> Bool
  {
    var result = false
    
    switch menuItem.action {

      case #selector(XTWindowController.showHideSidebar(_:)):
        result = true
        if historyController.sidebarSplitView.isSubviewCollapsed(
            historyController.sidebarSplitView.subviews[0]) {
          menuItem.title = NSLocalizedString("Show Sidebar", comment: "")
        }
        else {
          menuItem.title = NSLocalizedString("Hide Sidebar", comment: "")
        }

      case #selector(XTWindowController.verticalLayout(_:)):
        result = true
        menuItem.state = historyController.mainSplitView.vertical
            ? NSOnState : NSOffState

      case #selector(XTWindowController.horizontalLayout(_:)):
        result = true
        menuItem.state = historyController.mainSplitView.vertical
            ? NSOffState : NSOnState

      default:
        result = super.validateMenuItem(menuItem)
    }
    return result
  }
}
