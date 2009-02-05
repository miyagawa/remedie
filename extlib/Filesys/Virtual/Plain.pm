package Filesys::Virtual::Plain;

###########################################################################
### Filesys::Virtual::Plain
### L.M.Orchard (deus_x@pobox_com)
### David Davis (xantus@cpan.org)
###
###
### Copyright (c) 1999 Leslie Michael Orchard.  All Rights Reserved.
### This module is free software; you can redistribute it and/or
### modify it under the same terms as Perl itself.
###
### Changes Copyright (c) 2003-2004 David Davis and Teknikill Software
###########################################################################

use strict;
use Filesys::Virtual;
use Carp;
use User::pwent;
use User::grent;
use IO::File;

our $AUTOLOAD;
our $VERSION = '0.10';
our @ISA = qw(Filesys::Virtual);

our %_fields = (
	 'cwd'       => 1,
	 'root_path' => 1,
	 'home_path' => 1,
);

sub AUTOLOAD {
	my $self = shift;
		
	my $field = $AUTOLOAD;
	$field =~ s/.*:://;
	
	return if $field eq 'DESTROY';

	croak("No such property or method '$AUTOLOAD'") if (!$self->_field_exists($field));
		
	{
		no strict "refs";
		*{$AUTOLOAD} = sub {
			my $self = shift;
			return (@_) ? ($self->{$field} = shift) : $self->{$field};
		};
	}
		
	return (@_) ? ($self->{$field} = shift) : $self->{$field};

}

=pod

=head1 NAME

Filesys::Virtual::Plain - A Plain virtual filesystem

=head1 SYNOPSIS

	use Filesys::Virtual::Plain;

	my $fs = Filesys::Virtual::Plain->new();

	$fs->login('xantus', 'supersekret');

	print foreach ($fs->list('/'));

=head1 DESCRIPTION

This module is used by other modules to provide a pluggable filesystem.

=head1 CONSTRUCTOR

=head2 new()

You can pass the initial cwd, root_path, and home_path as a hash.

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	$self->_init(@_);
	return $self;
}

sub _init {
	my ($self, $params) = @_;

	foreach my $field (keys %_fields) {
		next if (!$self->_field_exists($field));
		$self->$field($params->{$field});
	}
}

sub _field_exists {
	return (defined $_fields{$_[1]});
}

=pod

=head2 login($username, $password, $become)

Logs in a user.  Returns 0 on failure.  If $username is 'anonymous' then it
will try to login as 'ftp' with no password.  If $become is defined then it
will try to change ownership of the process to the uid/gid of the logged in
user.  BEWARE of the consequences of using $become.  login() also sets the 
uid, gid, home, gids, home_path, and chdir to the users'.

=cut

sub login {
	my $self = shift;
    my $username = shift;
    my $password = shift;
	my $become = shift;
	my $pw;
	if ($username eq "anonymous") {
		### Anonymous login
		$pw = getpwnam("ftp");
		unless (defined $pw) {
			return 0;
		}
	} else {
		### Given username / password
		$pw = getpwnam($username);
		unless (defined $pw) {
			return 0;
		}
		my $cpassword = $pw->passwd();
		my $crpt = crypt($password, $cpassword);
		unless ($crpt eq $cpassword) {
			return 0;
		}
	}
	if (defined $become) {
		$< = $> = $pw->uid();
		$( = $) = $pw->gid();
	}
	$self->{uid} = $pw->uid();
	$self->{gid} = $pw->gid();
	$self->{home} = $pw->dir();
	$self->{gids}{$pw->gid()} = 1;
	$self->chdir($pw->dir());
	$self->home_path($pw->dir());
	return 1;
}

=pod

=head2 cwd

Gets or sets the current directory, assumes / if blank.
This is used in conjunction with the root_path for file operations.
No actual change directory takes place.

=cut

sub cwd {
	my $self = shift;
	
	if (@_) {
		$self->{cwd} = shift;
	} else {
		$self->{cwd} ||= '/';
	}
		
	return $self->{cwd};
}

=pod

=head2 root_path($path)

Get or set the root path.  All file paths are  off this and cwd
For example:

	$self->root_path('/home/ftp');
	$self->cwd('/test');
	$self->size('testfile.txt');

The size command would get the size for file /home/ftp/test/testfile.txt
not /test/testfile.txt

=cut

sub root_path {
	my ($self) = shift;

	if (@_) {
		my $root_path = shift || '';
			
		### Does the root path end with a '/'?  If so, remove it.
		$root_path = (substr($root_path, length($root_path)-1, 1) eq '/') ?
			substr($root_path, 0, length($root_path)-1)	: $root_path;
		$self->{root_path} = $root_path;
	}
		
	return $self->{root_path};			
}

=pod

=head2 chmod($mode,$file)

chmod's a file.

=cut

sub chmod {
	my ($self, $mode, $fn) = @_;
	$fn = $self->_path_from_root($fn);
	
	return (chmod($mode,$fn)) ? 1 : 0;
}

=pod

=head2 modtime($file)

Gets the modification time of a file in YYYYMMDDHHMMSS format.

=cut

sub modtime {
	my ($self, $fn) = @_;
	$fn = $self->_path_from_root($fn);
	
#	return (0,"");
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat($fn);
		
	my ($sec, $min, $hr, $dd, $mm, $yy, $wd, $yd, $isdst) =
		localtime($mtime); $yy += 1900; $mm++;
		
	return (1,sprintf "%04d%02d%02d%02d%02d%02d", $yy, $mm, $dd, $hr, $min, $sec);
}

=pod

=head2 size($file)

Gets the size of a file in bytes.

=cut

sub size {
	my ($self, $fn) = @_;
	$fn = $self->_path_from_root($fn);

	return (CORE::stat($fn))[7];
}

=pod

=head2 delete($file)

Deletes a file, returns 1 or 0 on success or failure.

=cut

sub delete {
	my ($self, $fn) = @_;
	$fn = $self->_path_from_root($fn);

	return ((-e $fn) && (!-d $fn) && (unlink($fn))) ? 1 : 0;
}

=pod

=head2 chdir($dir)

Changes the cwd to a new path from root_path.
Returns undef on failure or the new path on success.

=cut

sub chdir {
	my ($self, $dir) = @_;

	my $new_cwd = $self->_resolve_path($dir);
	my $full_path = $self->root_path().$new_cwd;

	return ((-e $full_path) && (-d $full_path)) ? $self->cwd($new_cwd) : undef;
}

=pod

=head2 mkdir($dir, $mode)

Creats a directory with $mode (defaults to 0755) and chown()'s the directory
with the uid and gid.  The return value is from mkdir().

=cut

sub mkdir {
	my ($self, $dir, $mode) = @_;
	$dir = $self->_path_from_root($dir);

	return 2 if (-d $dir);
	
	$mode ||= 0755;
	
	my $ret = (mkdir($dir, $mode)) ? 1 : 0;
	
	if ($ret) {
		chown($self->{uid}, $self->{gid}, $dir);
	}
	return $ret;
}

=pod

=head2 rmdir($dir)

Deletes a directory or file if -d test fails.  Returns 1 on success or 0 on
failure.

=cut

sub rmdir {
	my ($self, $dir) = @_;
	$dir = $self->_path_from_root($dir);

	if (-e $dir) {
		if (-d $dir) {
			return 1 if (rmdir($dir));
		} else {
			return 1 if (unlink($dir));
		}
	}

	return 0;
}

=pod

=head2 list($dir)

Returns an array of the files in a directory.

=cut

sub list {
	my ($self, $dirfile) = @_;
	$dirfile = $self->_path_from_root($dirfile);
		
	my @ls;
		
	if(-e $dirfile) {
		if(!-d $dirfile) {
			### This isn't a directory, so derive its short name, and push it.
			my @parts = split(/\//, $dirfile);
			push(@ls, pop @parts);
		} else {
			### Open the directory and get a file list.
            opendir(DIR, $dirfile);
            my @files = readdir(DIR);
			closedir(DIR);
						
			### Process the files...
            @ls = (sort @files);
		}
	}
	
	return @ls;
}

=pod

=head2 list_details($dir)

Returns an array of the files in ls format.

=cut

sub list_details {
	my ($self, $dirfile) = @_;
	$dirfile = $self->_path_from_root($dirfile);
		
	my @ls;
		
    if( -e $dirfile ) {
		if(! -d $dirfile ) {
			### This isn't a directory, so derive its short name, and produce
			### an ls line.
			my @parts = split(/\//, $dirfile);
			my $fn = pop @parts;
			push(@ls, $self->_ls_stat($dirfile, $fn));
		} else {
			### Open the directory and get a file list.
            opendir(DIR, $dirfile);
            my @files = readdir(DIR);
			closedir(DIR);
						
			### Make sure the directory path ends in '/'
			$dirfile = (substr($dirfile, length($dirfile)-1, 1) eq '/') ? $dirfile : $dirfile.'/';
						
			### Process the files...
			foreach (sort @files) {
				push(@ls, $self->_ls_stat($dirfile.$_, $_));
			}
		}
	}
		
	return @ls;
}

=pod

=head2 stat($file)

Does a normal stat() on a file or directory

=cut

sub stat {
	my ($self, $fn) = @_;
				
	$fn =~ s/\s+/ /g;
	$fn = $self->_path_from_root($fn);

	return CORE::stat($fn);
}

=pod

=head2 test($test,$file)

Perform a perl type test on a file and returns the results.

For example to perform a -d on a directory.

	$self->test('d','/testdir');

See filetests in perlfunc (commandline: perldoc perlfunc)

=cut

#    -r  File is readable by effective uid/gid.
#    -w  File is writable by effective uid/gid.
#    -x  File is executable by effective uid/gid.
#    -o  File is owned by effective uid.

#    -R  File is readable by real uid/gid.
#    -W  File is writable by real uid/gid.
#    -X  File is executable by real uid/gid.
#    -O  File is owned by real uid.

#    -e  File exists.
#    -z  File has zero size.
#    -s  File has nonzero size (returns size).

#    -f  File is a plain file.
#    -d  File is a directory.
#    -l  File is a symbolic link.
#    -p  File is a named pipe (FIFO), or Filehandle is a pipe.
#    -S  File is a socket.
#    -b  File is a block special file.
#    -c  File is a character special file.
#    -t  Filehandle is opened to a tty.

#    -u  File has setuid bit set.
#    -g  File has setgid bit set.
#    -k  File has sticky bit set.

#    -T  File is a text file.
#    -B  File is a binary file (opposite of -T).

#    -M  Age of file in days when script started.
#    -A  Same for access time.
#    -C  Same for inode change time.

sub test {
	my ($self, $test, $fn) = @_;

	$fn = $self->_path_from_root($fn);
	$fn =~ s/'/\\'/g;
	# NO FUNNY BUSINESS
	$test =~ s/^(.)/$1/;
	
	my $ret = eval("-$test '$fn'");
	
	return ($@) ? undef : $ret;
}

=pod

=head2 open_read($file,[params])

Opens a file with L<IO::File>. Params are passed to open() of IO::File.
It returns the file handle on success or undef on failure.  This could
be technically be used for any sort of open operation.  See L<IO::File>'s
open method.

=cut

sub open_read {
	my ($self, $fin, @opts) = @_;
	$fin =~ s/\s+/ /g;
	$self->{file_path} = $fin = $self->_path_from_root($fin);

	return IO::File->new($fin,@opts);
}

=pod

=head2 close_read($fh)

Performs a $fh->close()

=cut

sub close_read {
	my ($self, $fh) = @_;

	return $fh->close();
}

=pod

=head2 open_write($fh, $append)

Performs an $fh->open(">$file") or $fh->open(">>$file") if $append is defined.
Returns the filehandle on success or undef on failure.

=cut

sub open_write {
	my ($self, $fin, $append) = @_;
	$fin =~ s/\s+/ /g;
	$self->{file_path} = $fin = $self->_path_from_root($fin);
	
	my $o = (defined($append)) ? '>>' : '>';
	return IO::File->new($o.$fin);
}

=pod

=head2 close_write($fh)

Performs a $fh->close()

=cut

sub close_write {
	my ($self, $fh) = @_;

	$fh->close();
		
	return 1;
}

=pod

=head2 seek($fh, $pos, $wence)

Performs a $fh->seek($pos, $wence). See L<IO::Seekable>.

=cut

sub seek {
	my ($self, $fh, $first, $second) = @_;

	return $fh->seek($first, $second);
}

=pod

=head2 utime($atime, $mtime, @files)

Performs a utime() on the file(s).  It changes the access time and mod time of
those files.

=cut

sub utime {
    my ($self, $atime, $mtime, @fn) = @_;

	foreach my $i ( 0 .. $#fn ) {
		$fn[$i] = $self->_path_from_root($fn[$i]);
	}
	
	return CORE::utime($atime, $mtime, @fn);
}


### Internal methods

# Restrict the path to beneath root path

sub _path_from_root {
	my ($self, $path) = @_;

	return $self->root_path().$self->_resolve_path($path);
}

# Resolve a path from the current path

sub _resolve_path {
	my $self = shift;
	my $path = shift || '';

	my $cwd = $self->cwd();
	my $path_out = '';

	if ($path eq '') {
		$path_out = $cwd;
	} elsif ($path eq '/') {
		$path_out = '/';
	} else {
		my @real_ele = split(/\//, $cwd);
		if ($path =~ m/^\//) {
			undef @real_ele;
		}
		foreach (split(/\//, $path)) {
			if ($_ eq '..') {
				pop(@real_ele) if ($#real_ele);
			} elsif ($_ eq '.') {
				next;
			} elsif ($_ eq '~')	{
				@real_ele = split(/\//, $self->home_path());
			} else {
				push(@real_ele, $_);
			}
		}
		$path_out = join('/', @real_ele);
	}
	
	$path_out = (substr($path_out, 0, 1) eq '/') ? $path_out : '/'.$path_out;

	return $path_out;
}

# Given a file's full path and name, produce a full ls line
sub _ls_stat {
	my ($self, $full_fn, $fn) = @_;
		
	my @modes = ("---------", "rwxrwxrwx");
	# Determine the current year, for time comparisons
	my $curr_year = (localtime())[5]+1900;

	# Perform stat() on current file.
	my ($mode,$nlink,$uid,$gid,$size,$mtime) = (CORE::stat($full_fn))[2 .. 5,7,9];
	#my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	#		$atime,$mtime,$ctime,$blksize,$blocks) = CORE::stat($full_fn);
	
	# Format the mod datestamp into the ls format
	my ($day, $mm, $dd, $time, $yr) = (localtime($mtime) =~ m/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);
	
	# Get a string of 0's and 1's for the binary file mode/type
	my $bin_str  = substr(unpack("B32", pack("N", $mode)), -16);
	
	# Produce a permissions map from the file mode
	my $mode_bin = substr($bin_str, -9);
	my $mode_str = '';
	
	for (my $i=0; $i<9; $i++) {
		$mode_str .= substr($modes[substr($mode_bin, $i, 1)], $i, 1);
	}
		
	# Determine what type of file this is from the file type
	my $type_bin = substr($bin_str, -16, 7);
	my $type_str = '-';
	$type_str = 'd' if ($type_bin =~ m/^01/);
	
	# Assemble and return the line
	return sprintf("%1s%9s %4s %-8s %-8s %8s %3s %2s %5s %s",
		 $type_str, $mode_str, $nlink,
		 $self->_user($uid), $self->_group($gid), $size, $mm, $dd,
		 ($curr_year eq $yr) ? substr($time,0,5) : $yr, $fn);
}

# Lookup user name by uid

{
	my %user;
	sub _user {
		my ($self, $uid) = @_;
		if (!exists($user{$uid})) {
			if (defined($uid)) {
				my $obj = getpwuid($uid);
				if ($obj) {
					$user{$uid} = $obj->name;
				} else {
					$user{$uid} = "#$uid";
				}
			} else {
				return '#?';
			}
		}
		return $user{$uid};
	}
}

# Lookup group name by gid

{
	my %group;
	sub _group {
		my ($self, $gid) = @_;
		if (!exists($group{$gid})) {
			if (defined($gid)) {
				my $obj = getgrgid($gid);
				if ($obj) {
					$group{$gid} = $obj->name;
				} else {
					$group{$gid} = "#$gid";
				}
			} else {
				return '#?';
			}
		}
		return $group{$gid};
	}
}

1;

__END__

=head1 AUTHOR

David Davis, E<lt>xantus@cpan.orgE<gt>, http://teknikill.net/

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<Filesys::Virtual>, L<Filesys::Virtual::SSH>,
L<Filesys::Virtual::DAAP>, L<POE::Component::Server::FTP>,
L<Net::DAV::Server>, L<HTTP::Daemon>,
http://perladvent.org/2004/20th/

=cut
