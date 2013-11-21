#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@class XTCommitHeaderViewController;
@class XTFileChangesDataSource;
@class XTFileListDataSource;
@class XTRepository;
@class XTTextPreviewController;
@class RBSplitView;

extern const CGFloat kChangeImagePadding;

/**
  View controller for the file list and detail view.
 */
@interface XTFileViewController : NSViewController
{
  IBOutlet NSSplitView *_headerSplitView;
  IBOutlet RBSplitView *_splitView;
  IBOutlet NSView *_leftPane, *_rightPane;
  IBOutlet NSOutlineView *_fileListOutline;
  IBOutlet QLPreviewView *_filePreview;
  IBOutlet XTCommitHeaderViewController *_headerController;
  IBOutlet XTFileChangesDataSource *_fileChangeDS;
  IBOutlet XTFileListDataSource *_fileListDS;
  IBOutlet XTTextPreviewController *_textController;

  XTRepository *_repo;
}

@property (strong) IBOutlet NSTabView *previewTabView;
@property (weak) IBOutlet NSSegmentedControl *viewSelector;
@property (readonly) NSDictionary *changeImages;

+ (BOOL)fileNameIsText:(NSString*)name;

- (IBAction)changeFileListView:(id)sender;

- (void)setRepo:(XTRepository *)repo;
- (void)refresh;

@end
