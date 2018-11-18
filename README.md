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
it won't auto-generate any files or assume that you'll always want to
push to a specific fork. This is a slightly different philosophy from
other packages, for example:

 - `git-atlas`: This assumes you want a `WorkDir`, which includes a
   `package_filters.txt` file. This is useful for full Atlas releases,
   but it can get in the way if you just want to rebuild a few Athena
   package within another project.

 - `acm`: This is designed to make working with git and CMake more
   like working with RootCore. It streamlines some common operations
   when maintaining analysis code, but being built on top of
   `git-atlas` it also inherits the confusing bits.

In short, if you _prefer_ git and CMake to whatever ATLAS was using
before but find the sparse checkout thing a bit confusing, this
package might be useful to you. If you want to abstract away most of
the underlying tools, you should use something else.


Installation
------------

 - Clone this repo
 - Add `source git-fatlas.sh` to your `.bashrc`
