# Glossary

## Domain Terms

### DRO (Digital Repository Object)
A "work" managed in the SDR: describable, versioned digital content with access rights and structural metadata. DRO is a superset covering three subtypes distinguished by role, not just content type: **Item**, **Agreement**, and **Virtual Object**.

### Item
A DRO that is not an Agreement and not a Virtual Object. This is the default/common case — most content types (book, image, 3d, map, page, etc.) are Items unless they specifically serve one of the other two roles.

### Agreement
A DRO identified by its content type (`agreement`). Represents an agreement (e.g., a deposit or licensing agreement) rather than descriptive/curatorial content. An APO references one Agreement via its `hasAgreement` relationship (see below). Agreements are always dark.

### Virtual Object
A DRO identified by a **structural** distinction, not by content type: its structural metadata references/borrows constituent resources from other objects, rather than the DRO being a standalone work in its own right. Because this is structural rather than a `type` value, a Virtual Object can carry any content type — the same content type space Items use.

### Collection
A grouping of DROs for conceptual/curatorial purposes, reusable across the system. A DRO may be a member of a Collection (`isMemberOf`). Membership is **one level only** — a Collection cannot itself be a member of another Collection.

### APO (Administrative Policy Object AKA Admin Policy)
Governs the administrative/access rules applied to the objects under it. "APO" and "AdminPolicy" are used interchangeably but APO is the preferred term. Distinct from the "governs" relationship is the APO's own `hasAgreement` reference to an Agreement DRO.

### Governing APO
The `hasAdminPolicy` relationship: every object (DRO, Collection, or APO) has exactly one governing APO. The relationship means the same thing regardless of the subject's type — including when the subject is itself an APO (an APO can be governed by another APO).

### Object Access
The access (view, download, location) of a DRO as a whole. It applies now, during any embargo; an embargo's access replaces it when the embargo is released.

### File Access
The access of an individual file. New files get the Object Access, with citation-only becoming dark, since a file cannot be citation-only. The files of a dark object must be dark and unshelved. When an embargo is released, every file gets the embargo's access.

### Overwrite File Access
Applying the Object Access to every file when saving an item whose Object Access changed. It always happens when the object is dark, which also unpublishes the files; a file that is then neither preserved, shelved, nor published (e.g., a derivative) is removed, along with any Resource it empties.

### Version
A numbered state of an object in SDR; a new version is opened for changes and closed when deposited. DSA stores cocina for each version except legacy versions, and a version's stored cocina may no longer be valid against the current cocina models.

### User Version (AKA Public Version)
A Version made publicly available on PURL, numbered separately from Versions. The latest User Version is shown at the object's PURL; earlier ones at `<purl>/<druid>/version/<user version>`. A User Version other than the latest can be withdrawn, removing it from PURL, and later restored. When an object is made dark, all User Versions other than the latest are permanently withdrawn and can't be restored.

### Draft
The changes in an object's open version that have not yet been deposited. Discarding a draft deletes the open version, returning the object to its last closed version, and deletes the draft's Mutable Content and staged files. A first version cannot be discarded, but it can be purged.

### Deposit
Submitting a Draft for accessioning. If the object is a DRO with files, depositing starts an assembly workflow (e.g., to create derivatives, including for files deposited in earlier versions), which closes the version once assembly is done; otherwise it closes the version directly, which starts accessioning. A geo object goes through assembly only when it has staged files. A web archive seed always goes through assembly, with or without files, since its assembly generates its description and thumbnail (or keeps those it already has). Depositing from manage files stages the Mutable Content first; depositing from elsewhere (e.g., the edit item form or the status box) deposits the structure as last staged, so it is not possible while the Mutable Content has unsaved changes.

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
A single user-run deposit of many Items whose files are on a mount, carried out in steps: discovery, structure, and deposit. The deposit step is initiated once a version is open and staging has started for every Item Deposit; staging and accessioning then proceed for each Item independently.

### Item Deposit
One Item within a Multi-Item Deposit, identified by its druid and its folder on the mount.

### Workgroup
A named group of users (e.g., `sdr:map-staff`) managed outside Argo. Permissions are granted to workgroups, never to individual users.

### Impersonation
An admin temporarily acting with the permissions of one or more chosen Workgroups instead of their own, to see what members of those Workgroups can see and do.
### File Flag
An underscore-separated token in an SMPL filename that describes the file rather than the content (e.g., `pm` preservation master, `sl` service low, `cap` caption, `script` transcript). Files of the same recording share a filename once role and processing flags (`pm`, `sh`, `sl`, `sp`) and the `thumb`, `cap`, and `script` flags are removed, along with a caption's language tag before `cap` (e.g., `_es_cap`); other flags (side, part, track, etc.) distinguish recordings.

## Structural Metadata Terms
Structural metadata (file sets and files) is held in Active Record models rather than cocina models. See README "Structural metadata" for the full model and flows.

### Lock
The cocina object's optimistic locking key (`cocina_object.lock`, only present on `*WithMetadata` cocina objects). It changes whenever the object is updated, so a lock identifies one state of the object.

### Content
The structure of a DRO for one lock: ordered `ContentFileSet`s holding ordered `ContentFile`s, each pointing to a `ContentFileBinary` (the physical file, identified by filepath and possibly shared by several `ContentFile`s). Identified by druid + lock + immutable (a unique index), so a druid/lock has at most one immutable and one mutable Content.

### Resource
One ordered `ContentFileSet` within a Content, typed by its role (e.g., a `page` of a book, an `object`). Use "Resource" when talking to users; it is the same thing as a ContentFileSet (a cocina FileSet).

### Hierarchical Filepath
A file's filepath that includes directories (e.g., `folder1/image1.tif`) rather than a bare filename. Only the file (`object`) and geo content types may have hierarchical filepaths; DSA rejects them for all other content types. Use "hierarchical filepaths" rather than "files in folders".

### Immutable Content
A Content that exactly reflects the cocina object's structural metadata at its lock. Use it for anything that shows or exports what was deposited (e.g., the Files tab, structural CSV download from the object page).

### Mutable Content
A Content being edited (uploads, discovery, reordering, structural CSV import); it may deviate from the cocina object. It reaches the cocina object only through **staging**. While the version is open, it moves to each new lock of the object (e.g., after a draft save or an item edit), and it holds the OCR settings (whether to run OCR and in which languages) used when depositing.

### Unsaved Changes
Changes to a Mutable Content that have not been staged to the cocina object, such as new files or edited resources. Saving as a draft or depositing from manage files stages them; discarding the Draft deletes them.

### Staging
Saving a mutable Content to the cocina object (`StageFilesJob`): `CocinaObjectMutators::StructuralMutator` rebuilds the cocina structural metadata from the Content and `Sdr::Repository.update` saves it. When depositing, the Content becomes immutable for the new lock and accessioning starts; when saving as a draft, the Content stays mutable and moves to the new lock.
