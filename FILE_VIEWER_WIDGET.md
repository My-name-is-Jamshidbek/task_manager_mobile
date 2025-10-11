# File Viewer Dialog Widget

## Overview

The `FileViewerDialog` is a comprehensive file viewing and management widget that supports multiple file types including images, PDFs, documents, and more.

## Features

- ✅ **Image Preview**: Direct display of JPG, PNG, GIF, WebP, BMP images
- ✅ **File Type Recognition**: Smart icons and colors for different file types
- ✅ **Download**: Opens file download in browser
- ✅ **Share**: Share file download link
- ✅ **Open**: Open file in external applications
- ✅ **Multi-language**: English, Russian, Uzbek support
- ✅ **Error Handling**: Graceful error management
- ✅ **Responsive Design**: Works on different screen sizes

## Supported File Types

### Images

- JPG, JPEG, PNG, GIF, WebP, BMP (with preview)

### Documents

- PDF (red icon)
- DOC, DOCX, TXT, RTF (blue icon)
- XLS, XLSX, CSV (green icon)

### Media

- MP4, AVI, MOV, MKV (video icon)
- MP3, WAV, AAC, FLAC (audio icon)

### Archives

- ZIP, RAR, 7Z (archive icon)

## Usage

### Basic Usage

```dart
import '../../widgets/file_viewer_dialog.dart';

// Show file viewer dialog
await showFileViewer(
  context,
  fileId: 123,
  fileName: 'document.pdf',
  fileUrl: 'https://example.com/files/document.pdf', // Optional for preview
);
```

### In ListView (Example from ProjectDetailScreen)

```dart
ListTile(
  leading: Icon(Icons.picture_as_pdf),
  title: Text('document.pdf'),
  subtitle: Text('Click to view'),
  onTap: () => showFileViewer(
    context,
    fileId: file.id ?? 0,
    fileName: file.name,
    fileUrl: file.url,
  ),
)
```

## API Integration

The widget uses the `/files/{file}/download` endpoint:

- **URL**: `https://tms.amusoft.uz/api/files/{fileId}/download`
- **Method**: GET
- **Headers**:
  - `Authorization: Bearer {token}` (handled automatically)
  - `Accept: application/octet-stream`

## Localization Keys

### English

```json
"files": {
  "download": "Download",
  "downloading": "Downloading...",
  "open": "Open",
  "downloadSuccess": "File downloaded successfully",
  "downloadError": "Failed to download file",
  "openError": "Unable to open file"
}
```

### Russian

```json
"files": {
  "download": "Скачать",
  "downloading": "Скачивание...",
  "open": "Открыть",
  "downloadSuccess": "Файл успешно скачан",
  "downloadError": "Не удалось скачать файл",
  "openError": "Не удается открыть файл"
}
```

### Uzbek

```json
"files": {
  "download": "Yuklab olish",
  "downloading": "Yuklab olinyapti...",
  "open": "Ochish",
  "downloadSuccess": "Fayl muvaffaqiyatli yuklab olindi",
  "downloadError": "Faylni yuklab olishda xatolik",
  "openError": "Faylni ochib bo'lmaydi"
}
```

## Integration Points

### Project Files (✅ Already integrated)

- Location: `ProjectDetailScreen._filesSection()`
- Replaces direct URL opening with file viewer dialog

### Task Files (Ready for integration)

```dart
// In task detail or task list screens
onTap: () => showFileViewer(
  context,
  fileId: taskFile.id,
  fileName: taskFile.name,
  fileUrl: taskFile.url,
)
```

### User Profile/Settings Files

```dart
// For profile pictures, documents, etc.
onTap: () => showFileViewer(
  context,
  fileId: userFile.id,
  fileName: userFile.name,
  fileUrl: userFile.url,
)
```

## Technical Notes

- **Authentication**: Automatically uses current user's auth token
- **Error Handling**: Shows user-friendly error messages
- **File ID**: Required for download API, falls back to 0 if not available
- **File URL**: Optional, used for image previews
- **Browser Download**: Files are downloaded through system browser for better compatibility

## Future Enhancements (Optional)

- [ ] Local file caching for offline viewing
- [ ] PDF inline viewer using flutter_pdfview
- [ ] Video/audio playback widgets
- [ ] File upload from dialog
- [ ] Batch file operations

## Dependencies Used

- `share_plus`: For file sharing functionality
- `url_launcher`: For opening files/downloads in browser
- `flutter/material.dart`: UI components
