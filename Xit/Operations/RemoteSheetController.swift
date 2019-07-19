import Cocoa
import Siesta

protocol RemoteSheetDelegate: AnyObject
{
  func acceptSettings(from sheetController: RemoteSheetController) -> Bool
}

class RemoteSheetController: SheetController
{
  weak var delegate: RemoteSheetDelegate?
  weak var repository: XTRepository?
  
  @IBOutlet weak var nameField: NSTextField!
  @IBOutlet weak var fetchField: NSTextField!
  @IBOutlet weak var pushField: NSTextField!
  
  var name: String
  {
    get { return nameField.stringValue }
    set { nameField.stringValue = newValue }
  }
  var fetchURLString: String?
  {
    get { return fetchField.stringValue.nilIfEmpty }
    set { fetchField.stringValue = newValue ?? "" }
  }
  var pushURLString: String?
  {
    get { return pushField.stringValue.nilIfEmpty }
    set { pushField.stringValue = newValue ?? "" }
  }
  
  override func resetFields()
  {
    name = ""
    fetchURLString = nil
    pushURLString = nil
  }
  
  override func accept(_ sender: AnyObject)
  {
    if delegate?.acceptSettings(from: self) ?? false {
      super.accept(sender)
    }
  }
}
