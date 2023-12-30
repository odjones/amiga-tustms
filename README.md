# amiga-tustms
The Ultimate Soundtracker Module Scanner (for machines with 2MB of chip memory)

This is a command-line based utility for ripping SoundTracker music modules directly from system memory. Load and run a game with SoundTracker music that you want to rip, then reset your computer and boot from a minimal bootable floppy disk with TUSTMS copied to it.

The music data is usually stored in higher memory, so the chances of recovering it after a fresh boot are usually pretty good. The utility allows you to scan for multiple music modules in memory (not just one!) and save each to disk with a different name. The module statistics can be viewed before saving - and the size can also be edited (some modules are deliberately mangled to prevent most module rippers from saving them completely - this function gets around that little trick!)

Thanks to this little utility, I amassed quite a collection of SoundTracker game music in my collection. Enjoy!

This project was written in 68000 assembler, using Devpac 3.x by HiSoft. I was particularly lazy about assembling system headers at the time (I also started writing code before I got a hard disk, and floppy drives were slow!), so I did a one-off compile of all system libraries into a GenAm symbol file called system.gs - this contains all symbols for the Amiga operating system, and can be used in place of includes. I usually placed a copy on the RAM disk, to speed up assembly. However, it will _only_ work with Devpac 3.x.

All dependent libraries (DNumToStr.lib and DStrToNum.lib) and macros (Libraries.mac and Files.mac), also included, are my own work.

(Yes, my coder handle back in the day really _was_ Chainsaw Baron! Then again, I was still a teenager when I wrote this code, so there you go.)
