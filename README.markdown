Remedie is a perl based pluggable media center application. It runs as a web server, uses Plagger and SQLite as its backend and uses JavaScript (jQuery) and CSS to build the user interface.

## How to install

Check out Git repository using

  git clone git://github.com/miyagawa/remedie.git

And then install the dependencies looking at `Makefile.PL`.

**Do not run make install**. Especially, if you have Plagger installed in your system, running `make install` for Remedie breaks your existent Plagger installation because we forked Plagger. So, don't do that.

## License

Unless otherwise noted, Remedie perl code and remedie*.js are licensed under Perl Artistic or GPL 2 License.

This software also includes the following material which have their own license:

* [jQuery](http://www.jquery.com/) (MIT and GPL)

* jQuery plugins (Refer to each individual file for their licenses)

* [JW FLV MEDIA PLAYER 4.2](http://www.jeroenwijering.com/?item=JW_FLV_Player) (Creative Commons by-nc-sa)

* [Fast Icon](http://www.fasticon.com/) (Royalty free icons)

* [Ben Fleming](http://www.yellowicon.com/) (CC by-nc)

## Links

* [github](http://github.com/miyagawa/remedie) (Git repository)

* [Google Code](http://code.google.com/p/remedie) (Wiki, Issue tracking)

* [Remedie](http://remediecode.org/)



