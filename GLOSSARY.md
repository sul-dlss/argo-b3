# Glossary

## Domain Terms

### DRO (Digital Repository Object)
A "work" managed in the SDR: describable, versioned digital content with access rights and structural metadata. DRO is a superset covering three subtypes distinguished by role, not just content type: **Item**, **Agreement**, and **Virtual Object**.

### Item
A DRO that is not an Agreement and not a Virtual Object. This is the default/common case — most content types (book, image, 3d, map, page, etc.) are Items unless they specifically serve one of the other two roles.

### Agreement
A DRO identified by its content type (`agreement`). Represents an agreement (e.g., a deposit or licensing agreement) rather than descriptive/curatorial content. An APO references one Agreement via its `hasAgreement` relationship (see below). Agreements are always dark. Its Resources are file Resources, each of which may hold several files (e.g., PDF and DOCX versions of the same terms of deposit).

### Virtual Object
A DRO identified by a **structural** distinction, not by content type: its structural metadata references/borrows constituent resources from other objects, rather than the DRO being a standalone work in its own right. Because this is structural rather than a `type` value, a Virtual Object can carry any content type — the same content type space Items use.

### Collection
A grouping of DROs for conceptual/curatorial purposes, reusable across the system. A DRO may be a member of a Collection (`isMemberOf`). Membership is **one level only** — a Collection cannot itself be a member of another Collection.

### APO (Administrative Policy Object AKA Admin Policy)
Governs the administrative/access rules applied to the objects under it. "APO" and "AdminPolicy" are used interchangeably but APO is the preferred term. Distinct from the "governs" relationship is the APO's own `hasAgreement` reference to an Agreement DRO.

### Governing APO
The `hasAdminPolicy` relationship: every object (DRO, Collection, or APO) has exactly one governing APO. The relationship means the same thing regardless of the subject's type — including when the subject is itself an APO (an APO can be governed by another APO).

### Druid
The unique identifier of an SDR object (e.g., `druid:bc123df4567`). Shown without the `druid:` prefix (e.g., `bc123df4567`) where space is limited.

### Object Access
The access (view, download, location) of a DRO as a whole. It applies now, during any embargo; an embargo's access replaces it when the embargo is released.

### File Access
The access of an individual file. New files get the Object Access, with citation-only becoming dark, since a file cannot be citation-only. The files of a dark object must be dark and unshelved. When an embargo is released, every file gets the embargo's access.

### Overwrite File Access
Applying the Object Access to every file when saving an item whose Object Access changed. It always happens when the object is dark, which also unpublishes the files; a file that is then neither preserved, shelved, nor published (e.g., a derivative) is removed, along with any Resource it empties.

### Preservation
SDR's archival store of every preserved file of each accessioned Version. It is not subject to File Access. A shelved file that is not preserved is copied from Stacks into Preservation when it is changed to preserved.

### Stacks
Where shelved files are served from (e.g., for PURL and file download), subject to their File Access.

### Version
A numbered state of an object in SDR; a new version is opened for changes and closed when deposited. DSA stores cocina for each version except legacy versions, and a version's stored cocina may no longer be valid against the current cocina models.

### User Version (AKA Public Version)
A Version made publicly available on PURL, numbered separately from Versions. The latest User Version is shown at the object's PURL; earlier ones at `<purl>/<druid>/version/<user version>`. A User Version other than the latest can be withdrawn, removing it from PURL, and later restored. When an object is made dark, all User Versions other than the latest are permanently withdrawn and can't be restored.

### PURL
The public web page for an object, showing its latest User Version. Dark objects and objects never published have no PURL page.

### Draft
The changes in an object's open version that have not yet been deposited. Discarding a draft deletes the open version, returning the object to its last closed version, and deletes the draft's Mutable Content and staged files. A first version cannot be discarded, but it can be purged.

### Deposit
Submitting a Draft for accessioning. If the object is a DRO with files, depositing starts an assembly workflow (e.g., to create derivatives, including for files deposited in earlier versions), which closes the version once assembly is done; otherwise it closes the version directly, which starts accessioning. A geo object goes through assembly only when it has staged files. A web archive seed always goes through assembly, with or without files, since its assembly generates its description and thumbnail (or keeps those it already has). Depositing from manage files stages the Mutable Content first; depositing from elsewhere (e.g., the edit item form or the status box) deposits the structure as last staged, so it is not possible while the Mutable Content has unsaved changes. A Bulk Action that closes versions deposits each object it changed, in the same way. If assembly stops with a Process in error, the Draft can be edited and saved, but not deposited; depositing resumes when the Process is retried.

### Single-Object Deposit
A Deposit a user starts for one object, from manage files, the edit item form, or the status box. Depositing a MID Item Deposit's object again from manage files is a Single-Object Deposit.

### Bulk Action Object Deposit
The Deposit of one object made by a Bulk Action, either Redeposit or a Bulk Action that closes versions. Use "Bulk Action Object Deposit" rather than "Bulk Action Deposit", which reads as the name of a Bulk Action.

### Deposit Lifecycle
The stages a Deposit passes through: **Initiating** (MID Item Deposits only, while Deposit Initiation runs), **Staging**, **Assembling** (an assembly workflow, e.g., `assemblyWF`, `gisAssemblyWF`, `ocrWF`, is active and the Version is still open), **Accessioning** (the Version is closed and `accessionWF` is active), and **Complete** (`accessionWF` has finished for the Version). Use "Accessioning" even though the UI labels that stage "Depositing", and "Complete" for what the UI shows as "Deposited".

### In Error
A Deposit is in error when Staging failed (fixed by saving or depositing again from manage files), an assembly workflow has a Process in error (an **Assembly error**), or `accessionWF` has a Process in error (an **Accessioning error**); the latter two are fixed by retrying the Process. A MID Item Deposit is also in error after a **Deposit start failure**, when its version could not be opened or its staging could not be started.

### Tracked Deposit
A Deposit started in Argo-B3, remembered with who deposited it from when it starts until it is Complete, so its outcome can be reported to that user.

### Purge
Permanently deleting an object from SDR, along with its Mutable Content and staged files. Only an object that has never been submitted for accessioning can be purged, which in practice means a first version. Unlike discarding a Draft, which returns the object to its last closed version, purging leaves no object behind.

### Last Updated
When, and by whom, an object was most recently registered, opened, updated, or closed. Other activity, such as accessioning or releasing, does not count.

### Release Tag
An instruction to release an object to (or withhold it from) a discovery target: SearchWorks, EarthWorks, or search engines (the PURL sitemap). Tags are only ever added, never deleted; for each target, an item's latest tag overrides its collections' tags, so an item that has its own tag for a target no longer follows its collection for that target. A collection's tag applies to its member items only when it releases the collection and its members.

### Tag
An administrative label on an object, made of two or more terms separated by ` : ` (e.g., `Project : Maps : 2024`), used to find and group objects in Argo; tags are not public. **Project** and **Ticket** tags are tags whose first term is `Project` or `Ticket`. Unlike Release Tags, tags can be changed and removed.

### Process
One step of a workflow (e.g., `shelve` in `accessionWF`) for one version of an object, performed by a robot. A process in error can be retried (set back to waiting, so it is queued again) by users who can edit the object; admins can also skip or complete it. Use "process" rather than "workflow step".

### Multi-Item Deposit
A single user-run deposit of many Items whose files are on a mount, carried out in steps: Discovery, File Check, and Deposit Initiation. It is **not submitted** until Deposit Initiation has started every MID Item Deposit, and **Submitted** from then on. A Submitted Multi-Item Deposit is **in progress** until it **settles**, when every MID Item Deposit is Complete or In Error: either **complete** (all Complete) or **with errors**. Do not shorten it to "MID" on its own; "MID" appears only in "MID Item Deposit".

### MID Item Deposit
One Item within a Multi-Item Deposit, identified by its druid and its folder on the mount. Once Deposit Initiation starts it, it is that Item's Deposit, and its outcome is reported only through the Multi-Item Deposit. Errors are recorded per MID Item Deposit and step, so a count of a step's errors is the number of MID Item Deposits with errors, not of error messages. Use "MID Item Deposit" rather than "Item Deposit".

### Discovery
The first step of a Multi-Item Deposit: checking each manifest row's folder on the mount and its object, and recording the folder's files. A **Discovery error** blocks File Check; a warning does not.

### File Check
The second step of a Multi-Item Deposit: configuring the deposit (e.g., OCR) and building and validating each MID Item Deposit's structure, from a structural metadata CSV or else by content type. A **File Check error** blocks Deposit Initiation; a warning does not. Use "File Check" rather than "structure step".

### Deposit Initiation
The last step of a Multi-Item Deposit: checking that every object can be deposited and, only if all can (a **Deposit Initiation error** on any stops all), starting each MID Item Deposit. Use "Deposit Initiation" rather than "deposit step".

### Bulk Action
An operation run in the background on many objects at once, chosen from a search or a list of druids, that produces a log of its results.

### Workgroup
A named group of users (e.g., `sdr:map-staff`) managed outside Argo. Permissions are granted to workgroups, never to individual users.

### Impersonation
An admin temporarily acting with the permissions of one or more chosen Workgroups instead of their own, to see what members of those Workgroups can see and do.
### File Flag
An underscore-separated token in an SMPL filename that describes the file rather than the content (e.g., `pm` preservation master, `sl` service low, `cap` caption, `script` transcript). Files of the same recording share a filename once role and processing flags (`pm`, `sh`, `sl`, `sp`) and the `thumb`, `cap`, and `script` flags are removed, along with a caption's language tag before `cap` (e.g., `_es_cap`); other flags (side, part, track, etc.) distinguish recordings.

### Pin
A user's bookmark of an object, search, or Tag, listed on that user's dashboard for quick access. Pins are personal and not visible to other users.

## Structural Metadata Terms
Structural metadata (file sets and files) is held in Active Record models rather than cocina models. See README "Structural metadata" for the full model and flows.

### Lock
The cocina object's optimistic locking key (`cocina_object.lock`, only present on `*WithMetadata` cocina objects). It changes whenever the object is updated, so a lock identifies one state of the object.

### Content
The structure of a DRO for one lock: ordered `ContentFileSet`s holding ordered `ContentFile`s, each pointing to a `ContentFileBinary` (the physical file, identified by filepath and possibly shared by several `ContentFile`s). Identified by druid + lock + immutable (a unique index), so a druid/lock has at most one immutable and one mutable Content.

### Resource
One ordered `ContentFileSet` within a Content, typed by its role (e.g., a `page` of a book, an `object`). Use "Resource" when talking to users; it is the same thing as a ContentFileSet (a cocina FileSet).

### Hierarchical Filepath
A file's filepath that includes directories (e.g., `folder1/image1.tif`) rather than a bare filename. Only the file (`object`) and geo content types may have hierarchical filepaths; DSA rejects them for all other content types. Use "hierarchical filepaths" rather than "files in folders", and "folder" for a directory of hierarchical filepaths.

### Folder
A directory in Hierarchical Filepaths (e.g., `folder1` in `folder1/image1.tif`), shown as a collapsible row when listing files. Folders are not stored on their own: a folder exists only while it contains a file, and it is not a Resource.

### Immutable Content
A Content that exactly reflects the cocina object's structural metadata at its lock. Use it for anything that shows or exports what was deposited (e.g., the Files tab, structural CSV download from the object page).

### Mutable Content
A Content being edited (uploads, discovery, reordering, structural CSV import); it may deviate from the cocina object. It reaches the cocina object only through **staging**. While the version is open, it moves to each new lock of the object (e.g., after a draft save or an item edit), and it holds the OCR settings (whether to run OCR and in which languages) used when depositing.

### Unsaved Changes
Changes to a Mutable Content that have not been staged to the cocina object, such as new files or edited resources. Saving as a draft or depositing from manage files stages them; canceling manage files or discarding the Draft deletes them.

### Staging
Saving a mutable Content to the cocina object (`StageFilesJob`): `CocinaObjectMutators::StructuralMutator` rebuilds the cocina structural metadata from the Content and `Sdr::Repository.update` saves it. When depositing, the Content becomes immutable for the new lock and accessioning starts; when saving as a draft, the Content stays mutable and moves to the new lock.
