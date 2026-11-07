**Fixed**
- **Data a mod saves with `saveModData` survives a restart**: it was kept in a form the state file cannot hold, so it was lost after a restart and `getModData` then failed in that mod's start. It is kept as text now; data saved by an older version could not be kept and is replaced with the mod's default once.
