OS161-Web-GDB
=============

For debugging OS161 with a nice GUI in a browser

![screenshot](/screenshots/Screen Shot 2014-02-25 at 12.29.10 AM.png)

*Note that at the moment, this is only intended for students in Harvard CS161.  This probably wont work for anything other than debugging the OS161 kernel, at least not without significant modification.*


Installing/Running
============
Before trying OS161-Web-GDB, make sure you have Kenny's `.gdbinit`, and, of course, OS161 installed.  You'll need to have CoffeeScript installed, (I think,) which is surprisingly hard to install on the appliance since I think it needs the latest node.js, (0.10.25) while the appliance comes with an older one.

If everything else works, you should be able to install this by `git clone`ing the repo into `~/cs161/OS161-Web-GDB/` then `npm install`ing in the directory.  If it works, you should be able to run it with `grunt`, (oh you'll need to install the grunt cli with `npm install -g grunt`,) and finally use it by going to `http://your.appliances.ip:3000/`.  Mine is `http://192.168.66.128:3000/`.

These instructions are almost definitely insufficient, but hopefully should work.  Please figure it out and contribute back what you found!


Contributing
============
Please fork and send pull requests!  I am actively developing this, however,
so shoot me an email before you start hacking if you want to coordinate!
