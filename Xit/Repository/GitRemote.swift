import Cocoa

public protocol Remote: AnyObject
{
  var name: String? { get }
  var urlString: String? { get }
  var pushURLString: String? { get }
  
  func rename(_ name: String) throws
  func updateURLString(_ URLString: String?) throws
  func updatePushURLString(_ URLString: String?) throws
}

extension Remote
{
  var url: URL? { return urlString.flatMap { URL(string: $0) } }
  var pushURL: URL? { return pushURLString.flatMap { URL(string: $0) } }
  
  func updateURL(_ url: URL) throws
  {
    try updateURLString(url.absoluteString)
  }
  
  func updatePushURL(_ url: URL) throws
  {
    try updatePushURLString(url.absoluteString)
  }
}

class GitRemote: Remote
{
  let remote: OpaquePointer
  
  var name: String?
  {
    guard let name = git_remote_name(remote)
    else { return nil }
    
    return String(cString: name)
  }

  var urlString: String?
  {
    guard let url = git_remote_url(remote)
    else { return nil }
    
    return String(cString: url)
  }
  
  var pushURLString: String?
  {
    guard let url = git_remote_pushurl(remote)
    else { return nil }
    
    return String(cString: url)
  }
  
  init?(name: String, repository: OpaquePointer)
  {
    let remote = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
    let result = git_remote_lookup(remote, repository, name)
    guard result == 0,
          let finalRemote = remote.pointee
    else { return nil }
    
    self.remote = finalRemote
  }

  func rename(_ name: String) throws
  {
    guard let oldName = git_remote_name(remote),
          let owner = git_remote_owner(remote)
    else { throw RepoError.unexpected }
    
    let problems = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
    
    problems.pointee = git_strarray()
    
    let result = git_remote_rename(problems, owner, oldName, name)
    let resultCode = git_error_code(rawValue: result)
    
    defer {
      git_strarray_free(problems)
    }
    switch resultCode {
      case GIT_EINVALIDSPEC:
        throw RepoError.invalidName(name)
      case GIT_EEXISTS:
        throw RepoError.duplicateName
      case GIT_OK:
        break
      default:
        throw RepoError(gitCode: resultCode)
    }
  }
  
  func updateURLString(_ URLString: String?) throws
  {
    guard let name = git_remote_name(remote),
          let owner = git_remote_owner(remote)
    else { throw RepoError.unexpected }
    let result = git_remote_set_url(owner, name, URLString)
    
    if result == GIT_EINVALIDSPEC.rawValue {
      throw RepoError.invalidName(URLString ?? "")
    }
    else {
      try RepoError.throwIfGitError(result)
    }
  }
  
  func updatePushURLString(_ URLString: String?) throws
  {
    guard let name = git_remote_name(remote),
          let owner = git_remote_owner(remote)
    else { throw RepoError.unexpected }
    let result = git_remote_set_pushurl(owner, name, URLString)
    
    if result == GIT_EINVALIDSPEC.rawValue {
      throw RepoError.invalidName(URLString ?? "")
    }
    else {
      try RepoError.throwIfGitError(result)
    }
  }
}
