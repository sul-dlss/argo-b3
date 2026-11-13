# Screencasts of argo-b3

## Running the app

Follow README "Development": `docker compose up -d` (Postgres, Redis, Solr, DSA, SURI), `bin/rails db:prepare`, then `PORT=<free port> bin/dev` from this checkout. If Docker isn't running, start it first.

- **Whose server is it?** Before trusting a server already on a port, confirm it runs from this checkout: `lsof -a -p "$(lsof -nP -iTCP:<port> -sTCP:LISTEN -t | head -1)" -d cwd -Fn` prints its directory.
- **Stopping**: `bin/overmind quit`, run from the checkout that started it.

`bin/dev` signs every request in as a development user (`USER_GROUPS`, `NAME`, `EMAIL`; defaults in `bin/dev`), an admin by default. The `User` record is created on the first request, so load a page before seeding records owned by it.

## Demo data

- **Agreements, APOs, collections**: `bin/rake development:bootstrap_agreement`, `development:bootstrap_apo` (`AGREEMENT_DRUID=`), or `"development:bootstrap_collection[<APO druid>]"`, each with an optional `TITLE=`. Then run `bin/rake "development:complete_workflows[<druid>]"` so the object is accessioned and editable. Each prints the new druid.
- **Depositing consumes the object**: after a deposit beat, the object is accessioning until `complete_workflows` runs again. Bootstrap a fresh object per take.
- **Records only in argo-b3's database** (e.g., Multi-Item Deposits and their Item Deposits): create them with `bin/rails runner <script>`, owned by `User.find_by!(email_address: '<EMAIL from bin/dev>')`.

## Known UI traps

- On tabbed edit forms, the Deposit tab and the Deposit submit button share a name; click the submit with `.and(page.locator('[type=submit]'))`.
- After a validation error, tab out of a corrected field before clicking a footer button: clearing the error moves the footer.
