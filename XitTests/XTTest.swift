import Foundation
import XCTest
@testable import Xit

class XTTest: XCTestCase
{
  var repoPath: String!
  var remoteRepoPath: String!
  
  var repository, remoteRepository: XTRepository!
  
  var file1Name: String { return "file1.txt" }
  var file1Path: String { return repoPath.appending(pathComponent: file1Name) }
  var addedName: String { return "added.txt" }
  var untrackedName: String { return "untracked.txt" }
  
  static func createRepo(atPath repoPath: String) -> XTRepository?
  {
    NSLog("[createRepo] repoName=\(repoPath)")
    
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: repoPath) {
      do {
        try fileManager.removeItem(atPath: repoPath)
      }
      catch {
        XCTFail("Couldn't make way for repository: \(repoPath)")
        return nil
      }
    }
    
    do {
      try fileManager.createDirectory(atPath: repoPath,
                                      withIntermediateDirectories: true,
                                      attributes: nil)
    }
    catch {
      XCTFail("Couldn't create repository: \(repoPath)")
      return nil
    }
    
    let repoURL = URL(fileURLWithPath: repoPath)
    guard let repo = XTRepository(emptyURL: repoURL)
    else {
      XCTFail("initializeRepository '\(repoPath)' FAIL")
      return nil
    }
    guard fileManager.fileExists(atPath: repoPath.appending(pathComponent: ".git"))
    else {
      XCTFail(".git not found")
      return nil
    }

    return repo
  }
  
  override func setUp()
  {
    super.setUp()
    
    repoPath = NSString.path(withComponents: ["private",
                                              NSTemporaryDirectory(),
                                              "testRepo"])
    repository = XTTest.createRepo(atPath: repoPath)
    addInitialRepoContent()
  }
  
  override func tearDown()
  {
    waitForRepoQueue()
    
    let fileManager = FileManager.default
    
    XCTAssertNoThrow(try fileManager.removeItem(atPath: repoPath))
    if let remoteRepoPath = self.remoteRepoPath {
      XCTAssertNoThrow(try fileManager.removeItem(atPath: remoteRepoPath))
    }
    super.tearDown()
  }
  
  func waitForRepoQueue()
  {
    wait(for: repository)
  }
  
  func wait(for repository: XTRepository)
  {
    repository.queue.wait()
    WaitForQueue(DispatchQueue.main)
  }
  
  func addInitialRepoContent()
  {
    XCTAssertTrue(commit(newTextFile: file1Name, content: "some text"))
  }
  
  func makeRemoteRepo()
  {
    let parentPath = repoPath.deletingLastPathComponent
    
    remoteRepoPath = parentPath.appending(pathComponent: "remotetestrepo")
    remoteRepository = XTTest.createRepo(atPath: remoteRepoPath)
    XCTAssertNotNil(remoteRepository)
  }
  
  @discardableResult
  func commit(newTextFile name: String, content: String) -> Bool
  {
    return commit(newTextFile: name, content: content, repository: repository)
  }

  @discardableResult
  func commit(newTextFile name: String, content: String,
              repository: XTRepository) -> Bool
  {
    let basePath = repository.repoURL.path
    let filePath = basePath.appending(pathComponent: name)
    
    do {
      try content.write(toFile: filePath, atomically: true, encoding: .ascii)
    }
    catch {
      return false
    }
    
    var result = true
    let semaphore = DispatchSemaphore(value: 0)
    
    repository.queue.executeOffMainThread {
      do {
        try repository.stage(file: name)
        try repository.commit(message: "new \(name)", amend: false,
                                   outputBlock: nil)
        semaphore.signal()
      }
      catch {
        result = false
      }
    }
    return (semaphore.wait(timeout: .distantFuture) == .success) && result
  }
  
  @discardableResult
  func write(text: String, to path: String) -> Bool
  {
    do {
      try text.write(toFile: repoPath.appending(pathComponent: path),
                     atomically: true, encoding: .utf8)
      repository.invalidateIndex()
    }
    catch {
      XCTFail("write to \(path) failed")
      return false
    }
    return true
  }
  
  @discardableResult
  func writeTextToFile1(_ text: String) -> Bool
  {
    return write(text: text, to: file1Name)
  }
  
  func makeStash() throws
  {
    writeTextToFile1("stashy")
    write(text: "new", to: untrackedName)
    write(text: "add", to: addedName)
    try repository.stage(file: addedName)
    try repository.saveStash(name: "", includeUntracked: true)
  }

  func makeTiffFile(_ name: String) throws
  {
    let tiffURL = repository.fileURL(name)
    
    try NSImage(named: .actionTemplate)?.tiffRepresentation?.write(to: tiffURL)
  }
}

extension DeltaStatus: CustomStringConvertible
{
  public var description: String
  {
    switch self {
      case .unmodified:
        return "unmodified"
      case .added:
        return "added"
      case .deleted:
        return "deleted"
      case .modified:
        return "modified"
      case .renamed:
        return "renamed"
      case .copied:
        return "copied"
      case .ignored:
        return "ignored"
      case .untracked:
        return "untracked"
      case .typeChange:
        return "typeChange"
      case .conflict:
        return "conflict"
      case .mixed:
        return "mixed"
    }
  }
}
