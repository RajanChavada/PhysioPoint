---
description: Delete and resync PhysioPoint in Downloads folder
---

# Resync Downloads

Deletes the existing PhysioPoint copy in ~/Downloads, replaces it with the current version from ~/Documents, and syncs the latest app sources into the .swiftpm bundle.

// turbo-all

1. Delete old copy and re-copy the full project:
```bash
rm -rf /Users/jimmychavada/Downloads/PhysioPoint && cp -R /Users/jimmychavada/Documents/PhysioPoint /Users/jimmychavada/Downloads/PhysioPoint && echo 'Redownload complete'
```

2. Sync app sources into the .swiftpm bundle in Downloads:
```bash
rsync -av --delete /Users/jimmychavada/Documents/PhysioPoint/app/Sources/PhysioPoint/ /Users/jimmychavada/Downloads/PhysioPoint/PhysioPoint.swiftpm/Sources/PhysioPoint/ && echo 'Sync to Downloads .swiftpm complete'
```
