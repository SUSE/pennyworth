# Pennyworth Contribution Guidelines

Pennyworth is an open project and welcomes contributions. We have written these
guidelines so you know how the project works, and to make contributions smooth
and fun for everybody involved.

There are two main forms of contribution: reporting bugs and performing code
changes.

## Bug Reports

If you find a problem with Pennyworth, report it using [GitHub
issues](https://github.com/SUSE/pennyworth/issues/new). When creating a bug
report, make sure you include:

  1. Steps to reproduce the bug
  2. What you expected to happen
  3. What happened instead

This information will help to determine the cause and prepare a fix as fast as
possible.

## Code Changes

Code contributions come in various forms and sizes, from simple bug fixes to
significant refactorings and implementation of new features. Before making any
non-trivial change, get in touch with Pennyworth developers first. This can
prevent wasted effort later.

To send your code change, use GitHub pull requests. The workflow is as follows:

  1. Fork the project.

  2. Create a topic branch based on `master`.

  3. Implement your change, including tests and documentation.  Make sure you
     adhere to the [Ruby style
     guide](https://github.com/SUSE/style-guides/blob/master/Ruby.md).

  4. Run tests using `rake spec` to make sure your change didn't break anything.

  5. Publish the branch and create a pull request.

  6. Pennyworth developers will review your change and possibly point out
     issues. Adapt the code under their guidance until all issues are resolved.

  7. Finally, the pull request will get merged or rejected.

See also [GitHub's guide on
contributing](https://help.github.com/articles/fork-a-repo).

If you want to do multiple unrelated changes, use separate branches and pull
requests.

### Commits

Each commit in the pull request should do only one thing, which is clearly
described by its commit message. Especially avoid mixing formatting changes and
functional changes into one commit. When writing commit messages, adhere to
[widely used
conventions](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

# Additional Information

If you have any question, feel free to ask on the [Machinery mailing
list](http://lists.suse.com/mailman/listinfo/machinery). We'll do our best to
provide a timely and accurate answer.
