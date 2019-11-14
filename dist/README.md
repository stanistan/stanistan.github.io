# www.stanistan.com

__All edits should happen on `the-details` branch.__ The `master`
branch is reserved for build output by [zola][zola], (the static
site generator).

- [the actual website][stanistan]

### Usage

For things that are _blog_-ish posts, they should be in the `content/writes`
directory, and have a specified `date` field in their front-matter.

The included `Makefile` has commands that make things easy to use.

#### `make serve-dev`

This starts the server in a dev configuration, showing drafts.

#### `make serve-prod`

Starts the server in a prod configuration, no drafts.

#### `make deploy`

Sets up the `the-detals` branch to be deployed, that content
is in its correct directories, there are no dead links, and then
ships the `DIST_DIR` to the `master` branch.

---

There are other sub-commands, but mostly these are the ones that matter.

[stanistan]: https://www.stanistan.com
[zola]: https://getzola.org
