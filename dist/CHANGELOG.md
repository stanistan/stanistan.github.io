+++
title = "Changelog"
path = "CHANGELOG"
+++


__All notable changes to this project will be documented in this file.__

This is based off of [keepachangelog.com](https://keepachangelog.com/en/1.0.0/).

There are no real _releases_, or _tags_ here since this is not a library
or anything, but I felt like it would be fun (besides just git history)
to keep a log of how the site has changed over time.

This should be in reverse chronological order.

### 2019-11-14

#### New

- Adding a `CHANGELOG.md`, which is symlinked and served as `/CHANGELOG`.

#### Updated

- The post [How this site works](@/writes/2019/11/10/how-this-blog-works.md)
  was updated to reflect the fixes in the section below.

#### Fixed

- No longer have to deal with weird `master` merge issues because
  `bin/ship` force pushes master. This was a problem before because
  the master branch _needs_ to have a `CNAME` file for custom domains
  to work well. Fixed by symlinking it to `static/` the same way that
  the REAMDE is, and this file is.
