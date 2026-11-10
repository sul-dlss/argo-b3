# Design deviations

Known places where existing code doesn't conform to `DESIGN_STANDARDS.md`. This is a checklist, not a standard: delete an entry when it's fixed. Rule IDs refer to `DESIGN_STANDARDS.md`. Within each section, entries are one per instance (`file:line`).

## Consistency

- [ ] CONS-2 `app/views/reports/show.html.erb:3-30`: "Select source of items" radios copy `BulkActions::SelectSourceComponent` rather than sharing it (the copies already differ: legend wording and colon, raw fieldset, no item count).

## Sources

- [ ] SRC-1 Raw heading instead of `HeadingComponent`: `app/components/show/embargo_banner_component.html.erb:2`.
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

## Icons

- [ ] ICON-1 `app/components/elements/progress_stepper_step_component.html.erb:5`: raw `<i class="bi bi-check-lg">`.
- [ ] ICON-1 `app/assets/stylesheets/search.scss:60-66`: CSS-injected icon (`content: "\F633"`).
- [ ] ICON-1 `app/assets/stylesheets/bl_facets.scss:63,142-143`: inline SVG data URIs.
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
- [ ] COPY-5 "Register & deposit single object" (`app/views/dashboard/index.html.erb:30`).
- [ ] COPY-8 Counts without `number_with_delimiter`: `app/views/reports/show.html.erb:16`, `app/views/objects/show_collection_overview.html.erb:10`, `app/views/objects/show_admin_policy_overview.html.erb:14,20`, `app/views/objects/show_constituents.html.erb:3`.

## Tooling

- [ ] Enable the herb accessibility rules that are off by default, then mark the matching rules *(linted)* in `DESIGN_STANDARDS.md`: `a11y-avoid-generic-link-text` (LINK-1), `a11y-nested-interactive-elements` (A11Y-6), `html-navigation-has-label` (PAGE-5), `html-no-title-attribute` (ICON-3).
