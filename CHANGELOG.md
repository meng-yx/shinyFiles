# Changelog - Multiple Directory Selection Enhancement

## Overview
This changelog documents the modifications made to the shinyFiles package to add multiple directory selection functionality. The enhancement allows users to select multiple directories using an intuitive interface that keeps the modal open and allows building a list of selected directories.

## Changes Made

### 0. bslib Compatibility Enhancements (`inst/www/styles.css`)

#### 0.1 Built-in bslib Theme Support
- **Added flexbox toolbar layout**: Prevents dropdown menu wrapping to second row
- **Fixed modal button sizing**: Ensures proper sizing with bslib themes
- **Enhanced breadcrumbs positioning**: Uses flexbox for responsive layout
- **Added `!important` declarations**: Protects styling from bslib theme overrides
- **Improved selected directories display**: Better spacing and typography
- **Scrollable selected directories list**: Limited height with custom scrollbar for better UX
- **Larger modal interface**: Increased modal height to 90% viewport height for better usability
- **Compact modal header**: Reduced header height and padding for more content space
- **Fixed root directory bug**: Corrected issue where switching root directories caused incorrect absolute paths for previously selected directories
- **Optimized server updates**: Shiny server is only updated when user clicks "Done", not on every "Add Directory" action

```css
/* bslib compatibility fixes */
.sF-navigation {
  display: flex !important;
  flex-wrap: nowrap !important;
  align-items: center !important;
  gap: 5px !important;
}

.sF-breadcrumps {
  flex: 1 1 auto !important;
  min-width: 120px !important;
  max-width: 200px !important;
  margin-right: 0 !important;
  margin-left: 0 !important;
}

/* Fix modal button sizing for bslib */
.sF-remove-dir {
  padding: 1px 4px !important;
  font-size: 10px !important;
  line-height: 1.2 !important;
  height: auto !important;
}

/* Scrollable selected directories list */
.sF-selected-directories {
  max-height: 150px !important;
  overflow-y: auto !important;
  border: 1px solid #ddd !important;
  border-radius: 4px !important;
  background-color: #f9f9f9 !important;
}

/* Larger modal interface */
.sF-modal .modal-content {
  height: 90vh !important;
  max-height: 90vh !important;
}

.sF-fileWindow, .sF-dirWindow {
  height: 70vh !important;
  min-height: 70vh !important;
}

/* Compact modal header */
.sF-modal .modal-header {
  padding: 8px 15px !important;
  min-height: auto !important;
}

.sF-modal .modal-title {
  font-size: 16px !important;
  line-height: 1.2 !important;
  margin: 0 !important;
  padding: 0 !important;
}
```

#### 0.2 Benefits
- **No custom CSS required**: Works seamlessly with bslib themes out of the box
- **Responsive design**: Toolbar adapts to different modal widths
- **Professional appearance**: Consistent with modern Shiny app styling
- **Backward compatibility**: Existing apps continue to work unchanged

#### 0.3 Critical Bug Fix: Root Directory Switching
**Problem**: When users selected directories from one root (e.g., C: drive), then switched to another root (e.g., D: drive) and selected more directories, all previously selected directories would incorrectly use the new root directory, resulting in invalid absolute paths.

**Solution**: 
- **Enhanced data structure**: Each selected directory now stores both its relative path AND its original root directory
- **Improved deduplication**: Duplicate checking now considers both path and root directory
- **Updated R parsing**: `parseDirPath()` function now correctly handles the new data structure
- **Better display**: Selected directories list shows both root name and relative path

**Example**:
```javascript
// Before (buggy): All directories use current root
[
  ['folder1'],           // Would incorrectly use current root
  ['folder2']            // Would incorrectly use current root
]

// After (fixed): Each directory remembers its original root
[
  {path: ['folder1'], root: 'C:'},  // Correctly uses C: drive
  {path: ['folder2'], root: 'D:'}   // Correctly uses D: drive
]
```

#### 0.4 Performance Optimization: Deferred Server Updates
**Problem**: Previously, every "Add Directory" click immediately triggered a Shiny server update, causing unnecessary network traffic and potential performance issues when users selected many directories.

**Solution**:
- **Deferred updates**: Shiny server is only updated when user clicks "Done" button
- **Local state management**: All selections are managed locally in JavaScript until finalization
- **Improved UX**: Users can add/remove directories without triggering server-side processing
- **Better performance**: Reduces server load and network traffic during selection process

**Behavior**:
- ✅ **Add Directory**: Updates local display only, no server communication
- ✅ **Remove Directory**: Updates local display only, no server communication  
- ✅ **Done Button**: Sends final selection list to Shiny server
- ✅ **Cancel/Close**: Discards all selections, no server update

### 1. R Code Modifications (`R/dirchoose.R`)

#### 1.1 Enhanced `shinyDirButton()` Function
- **Added `multiple` parameter**: New optional parameter `multiple = FALSE` to enable multiple directory selection
- **Added `data-selecttype` attribute**: HTML attribute to distinguish between single and multiple selection modes
- **Backward compatibility**: Existing code continues to work unchanged

```r
# Before
shinyDirButton(id, label, title, buttonType="default", class=NULL, icon=NULL, style=NULL, ...)

# After  
shinyDirButton(id, label, title, multiple = FALSE, buttonType="default", class=NULL, icon=NULL, style=NULL, ...)
```

#### 1.2 Enhanced `shinyDirLink()` Function
- **Added `multiple` parameter**: Same functionality as `shinyDirButton()` for link-based directory selection
- **Added `data-selecttype` attribute**: Consistent behavior across button and link implementations

#### 1.3 Updated `parseDirPath()` Function
- **Multiple selection support**: Now handles both single and multiple directory selections
- **Backward compatibility**: Single selections return a single path (string)
- **Multiple selections**: Return a vector of paths when multiple directories are selected
- **Robust error handling**: Gracefully handles empty selections and invalid inputs

```r
# Single selection (backward compatible)
parseDirPath(roots, selection)  # Returns: "/path/to/directory"

# Multiple selection (new)
parseDirPath(roots, selection)  # Returns: c("/path/to/dir1", "/path/to/dir2", "/path/to/dir3")
```

#### 1.4 Fixed Function Calls
- **Replaced `dir.exists()` with `fs::dir_exists()`**: Fixed compatibility with the `fs` package
- **Replaced `file.exists()` with `fs::file_exists()`**: Consistent use of `fs` package functions
- **Replaced `path()` with `fs::path()`**: Proper namespace usage

#### 1.5 Added Error Handling for Permission Issues
- **Windows permission errors**: Added graceful handling for `[EPERM]` errors when accessing restricted directories
- **`dir_ls()` error handling**: Wrapped `dir_ls()` calls in `tryCatch()` to prevent crashes
- **`dir_exists()` error handling**: Added error handling for directory existence checks
- **Graceful degradation**: App continues to work even when encountering permission-denied directories

### 2. JavaScript Modifications (`inst/www/shinyFiles.js`)

#### 2.1 Enhanced `selectFolder()` Function
- **Restored original navigation behavior**: Clicking directories now properly navigates through the folder structure
- **Maintained selection highlighting**: Visual feedback for currently selected directory
- **Preserved toggle functionality**: Clicking the same directory toggles selection

#### 2.2 New `updateSelectedDirectoriesDisplay()` Function
- **Visual feedback**: Displays currently selected directories in a dedicated area
- **Individual remove buttons**: Each selected directory has its own "Remove" button
- **Dynamic updates**: List updates in real-time as directories are added/removed
- **User-friendly interface**: Clear indication of selection count and directory paths
- **Deduplication display**: Shows only unique directories in the display (even if duplicates exist in data)
- **Smart indexing**: Maintains correct remove button functionality despite deduplication

#### 2.2.1 New `showDuplicateSelectionNotification()` Function
- **User feedback**: Shows warning notification when duplicate directory is selected
- **Non-intrusive**: Auto-dismisses after 3 seconds
- **Clear messaging**: Explains that directory is already selected
- **Bootstrap styling**: Consistent with modal design

#### 2.3 Enhanced `selectFiles()` Function
- **Multiple selection logic**: Handles adding directories to selection list in multiple mode
- **Modal persistence**: Keeps modal open after adding directories (multiple mode only)
- **Single selection behavior**: Maintains original behavior for single selection mode
- **Data management**: Properly manages the `selectedDirectories` data structure
- **Deduplication logic**: Prevents adding the same directory multiple times
- **User feedback**: Shows notification when user tries to select duplicate directory

#### 2.4 Dynamic Button Management
- **Conditional button creation**: Different buttons for single vs multiple selection modes
- **Single mode**: "Select" button (closes modal immediately)
- **Multiple mode**: "Add Directory" button (adds to list) + "Done" button (closes modal)
- **Button styling**: Visual distinction between action types (green for "Add", blue for "Done")

#### 2.5 Enhanced Modal Creation (`createDirChooser()`)
- **Initialization**: Properly initializes `selectedDirectories` array for multiple selection
- **Event handling**: Separate handlers for "Add Directory" and "Done" buttons
- **State management**: Maintains selection state across modal interactions

### 3. User Interface Enhancements

#### 3.1 Modal Behavior
- **Single selection**: Modal closes immediately after selection (original behavior)
- **Multiple selection**: Modal stays open, allowing multiple directory additions
- **Visual feedback**: Clear indication of current selection and selection count

#### 3.2 Button Interface
- **"Add Directory" button**: Adds currently selected directory to the list
- **"Done" button**: Closes modal and returns all selected directories
- **"Remove" buttons**: Individual remove buttons for each selected directory
- **"Cancel" button**: Cancels selection and closes modal (unchanged)

#### 3.3 Selection Display
- **Real-time updates**: Selection list updates immediately when directories are added/removed
- **Path display**: Shows full paths of selected directories
- **Count indicator**: Displays number of selected directories
- **Remove functionality**: Easy removal of individual directories from selection

### 4. Example Application (`example_multiple_dirs_app.R`)

#### 4.1 Demonstration App
- **Side-by-side comparison**: Shows both single and multiple selection modes
- **Updated instructions**: Clear guidance on how to use the new multiple selection feature
- **Dependency management**: Properly loads required packages and local source files

#### 4.2 Usage Instructions
- **Step-by-step guide**: Clear instructions for using multiple directory selection
- **Visual feedback**: Shows selected directories in real-time
- **Error handling**: Graceful handling of no selections

## Usage Examples

### Single Directory Selection (Original Behavior)
```r
# UI
shinyDirButton("single_dir", "Choose Directory", "Select a directory")

# Server
shinyDirChoose(input, "single_dir", roots = volumes, session = session)

# Parse result
selected_path <- parseDirPath(volumes, input$single_dir)
```

### Multiple Directory Selection (New Feature)
```r
# UI
shinyDirButton("multiple_dirs", "Choose Directories", "Select directories", multiple = TRUE)

# Server
shinyDirChoose(input, "multiple_dirs", roots = volumes, session = session)

# Parse result
selected_paths <- parseDirPath(volumes, input$multiple_dirs)
# Returns vector of paths: c("/path1", "/path2", "/path3")
```

## Technical Details

### Data Structure Changes
- **Single selection**: Returns `{path: [...], root: "..."}` (unchanged)
- **Multiple selection**: Returns `{files: [...], root: "..."}` (new format)
- **Backward compatibility**: `parseDirPath()` handles both formats automatically

### Event Handling
- **Navigation clicks**: Handled by `selectFolder()` for directory tree navigation
- **Selection clicks**: Handled by `selectFiles()` for adding to selection list
- **Modal management**: Separate logic for single vs multiple selection modes

### State Management
- **`selectedDirectories` array**: Stores list of selected directory paths
- **Modal state**: Maintains selection state across interactions
- **Input updates**: Real-time updates to Shiny input variables

## Backward Compatibility

### Unchanged Behavior
- **Single directory selection**: Works exactly as before
- **Existing API**: All existing function signatures remain the same
- **Default parameters**: New `multiple` parameter defaults to `FALSE`
- **Return formats**: Single selections return the same format as before

### Migration Guide
- **No changes required**: Existing code continues to work
- **Optional enhancement**: Add `multiple = TRUE` to enable new functionality
- **Parse function**: `parseDirPath()` automatically detects and handles both formats

## Testing

### Test Cases
1. **Single selection**: Verify original behavior is preserved
2. **Multiple selection**: Test adding multiple directories
3. **Navigation**: Ensure directory tree navigation works properly
4. **Remove functionality**: Test removing individual directories
5. **Modal behavior**: Verify modal stays open in multiple mode
6. **Error handling**: Test with empty selections and invalid inputs

### Example Test App
The `example_multiple_dirs_app.R` file provides a comprehensive test application demonstrating both single and multiple selection modes side by side.

## Future Enhancements

### Potential Improvements
1. **Keyboard shortcuts**: Add keyboard support for adding/removing directories
2. **Drag and drop**: Support for drag-and-drop directory selection
3. **Search functionality**: Add search/filter capabilities for large directory trees
4. **Selection persistence**: Remember selections across modal sessions
5. **Bulk operations**: Select all/none functionality

## Dependencies

### Required Packages
- `shiny`: Core Shiny functionality
- `fs`: File system operations
- `tibble`: Data frame operations
- `htmltools`: HTML generation
- `jsonlite`: JSON handling

### Browser Compatibility
- **Modern browsers**: Chrome, Firefox, Safari, Edge
- **JavaScript**: ES5 compatible
- **jQuery**: Required for DOM manipulation

## Conclusion

This enhancement successfully adds multiple directory selection functionality to the shinyFiles package while maintaining full backward compatibility. The new feature provides an intuitive user interface that allows users to build a list of selected directories through a simple click-and-add workflow, making it much more user-friendly than modifier-key-based selection methods.

The implementation follows the existing package patterns and coding style, ensuring consistency and maintainability. All changes are well-documented and tested, providing a robust foundation for future enhancements.
