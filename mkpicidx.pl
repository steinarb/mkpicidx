#!/usr/bin/perl
# Lager smaa "-icon.gif" versjoner av alle tiff-filene i katalogen
# Disse har faatt redusert fargene. Alle ikoner deler paa en pott
# av $quant_no_cols farger.
#
# Steinar Bang, 940916

# 
$gallery="/home/steinarb/wwwhome/dod/gallery/steinarb" ;
$cur_dir="." ;
$icon_dir="$cur_dir/.icons";
$prefix_file="$cur_dir/prefix.html" ;
$suffix_file="$cur_dir/suffix.html" ;

#
$quant_no_cols=16 ;
$thumbnail_height=40 ;		# Height in pixels
$thumbnail_height=66 ;		# Height in pixels

opendir(IMAGEDIR, ".");
@allfiles = sort(readdir(IMAGEDIR));
closedir(IMAGEDIR) ;

@jpgfiles = grep(/.*\.jpg/, @allfiles) ;
@giffiles = grep(/.*\.gif/, @allfiles) ;
@rootnames = () ;
@rootpaths = () ;
@pnmfiles = ();
@descfiles = () ;

# Make ./.icons if it doesn't exist
if (!-d $icon_dir) { mkdir($icon_dir,0777) ; } 


print STDERR "Lager PNM-filer og reduserer hoeyden til $thumbnail_height piksler:\n" ;
foreach $f (@jpgfiles) {
    local ($rootname) = (&rootname($f)) ;
    local ($rootpath) = (&rootpath($f)) ;
    local($pnm) = ("$icon_dir/$rootname.pnm") ;
    print STDERR "Lager og skalerer $pnm\n" ;
    system("djpeg $f | pnmscale -height $thumbnail_height >$pnm") ;
#    system("djpeg $f | pnmscale -height $thumbnail_height | ppmnorm >$pnm") ;
    push (@pnmfiles,$pnm) ;
    print STDERR "rootname: $rootname  rootpath: $rootpath\n" ;
    push(@rootnames, $rootname) ;
    push(@rootpaths, $rootpath) ;
}

foreach $f (@giffiles) {
    local ($rootname) = (&rootname($f)) ;
    local ($rootpath) = (&rootpath($f)) ;
    local($pnm) = ("$icon_dir/$rootname.pnm") ;
    print STDERR "Lager og skalerer $pnm\n" ;
    system("giftopnm $f | pnmscale -height $thumbnail_height >$pnm") ;
#   system("giftopnm $f | pnmscale -height $thumbnail_height | ppmnorm >$pnm");
    push (@pnmfiles,$pnm) ;
    print STDERR "rootname: $rootname  rootpath: $rootpath\n" ;
    push(@rootnames, $rootname) ;
    push(@rootpaths, $rootpath) ;
}

print STDERR "Kvantiserer alle PNM-filene..." ;
system ("ppmquantall $quant_no_cols " . join(" ",@pnmfiles)) ;
print STDERR "ferdig\n" ;

print STDERR "Sletter gamle ikoner..." ;
system("rm $icon_dir/*.gif") ;
print STDERR "ferdig\n" ;

print STDERR "Lager GIF-ikoner:\n" ;
foreach $f (@pnmfiles) {
    local ($rootname) = &rootname($f) ;
    local ($gif) = ("$rootname.gif") ;
    print STDERR "Lager $gif\n" ;
#    system ("ppmquant -fs $quant_no_cols $f | ppmtogif >$gif") ;
#    system ("ppmtogif $f >$gif") ;
    system ("pnmcrop $f | ppmtogif >$gif") ;
}
print STDERR "Sletter PNM-filer..." ;
system("rm $icon_dir/*.pnm") ;
print STDERR "ferdig\n" ;

print STDERR "Lager \"index.html\":\n" ;
open(INDX, ">index.html") ;


if (-r $prefix_file) {
    open(DESC, $prefix_file);
    while(<DESC>) { print INDX ; }
    close(DESC) ;
} else {
    $pwdnam = $ENV{'PWD'} ;
    $pwdnam =~ s#(\w*/)*(\w+)$#\2# ;
    print INDX "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2//EN\">\n\n" ;
    print INDX "<html>\n" ;
    print INDX "<head>\n" ;
    print INDX "<title>\n\"$pwdnam\" picture archive\n</title>\n" ;
    print INDX "</head>\n\n<body>\n" ;
    print INDX "<h1>\n\"$pwdnam\" picture archive\n</h1>\n" ;
}

$cur_counter = 1;
foreach $f (@jpgfiles) {
    local ($rootname, $ext) = split(/\./, $f) ;
    local ($txt) = ("$rootname.txt") ;
    local ($icon) = ("$icon_dir/$rootname.gif") ;
    local ($jpg) = ($f) ;
    print INDX "<p><a name=\"jpeg$cur_counter\" href=\"$jpg\"><img src=\"$icon\" alt=\"[$jpg]\"></a><br>\n" ;
    $cur_counter++ ;
    $desc = `rdjpgcom $jpg` ; # Get JPEG comment, if any
    if ($desc) {
	# unpack any quoted octal values from the JPEG comment
	$desc =~ s/\\(\d\d\d)/pack("C",oct($1))/ge ;
	print INDX "<em>$desc</em>\n" ;
    } elsif (-r $txt) {
	open(DESC, "$txt");
	while(<DESC>) { print INDX ; }
	close(DESC) ;
    }
    $jpg_size = (stat($jpg))[7] ;
    printf(INDX "(JPEG %1.0fK).", ($jpg_size / 1024)) ;
    print INDX "</p>\n" ;
}

$cur_counter = 1;
foreach $f (@giffiles) {
    local ($rootname, $ext) = split(/\./, $f) ;
    local ($txt) = ("$rootname.txt") ;
    local ($icon) = ("$icon_dir/$rootname.gif") ;
    local ($gif) = ($f) ;
    print INDX "<p><a name=\"gif$cur_counter\" href=\"$gif\"><img src=\"$icon\" alt=\"[$gif]\"></a><br>\n" ;
    $cur_counter++ ;
    if (-r $txt) {
	open(DESC, "$txt");
	while(<DESC>) { print INDX ; }
	close(DESC) ;
    }
    $gif_size = (stat($gif))[7] ;
    printf(INDX "(GIF %1.0fK).", ($gif_size / 1024)) ;
    print INDX "</p>\n" ;
}

if (-r $suffix_file) {
    open(DESC, $suffix_file);
    while(<DESC>) { print INDX ; }
    close(DESC) ;
} else {
    # Print some blank lines at the end, to allow jumping directly to
    # name'd <a> elements down in the index
    $no_of_blank_lines = 40 ;
    for($i=0; $i<$no_of_blank_lines; $i++) {
	print INDX "<br>" ;
    }
    print INDX "\n" ;
    print INDX "</body>\n</html>\n" ;
}

close(INDX) ;

print STDERR "Ferdig\n" ;

#
# Steinar Bang, Falch Hurtigtrykk, Oslo
#
# Return the argument filename without the last '.ext' sequence (the
# root name of the file).
#

sub rootname {
    local($n) = @_ ;
#    $n =~ s/^.*\/([^\/]+)$/\1/ ;
    $n =~ s/\.\w{0,3}$// ;
    $n ;
}

sub rootpath {
    local($n) = @_ ;
    $n =~ s/^(.*)\/[^\/]+$/\1/ ;
    $n ;
}
