Remedie is a perl based pluggable media center application. It runs as a web server, uses Plagger and SQLite as its backend and uses JavaScript (jQuery) and CSS to build the user interface.

## How to install

If you're a lucky Mac OS X Leopard user, you can download the pre-build application bundle from [downloads page](http://github.com/miyagawa/remedie/downloads).

In summary, you can get the source code, install Perl dependencies and run the web server.

    git clone git://github.com/miyagawa/remedie.git
    cd remedie
    perl Makefile.PL
    make installdeps PERL_AUTOINSTALL_PREFER_CPAN=1
    ./bin/remedie-server.pl

If you do not have git command in handy, you can also download the tarball or ZIP file from [github master](http://github.com/miyagawa/remedie) (there's a "download" button). But I strongly suggest you shouldn't do that, since you need to manually download and update the local copy when Remedie is updated. With git it's just `git pull`.

Before running `make installdeps` command, you need to setup CPAN command so as you can install dependencies as non-root user. To do that, run `cpan` and then run the following commands to save the preference.

    o conf make_install_make_command 'sudo make'
    o conf mbuild_install_build_command 'sudo ./Build'
    o conf commit
    quit

`perl Makefile.PL && make installdeps` will examine `Makefile.PL`, installs required Perl modules from CPAN. **Do not run make install (or `cpan -i .`)**. Especially, if you have Plagger installed in your system, running `make install` for Remedie breaks your existent Plagger installation because we forked Plagger. So, don't do that.

Now with the `remedie-server.pl` process running, you can access Remedie user interface by accessing http://localhost:10010/ with your browser. See the file `HACKING` for more details.

## License

Unless otherwise noted, Remedie and Plagger perl code and `remedie*.js` are licensed under Perl Artistic or GPL 2 License.

This software also includes the following material which have their own license:

* [jQuery](http://www.jquery.com/) (MIT and GPL)
* jQuery plugins (Refer to each individual file for their licenses)
* [JW FLV MEDIA PLAYER](http://www.jeroenwijering.com/?item=JW_FLV_Player) (Creative Commons by-nc-sa)
* [Shadowbox.js Media Viewer](http://www.mjijackson.com/shadowbox/) (Creative Commons by-nc-sa)
* [Fast Icon](http://www.fasticon.com/) (Royalty free icons)
* [Ben Fleming](http://www.yellowicon.com/) (CC by-nc)
* [Movie icon by mazeNL77](http://mazenl77.deviantart.com/) (CC by)

## Links

* [github](http://github.com/miyagawa/remedie) (Git repository)
* [Google Code](http://code.google.com/p/remedie) (Wiki, Issue tracking)
