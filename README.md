# NP Sync
A simple utility to help me with syncing hard disks.  It asks you for a primary and replica drive, and generates listss of files to assist with syncing the two.  Currently it doesn't move or delete any files, just generate the lists.

- `dup_primary.tsv` and `dup_replica.tsv` are lists of presumed duplicate files. For speed, it estimates this using the modified date, file size, and first 8 bytes of content. This generates false positives, especially for automatically-generated files. Use discretion when cleaning up duplicates.
- `mismatch.tsv` indicates files that are different between disks, using the same content-estimation method described above. It also lists which drive it considers the "better" source of truth, based first on modified time (date), and then size if they were modified at the same time.
- `missing.tsv` lists files that were not found in the replica drive. Next to the file is the location of a file that's presumably the same content, so they can be moved instead of copied across drives.

I made this because I have two hard disks with 100k-150k files that I want synchronized. Just dragging and dropping them takes a few hours for Windows to enumerate and figure out which files to move. The utility takes a couple minutes, since it takes some shortcuts.

Potential future improvements:
- Automatically move missing files (will need enhanced content verification to ensure they're actually the same).
- Provide assistant to automatically resolve mismatches
- List files missing in the primary drive (presumably these should be deleted)
