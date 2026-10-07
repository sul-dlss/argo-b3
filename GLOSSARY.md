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
