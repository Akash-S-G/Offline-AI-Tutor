# Frontend PDF Installation Pipeline Audit

Generated: 2026-06-11

## Scope

Frontend installer only. Reader code was not modified.

Out of scope:

- PDF scanner
- PDF manifest generation
- textbook.json generation
- content.json generation
- chapter mapping
- PdfChapterReaderScreen
- PdfChapterLocator
- PdfViewerScreen
- TextbookRepository

## Installer Entry Point

Primary setup entry:

- `lib/features/onboarding/presentation/grade_sync_screen.dart`
- `GradeSyncScreen._startSync()`
- Calls `SyncManager.processPackUpdates()`

Manual content-pack entry:

- `lib/features/content_packs/presentation/content_pack_installer_screen.dart`
- Calls `ContentPackArchiveService.importPackArchive()`

## Download Service

Pack download:

- `lib/features/educational/application/sync_manager.dart`
- `PackDownloadOperation.execute()`
- Downloads pack archive from backend-provided `downloadUrl`
- Saves temporary archive under app documents `content_packs/{packId}.otpack`

PDF download:

- `lib/features/course/data/install/pdf_install_service.dart`
- Calls `GET /api/v1/pdf/resolve`
- Calls `GET /api/v1/pdf/file/{book_id}`
- Retries each backend operation up to 3 attempts

## Extraction Service

Pack extraction:

- `lib/features/content_packs/application/content_pack_archive_service.dart`
- `ContentPackArchiveService.importPackArchive()`
- Extracts `.otpack`, `.tar.gz`, or `.zip` archive
- Finds `pack_manifest.json` or `manifest.json`
- Resolves `contentDir`

## Chapter Install Location

Installed chapter root:

```text
ContentPackManifest.rootPath
```

Physical layout:

```text
content_packs/
  installed/
    incoming_x/
      chapter_folder/
        manifest.json
        content.json
        quizzes.json
        flashcards.json
        source.pdf
```

The reader already checks:

```text
chapter.rootPath/source.pdf
chapter.rootPath/textbook.pdf
```

So the installer now writes:

```text
chapter.rootPath/source.pdf
```

## Install Flow

```text
GradeSyncScreen
↓
SyncManager.processPackUpdates()
↓
PackDownloadOperation.execute()
↓
ContentPackArchiveService.importPackArchive()
↓
PdfInstallService.installChapterPdf()
↓
GET /api/v1/pdf/resolve
↓
GET /api/v1/pdf/file/{book_id}
↓
chapter.rootPath/source.pdf
↓
ContentPackRepository.upsertPack()
```

## Validation

After PDF save:

- `source.pdf` must exist
- file size must be greater than 0

If validation fails, the pack import throws and the install is incomplete.

## Reinstall Behavior

If `source.pdf` already exists and is non-empty:

- PDF download is skipped
- existing PDF is reused
- no overwrite occurs

## Installation Report

Each PDF install returns:

```text
chapterId
bookId
pdfDownloaded
pdfReused
pdfSize
installSuccess
failureReason
```

Reports are attached to `PackArchiveImportResult.pdfResults` and logged during sync.
