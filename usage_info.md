# Usage Options

Some options for usage.

 1. Local - Save in some local folder
 dependencies:
   library_name:
    path: /path/to/library_name

 2. Hosted - Pushed on Github, Gitlab etc.
 dependencies:
   library_name:
    git: <https://github.com/username/library_name>

 Or to target specific branch
 dependencies:
   library_name:
    git:
     url: <https://github.com/username/library_name.git>
     ref: dev    #branch name

 Or to target specific commit
 dependencies:
   library_name:
    git:
     url: <https://github.com/username/library_name.git>
     ref: e234072340    #commit reference id

 Where 'library_name' has to be the same as the 'name' declared in pubspec.yaml of that pub.
