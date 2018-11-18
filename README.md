Git Fatlas
==========

_Git ATLAS without the extra fat!_


Motivation and Features
-----------------------

Sometimes you just want to check out a tool from a release and modify
or fix it. This is to make that easy:

    - Go to your project, somewhere under the top-level
      `CMakeLists.txt` file

    - Run

      ```
      git-fatlas-init
      cd athena
      git-fatlas-add PackgeNa<tab>
      ```

      (That's right, tab complete!)

    - Go back and build your package again. Atlas CMake is configured
      to find the package you just checked out, so there's no need to
      edit package filters etc.

To remove a package use `git-fatlas-remove Path/To/Package`.


Comparison to other packages
----------------------------

    - `git-atlas`: This assumes you want a `WorkDir`, which gets in
      the way of compiling Athena code as a part of a larger project.

    - `acm`: This is designed to make working with git and CMake more
      like working with RootCore. Fatlas tries to be more "git-like",
      and doesn't try to hide CMake from you.

Installation
------------

    - Clone this repo
    - Add `source git-fatlas.sh` to your `.bashrc`
