# Glossary

## Domain Terms

### DRO (Digital Repository Object)
A "work" managed in the SDR: describable, versioned digital content with access rights and structural metadata. DRO is a superset covering three subtypes distinguished by role, not just content type: **Item**, **Agreement**, and **Virtual Object**.

### Item
A DRO that is not an Agreement and not a Virtual Object. This is the default/common case — most content types (book, image, 3d, map, page, etc.) are Items unless they specifically serve one of the other two roles.

### Agreement
A DRO identified by its content type (`agreement`). Represents an agreement (e.g., a deposit or licensing agreement) rather than descriptive/curatorial content. An APO references one Agreement via its `hasAgreement` relationship (see below).

### Virtual Object
A DRO identified by a **structural** distinction, not by content type: its structural metadata references/borrows constituent resources from other objects, rather than the DRO being a standalone work in its own right. Because this is structural rather than a `type` value, a Virtual Object can carry any content type — the same content type space Items use.

### Collection
A grouping of DROs for conceptual/curatorial purposes, reusable across the system. A DRO may be a member of a Collection (`isMemberOf`). Membership is **one level only** — a Collection cannot itself be a member of another Collection.

### APO (Administrative Policy Object AKA Admin Policy)
Governs the administrative/access rules applied to the objects under it. "APO" and "AdminPolicy" are used interchangeably but APO is the preferred term. Distinct from the "governs" relationship is the APO's own `hasAgreement` reference to an Agreement DRO.

### Governing APO
The `hasAdminPolicy` relationship: every object (DRO, Collection, or APO) has exactly one governing APO. The relationship means the same thing regardless of the subject's type — including when the subject is itself an APO (an APO can be governed by another APO).

## Structural Metadata Terms
Structural metadata (file sets and files) is held in Active Record models rather than cocina models. See README "Structural metadata" for the full model and flows.

### Lock
The cocina object's optimistic locking key (`cocina_object.lock`, only present on `*WithMetadata` cocina objects). It changes whenever the object is updated, so a lock identifies one state of the object.

### Content
The structure of a DRO for one lock: ordered `ContentFileSet`s holding ordered `ContentFile`s, each pointing to a `ContentFileBinary` (the physical file, identified by filepath and possibly shared by several `ContentFile`s). Identified by druid + lock + immutable (a unique index), so a druid/lock has at most one immutable and one mutable Content.

### Resource
One ordered `ContentFileSet` within a Content, typed by its role (e.g., a `page` of a book, an `object`). Use "Resource" when talking to users; it is the same thing as a ContentFileSet (a cocina FileSet).

### Immutable Content
A Content that exactly reflects the cocina object's structural metadata at its lock. Use it for anything that shows or exports what was deposited (e.g., the Files tab, structural CSV download from the object page).

### Mutable Content
A Content being edited (uploads, discovery, reordering, structural CSV import); it may deviate from the cocina object. It reaches the cocina object only through **staging**.

### Staging
Depositing a mutable Content (`StageFilesJob`): `CocinaObjectMutators::StructuralMutator` rebuilds the cocina structural metadata from the Content, `Sdr::Repository.update` saves it, and the Content becomes immutable for the new lock.
