# java2mirah
A ruby script to translate Java source to Mirah source.

----

Status
======
Needs a subfolder called __'in-java'__ from which to read your Java files.

Run as __>java2mirah.rb *FileName*__ where *FileName* is the name of the file *without* the .java extension.
As long as the file is in the __'in-java'__ folder it should work.

Currently prints Mirah code to the screen which can be copied and pasted into a file.  Won't take much work to fix this, just haven't done it yet.

The conversion is not perfect and likely never will be.  The intent is to reduce the amount of work in translating a java source file to a mirah source file.

Planned Features
================
The plan is to read all files in the __'in-java'__ folder and create Mirah versions in the __'out-mirah'__ folder.

Refactoring.  I want a script to be able to change a mirah class's package and/or class name, move it to the appropriate folder/file, and change all references throughout a project to reflect said changes.  This should be an easier task than what I've already written.  Just have to bother.
