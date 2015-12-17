# java2mirah
A ruby script to translate Java source to Mirah source.

----

Use
===
Run as __>java2mirah.rb__ with no arguments to create subfolders __'in-java'__ and __'out-mirah'__ if they don't exist and to print the example.

Run as __>java2mirah.rb [-a|--all]__ to create .mirah files for all .java files found in the __'in-java'__ folder.

Run as __>java2mirah.rb *FileName*__ where *FileName* is the name of the file *without* the .java extension.
As long as the file is in the __'in-java'__ folder it should work.

Status
======
The conversion is not perfect and likely never will be.  The intent is to reduce the amount of work in translating a java source file to a mirah source file.

Creates .mirah files in package based subfolders within __'out-mirah'__ subfolder.

Planned Features
================
Implement *extends* and *implements* for classes.
* current behaviour ignores anything after the class name.

Fix issue with translation effecting literal strings.
* As of now, if a word in a literal string is the same as an instance variable (field), it will get an @ placed in front of it as if it were a reference to that variable instead of just a word in a literal string.

Add command line options for tasks like:
* translate multiple specific files without doing all.
* whether or not to create package based directory structure.
* change package line, and thus directory structure, for translated mirah files.
* specify in and out directories.

Refactoring.
* I want a script to be able to change a mirah class's package and/or class name, move it to the appropriate folder/file, and change all references throughout a project to reflect said changes. This should be an easier task than what I've already written.  Just have to bother.
* Hard part: may need a GUI to simplify refactoring.
