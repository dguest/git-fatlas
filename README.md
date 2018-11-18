Git Fatlas
==========

_Git ATLAS without the extra fat!_


Motivation and Features
-----------------------

Sometimes you just want to check out a tool from a release and modify
or fix it. This is to make that easy:

 - Go to your project, somewhere under the top-level `CMakeLists.txt`
   file

 - Run
   ```
   git-fatlas-init
   cd athena
   git-fatlas-add PackgeNa<tab> OtherPackage<tab>
   ```
   (That's right, tab complete!)

 - Go back and build your package again.

   Atlas CMake will find the package you just checked out,
   so there's no need to edit package filters etc.

To remove a package use `git-fatlas-remove Path/To/Package`.


Comparison to other packages
----------------------------

In general this package won't try to hold your hand with git or CMake:
it won't auto-generate any files or assume that you have specifically
named forks. To be an effective developer in a large collaboration,
you have have to understand what git is doing, and you need _some_
understanding of what CMake is doing.

 - `git-atlas`: This assumes you want a `WorkDir`, which gets in the
   way of compiling Athena code as a part of a larger project. There
   are workarounds for this (package filters, etc) but in general
   working with them is more confusing than working with the raw git
   sparse checkout.

 - `acm`: This is designed to make working with git and CMake more
   like working with RootCore. It is built on top of `git-atlas` so it
   inherits all the confusing bits. Fatlas tries to be more
   "git-like", and doesn't try to hide CMake from you.


Installation
------------

 - Clone this repo
 - Add `source git-fatlas.sh` to your `.bashrc`
