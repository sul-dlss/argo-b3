# Design deviations

Known places where existing code doesn't conform to `DESIGN_STANDARDS.md`. This is a checklist, not a standard: delete an entry when it's fixed. Rule IDs refer to `DESIGN_STANDARDS.md`. WCAG failures come first; within each section, entries are one per instance (`file:line`).

Contrast figures are computed from the declared colors, not measured in a browser; confirm with a contrast checker when fixing.

## WCAG failures

### Page structure (WCAG 3.1.1, 2.4.1, 1.3.1, 2.4.2)

- [ ] PAGE-1 `app/views/layouts/application.html.erb:3`: `<html>` has no `lang`.
- [ ] PAGE-1 `app/views/layouts/application.html.erb:61`: the page content (`yield`) is not in a `<main id="main-container">`.
- [ ] PAGE-1 `app/views/layouts/application.html.erb`: no `SkipLinksComponent`.
- [ ] PAGE-2 Pages that set no title, so show the layout's fallback "Argo B3":
  - [ ] Registration and edit: `items/new`, `items/edit`, `collections/new`, `apos/new`, `apos/edit`, `agreements/new`, `administrative_tags/edit`, `item_releases/new`, `contents/edit`, `content_mount/new`, `content_globus/new`, `content_structure/edit`, `multiple_items/new`, `multiple_items/show`, `multi_item_deposit_globus/new`.
  - [ ] Bulk actions: `bulk_actions/index`, `bulk_actions/new`, `bulk_actions/show`, and every `bulk_actions/*/new` (title can be set once in `BulkActions::FormComponent`).
  - [ ] `reports/show`, `multi_item_deposit_actions/wait`.
  - [ ] Admin: `admin/impersonation/edit`, `admin/object_permissions/index`, `admin/workgroup_permissions/index`, `admin/workgroup_permissions/edit`.
- [ ] PAGE-2 Pages that set a title without the `| Argo B3` suffix: `dashboard/index:1`, `objects/show:1`, `search/show:1`, `workflow_grid/show:1`, `multi_item_deposit_actions/{index,show,discovery,structure,deposit}:1`.
- [ ] PAGE-2 `app/views/dashboard/index.html.erb:1`: title "Dashboard" doesn't match the h1 "Argo dashboard".
- [ ] PAGE-3 `app/views/reports/show.html.erb`: no h1 (the page starts with a fieldset legend).

### Keyboard (WCAG 2.1.1)

- [ ] A11Y-1 / TABLE-7 `app/components/show/content_file_binary_row_component.rb:39-46`: expandable `<tr>` toggled by `data-bs-toggle`; not keyboard operable.
- [ ] A11Y-1 / TABLE-7 `app/components/show/event_rows_component.rb:66-75`: same.

### Names and labels (WCAG 4.1.2, 1.3.1, 2.4.4)

- [ ] ICON-3 `app/components/search/facet_value_component.html.erb:17-19`: icon-only exclude link named only by `title`.
- [ ] ICON-3 `app/components/elements/selected_item_component.html.erb:4`: remove button with `label: ''`, named only by `title`.
- [ ] TABLE-2 Empty column headers (`label: ''`):
  - [ ] `app/components/bulk_actions/history_section_component.html.erb:33`
  - [ ] `app/components/edit/content_file_binaries_component.html.erb:9`
  - [ ] `app/views/admin/object_permissions/index.html.erb:42`
  - [ ] `app/views/admin/workgroup_permissions/edit.html.erb:37`
- [ ] FORM-2 `app/components/search/facet_search_component.html.erb:8`: placeholder used without a label.
- [ ] HEAD-4 `app/views/objects/show.html.erb:24-30`: pin button and "Read only" badge inside the h1, so the heading reads "<title> Pin Read only".

### Announcements (WCAG 4.1.3)

- [ ] A11Y-7 `app/views/contents/edit.html.erb:105`: dropzone error list is not a live region.
- [ ] A11Y-7 / FORM-6 `app/views/content_globus/new.html.erb:7`: error as `<p class="text-danger">`.
- [ ] A11Y-7 / FORM-6 `app/views/multi_item_deposit_globus/new.html.erb:3`: same.
- [ ] A11Y-7 `app/components/edit/file_set_component.html.erb:24`: "all files removed" note shown by JS without an announcement.
- [ ] A11Y-8 Self-refreshing pages without a status live region: `multiple_items/show`, `multi_item_deposit_actions/wait`, `multi_item_deposit_actions/show`, `bulk_actions/show`.

### Contrast (WCAG 1.4.3, 1.4.11)

- [ ] COLOR-2 / COLOR-3 `app/components/search/item_result_component.html.erb:36`: object-type pill uses normal-size bold text on the object-type color. Against the default text color this is about 4.4:1 (item), 4.45:1 (collection), 4.1:1 (APO), 4:1 (agreement), and 3.4:1 (virtual object), below 4.5:1.
- [ ] COLOR-2 `app/assets/stylesheets/search.scss:28`: `.selected-item-separator` `#adb5bd` on white, about 2:1.

### Heading order (WCAG 1.3.1)

- [ ] HEAD-1 Search page: h1 "Search" (`search/show:9`) is followed in the main column by a level-2 "Your selections" (`search/current_filters_component:4`) and then `<h3>` results (`search/items/index:4`) and `<h4>` per result; check the outline once raw headings are converted.
- [ ] HEAD-3 Text styled as a heading but not a heading element:
  - [ ] `app/components/show/file_set_component.html.erb:5` (`<span class="h3">`)
  - [ ] `app/components/edit/file_set_component.html.erb:4` (`<div class="h3">`)
  - [ ] `app/components/edit/content_file_component.html.erb:4` (`<div class="h4">`)
  - [ ] `app/components/report/fields_section_component.html.erb:1-3` (section label as a plain div)

## Consistency

- [ ] CONS-2 `app/views/reports/show.html.erb:3-30`: "Select source of items" radios copy `BulkActions::SelectSourceComponent` rather than sharing it (the copies already differ: legend wording and colon, raw fieldset, no item count).

## Sources

- [ ] SRC-1 Raw headings instead of `HeadingComponent`:
  - [ ] `app/views/search/items/index.html.erb:4`
  - [ ] `app/components/show/embargo_banner_component.html.erb:2`
  - [ ] `app/components/search/field_value_results_component.html.erb:2`
  - [ ] `app/components/search/loading_field_value_results_component.html.erb:2,7`
  - [ ] `app/components/search/loading_item_results_component.html.erb:2`
  - [ ] `app/components/search/result_heading_component.html.erb:1`
  - [ ] `app/components/search/facet_section_component.html.erb:3`
  - [ ] `app/components/search/loading_facet_section_component.html.erb:3`
- [ ] SRC-1 Raw `<hr>`: `app/views/admin/object_permissions/index.html.erb:36`, `app/views/admin/workgroup_permissions/edit.html.erb:29`.
- [ ] SRC-1 Raw `<button>`: `app/views/reports/show.html.erb:43,45`.
- [ ] SRC-1 Raw `.btn` spans for disabled previous / next: `app/components/search/item_navigation_component.html.erb:12,23`.
- [ ] SRC-1 Raw card markup instead of `CardComponent`:
  - [ ] `app/components/show/file_set_component.html.erb:2,55`
  - [ ] `app/components/edit/file_set_component.html.erb:2,6`
  - [ ] `app/components/edit/content_file_component.html.erb:2`
  - [ ] `app/views/objects/show_dro_overview.html.erb:64,74`
- [ ] SRC-1 Raw form fields instead of field components:
  - [ ] `app/components/search/checkbox_facet_input_component.html.erb:1-3`
  - [ ] `app/components/search/facet_search_component.html.erb:3-8`
  - [ ] `app/components/admin/impersonation_workgroups_component.html.erb:5-9`
  - [ ] `app/components/report/fields_section_component.html.erb:5-17`
  - [ ] `app/views/reports/show.html.erb:3-4,39-40` (raw fieldset / legend)
- [ ] SRC-2 Date fields have no shared component: `app/components/search/dynamic_facet_component.html.erb:21-27`.
- [ ] SRC-2 Ad hoc badges instead of a shared component: `app/views/objects/show.html.erb:20,28`, `app/components/bulk_actions/show_component.html.erb:8`, `app/components/search/item_result_component.html.erb:36`.

## Page structure

- [ ] PAGE-5 `app/views/search/items/index.html.erb:10`: `div role="navigation"` instead of `<nav>`.
- [ ] PAGE-5 `app/components/elements/pagination/brief_component.html.erb:2`: `<nav>` without `aria-label`.

## Headings

- [ ] HEAD-4 `app/components/show/embargo_banner_component.html.erb:2-3`: edit icon inside the h2 (and nothing to act on; see ICON-4).
- [ ] HEAD-3 Labels styled as headings: `app/components/edit/apo_fields_component.html.erb:14` (`label_classes: 'h3'`), `app/views/multi_item_deposit_actions/discovery.html.erb:20` (`label_classes: 'h2'`).

## Layout and spacing

- [ ] LAY-1 Container not `container py-2`:
  - [ ] `container mt-3`: `bulk_actions/new:1`, `dashboard/index:8`, `bulk_actions/history_section_component:1`, `multi_item_deposit/history_section_component:1`
  - [ ] `container my-2`: `search/show:8`, `workflow_grid/show:8`
  - [ ] `container pb-3`: `admin/object_permissions/index:6`, `admin/workgroup_permissions/index:1`, `admin/workgroup_permissions/edit:6`
  - [ ] `container my-3`: `bulk_actions/form_component:1`
  - [ ] plain `container`: `admin/impersonation/edit:1`, `search/layout_component:1`
  - [ ] `container ... mb-4`: `objects/show:10`, `bulk_actions/show_component:1`
- [ ] LAY-2 h1 margin not `mb-3`: `mb-4` (7 pages), `mb-5` (`bulk_actions/form_component:2`), `mb-0` (`bulk_actions/show_component:7`), none (edit pages followed by `<p class="mb-4">`).
- [ ] LAY-2 Form footer not `mt-5`: `admin/workgroup_permissions/edit:23` (`mt-3`), forms using `mt-4`, `reports/show:65` (`my-3`).
- [ ] LAY-2 `app/views/dashboard/index.html.erb:63,65`: sections without the `mb-5` wrapper.
- [ ] LAY-3 Inline styles:
  - [ ] `app/views/layouts/application.html.erb:57` (`z-index`)
  - [ ] `app/views/dashboard/index.html.erb:26` (`width: fit-content`)
  - [ ] `app/components/bulk_actions/list_section_component.html.erb:11` (`font-weight`)
  - [ ] `app/components/workflow_grid/workflow_table_component.html.erb:22-29` (placeholder widths)

## Typography

- [ ] TYPE-2 `font-size` in app SCSS: `application.bootstrap.scss:78`, `forms.scss:3`, `show.scss:181`, `progress_stepper.scss:65,76`, `search.scss:29`. (`dropzone.scss` is a vendor copy.)
- [ ] TYPE-4 `app/views/objects/show.html.erb:28`: `fw-semibold`.

## Color

- [ ] COLOR-1 Non-palette colors:
  - [ ] `application.bootstrap.scss:27-28`: item `#B98A00`, collection `#DA7A00`
  - [ ] `application.bootstrap.scss:91`: `#EDEFE1` (impersonation banner)
  - [ ] `application.bootstrap.scss:100-103`, `show.scss:70,127-130`: `black`
  - [ ] `search.scss:28`: `#adb5bd`
  - [ ] `show.scss:199`: `#ad4e00` (`.workflow-in-progress`)
  - [ ] `bl_facets.scss`: `--bs-*` variables rather than Stanford palette

## Buttons

- [ ] BTN-1 / BTN-3 `app/components/bulk_actions/form_component.html.erb:22-23`: "Submit" label, and Cancel (raw `link_to`) after the submit button. Affects every bulk action form.
- [ ] BTN-1 `app/views/dashboard/index.html.erb:26`: "Go".
- [ ] BTN-3 `app/components/edit/file_set_component.html.erb:28-29`: Cancel after Save.
- [ ] BTN-2 `app/views/reports/show.html.erb:66-67`: "Download" and "Preview" both primary.
- [ ] BTN-2 "Filter" is outline in `bulk_actions/history_section_component:17` and `multi_item_deposit/history_section_component:15`, primary elsewhere.
- [ ] BTN-6 Placeholders linking to `/` or `#` (disabled, but rendered as links): `app/views/objects/show.html.erb:45,80,81`, `app/components/header_component.html.erb:53`. Check that the gem's disabled rendering removes the `href`.

## Unavailable actions

- [ ] AVAIL-2 Inline actions hidden without permission (should be disabled, as the matching left-nav buttons are): Manage tags pencil (`app/components/show/tag_component.html.erb:2`), Manage release pencil (`app/components/show/released_to_component.html.erb:2`).
- [ ] AVAIL-4 Disabled for state without a visible reason:
  - [ ] Republish when never published (`app/views/objects/show.html.erb:56`)
  - [ ] Manage release when not manageable (`app/views/objects/show.html.erb:62`)
  - [ ] Discard / Purge when not available (`app/views/objects/show.html.erb:79`)
  - [ ] File deletion while discovery runs (`app/views/contents/show.html.erb:7`); check whether the page already says discovery is running
  - [ ] Multi-Item Deposit Next before discovery / structuring succeeds (`app/views/multi_item_deposit_actions/discovery.html.erb:112`, `app/views/multi_item_deposit_actions/structure.html.erb:107`)
  - [ ] Status box Edit when the version isn't editable (`app/components/show/status_component.html.erb:7`); for collections and agreements, which can't be edited yet, this is a placeholder (BTN-6) instead
- [ ] AVAIL-5 Disabled options without help text: "From last search" when there is no last search (`app/components/bulk_actions/select_source_component.html.erb:11`, `app/views/reports/show.html.erb:10`), "Follow collection" once the item has its own tag (`app/components/edit/release_tags_component.rb:36`).

## Forms

- [ ] FORM-1 No `.b3-form` / `.tab-form` wrapper:
  - [ ] `app/views/admin/workgroup_permissions/edit.html.erb:12`
  - [ ] `app/views/admin/impersonation/edit.html.erb:4`
  - [ ] `app/views/admin/object_permissions/index.html.erb:14`
  - [ ] `app/views/reports/show.html.erb:2`
  - [ ] `app/views/content_mount/new.html.erb:6`
  - [ ] `app/components/edit/file_set_component.html.erb:7`
  - [ ] `app/views/content_structure/edit.html.erb:36`
- [ ] FORM-2 Text styled as a label but not a `<label>`: `app/views/admin/workgroup_permissions/edit.html.erb:15`, `app/views/multiple_items/new.html.erb:44`, `app/components/edit/catalog_record_id_component.html.erb:37`.
- [ ] FORM-5 `app/components/report/fields_section_component.html.erb:12`: help text as `<small class="form-text text-muted">`, not attached to the field.
- [ ] FORM-9 Selects with 2 options (use radios): viewing direction (`app/components/edit/viewing_direction_component.html.erb:1`), collection view access (`app/views/collections/new.html.erb:37-45`).
- [ ] FORM-11 Yes / No ordered No then Yes: `app/components/edit/ocr_component.html.erb:10,17`, `app/components/edit/speech_to_text_component.html.erb:8-9`.

## Tables

- [ ] TABLE-4 Hand-written empty states: `app/views/objects/show_events.html.erb:19-20`, `app/views/technical_metadata/show.html.erb:5` (also missing the period), `app/views/content_structure/edit.html.erb:9`.
- [ ] TABLE-5 Symbols or uneven wording in headers: "# of constituents", "# of items", "# of collections" (`objects/show_admin_policy_overview:10` and similar), "Total / Success/ Failed" (`bulk_actions/history_section_component:31`), "Unpin" as a column header (6 dashboard pinned tables).
- [ ] TABLE-6 Inline column widths:
  - [ ] `app/components/bulk_actions/history_section_component.html.erb:24-33`
  - [ ] `app/components/multi_item_deposit/table_component.html.erb:2-9`
  - [ ] `app/components/workflow_grid/workflow_table_component.html.erb:8-13`
  - [ ] `app/components/show/content_file_binaries_component.html.erb:6`
  - [ ] `app/components/show/file_set_component.html.erb:59`
  - [ ] `app/components/edit/content_file_binaries_component.html.erb:6`

## Links

- [ ] LINK-1 Link text that doesn't stand alone:
  - [ ] "More »": `app/components/search/facet_page_link_component.html.erb:2`, `app/components/search/field_value_results_component.html.erb:9`
  - [ ] "Log file" repeated per row: `app/components/bulk_actions/history_row_component.rb:24`, `app/components/bulk_actions/show_component.rb:107`
  - [ ] "PURL": `app/components/show/version_row_component.rb:37`
  - [ ] Bare-number links: `app/views/objects/show_collection_overview.html.erb:10`, `app/views/objects/show_admin_policy_overview.html.erb:14,20`
- [ ] LINK-2 `target: '_blank'` instead of `link_to_new_tab`: `app/views/multi_item_deposit_globus/new.html.erb:9`, `app/views/content_globus/new.html.erb:14`.
- [ ] LINK-2 New-tab links without the icon and "(opens in new tab)": all `link_to_new_tab` uses (`app/helpers/link_helper.rb:16-18`, so it can be fixed in the helper) and the report download (`app/views/reports/show.html.erb:66`, `formtarget: '_blank'`). Only `app/components/show/version_row_component.rb:52` shows the icon.

## Icons

- [ ] ICON-1 `app/components/elements/progress_stepper_step_component.html.erb:5`: raw `<i class="bi bi-check-lg">`.
- [ ] ICON-1 `app/assets/stylesheets/search.scss:60-66`: CSS-injected icon (`content: "\F633"`).
- [ ] ICON-1 `app/assets/stylesheets/bl_facets.scss:63,142-143`: inline SVG data URIs.
- [ ] ICON-2 Icons beside text without `aria-hidden`:
  - [ ] `app/views/contents/edit.html.erb:107`
  - [ ] `app/views/multi_item_deposit_actions/discovery.html.erb:113`
  - [ ] `app/views/multi_item_deposit_actions/structure.html.erb:105,108`
  - [ ] `app/views/multi_item_deposit_actions/deposit.html.erb:43`
  - [ ] `app/components/item/tab_navigation_component.html.erb:10`
  - [ ] `app/views/content_structure/edit.html.erb:72`
  - [ ] `app/components/bulk_actions/history_row_component.rb:20,31`
  - [ ] `app/components/item/discard_or_purge_button_component.html.erb:8`
  - [ ] `app/components/search/facet_value_component.html.erb:6,18`
  - [ ] `app/components/search/hierarchical_value_component.html.erb:6-7`
  - [ ] Pin icon in the caption of the 6 `app/components/dashboard/pinned_*_table_component.html.erb:9`
- [ ] ICON-4 `app/components/show/embargo_banner_component.html.erb:3`: edit icon with no action.

## Feedback

- [ ] FEED-2 `flash[:success]`: `app/controllers/admin/impersonation_controller.rb:23,33` (use a toast).
- [ ] FEED-2 `flash[:warning]` for messages that are errors (use `flash[:danger]`): `app/controllers/application_controller.rb:22` (not authorized), `app/controllers/admin/impersonation_controller.rb:19` (invalid), `app/controllers/multiple_items_controller.rb:27` (registration failed). Review `item_releases_controller.rb:56` and `objects_controller.rb:188` too.
- [ ] FEED-4 `app/components/search/loading_field_value_results_component.html.erb:2`: text "(Loading ...)" instead of a spinner or skeleton.

## Copy

- [ ] COPY-2 Title Case: "Select All" / "Deselect All" (`app/views/reports/show.html.erb:43,45`).
- [ ] COPY-3 Acronyms: "SOLR doc" (`app/views/objects/show.html.erb:123`), "Folio Instance HRID" (`app/views/objects/show_collection_overview.html.erb:5`, `app/views/objects/show_dro_overview.html.erb:42`).
- [ ] COPY-3 Release target labels "Searchworks", "Earthworks" (`app/services/constants.rb:12-13`, label only; the values are API values), and help text "For example: Searchworks" (`app/services/reports/fields.rb:190`).
- [ ] COPY-4 Trailing colons:
  - [ ] "Upload structural CSV:", "Download:" (`app/views/content_structure/edit.html.erb:45,63`)
  - [ ] "From:", "To:" (`app/components/search/dynamic_facet_component.html.erb:21-27`)
  - [ ] Legends (`app/views/reports/show.html.erb:4,40`)
  - [ ] "Your selections:" (`app/components/search/current_filters_component.html.erb:4`)
- [ ] COPY-5 "Register & deposit single object" (`app/views/dashboard/index.html.erb:30`).
- [ ] COPY-8 Counts without `number_with_delimiter`: `app/views/reports/show.html.erb:16`, `app/views/objects/show_collection_overview.html.erb:10`, `app/views/objects/show_admin_policy_overview.html.erb:14,20`, `app/views/objects/show_constituents.html.erb:3`.

## Tooling

- [ ] Enable the herb accessibility rules that are off by default, then mark the matching rules *(linted)* in `DESIGN_STANDARDS.md`: `a11y-avoid-generic-link-text` (LINK-1), `a11y-nested-interactive-elements` (A11Y-6), `html-navigation-has-label` (PAGE-5), `html-no-title-attribute` (ICON-3).
