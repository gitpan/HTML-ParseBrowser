package HTML::ParseBrowser;
use vars ('%lang','$VERSION');
$VERSION = 0.5;

%lang = ('en' => 'English',
         'de' => 'German',
         'fr' => 'French',
         'es' => 'Spanish',
         'it' => 'Italian',
         'dn' => 'Danish',
         'jp' => 'Japanese');

sub new {
    my $class = shift;
    my $browser = {};
    bless $browser, ref $class || $class;
    $browser->Parse(shift);
    return $browser;}

sub Parse {
    my $browser = shift;
    my $useragent = shift;
    #$browser = {}; # clean each time
    delete $browser->{$_} for keys %{$browser};
    return undef unless $useragent;
    return undef if $useragent eq '-';
    $browser->{user_agent} = $useragent;
    $useragent =~ s/Opera (\d)/Opera\/$1/i;
    while ($useragent =~ s/\[(\w+)\]//) {
        push @{$browser->{languages}}, $lang{$1} || $1;
        push @{$browser->{langs}}, $1;}
    #($browser->{detail}) = ($useragent =~ s/\((.*)\)//);
    if ($useragent =~ s/\((.*)\)//) {
        $browser->{detail} = $1;}
    $browser->{useragents} = [grep /\//, split /\s+/, $useragent];
    $browser->{properties} = [split /;\s+/, $browser->{detail}];
    for (@{$browser->{useragents}}) {
        my ($br, $ver) = split /\//;
        $browser->{name} = $br;
        $browser->{version}->{v} = $ver;
        ($browser->{version}->{major},
         $browser->{version}->{minor}) = split /\./, $ver, 2;
        last if lc $br eq 'lynx';}
    for (@{$browser->{properties}}) {
        /compatible/i and next;
        unless (lc $browser->{name} eq 'webtv') {
            /^MSIE (.*)$/ and do {
                $browser->{name} = 'MSIE';
                $browser->{version}->{v} = $1;
                ($browser->{version}->{major},
                $browser->{version}->{minor}) = split /\./, $1, 2;};}
        if (/^Win/) {
            $browser->{os} = $_;
            $browser->{ostype} = 'Windows';
            if (/ /) {
                (undef, $browser->{osvers}) = split / /, $_, 2;
                if ($browser->{osvers} =~ /^NT/) {
                    $browser->{ostype} = 'Windows NT';
                    (undef, $browser->{osvers}) =
                      split / /, $browser->{osvers}, 2;
                    if ($browser->{osvers} >= 5) {
                        $browser->{osvers} = '2000';}}}
            elsif (/Win(\w\w)/i) {
                $browser->{osvers} = $1;}
            if (lc $browser->{osvers} =~ /^9x/) {
                $browser->{osvers} = 'ME';}}
        if (/^Mac/) {
            $browser->{os} = $_;
            $browser->{ostype} = 'Macintosh';
            (undef, $browser->{osvers}) = split /[ _]/, $_, 2;}
        if (/^PPC$/) {
            $browser->{osarc} = 'PPC';}
        if (/^Linux/) {
            $browser->{os} = $_;
            $browser->{ostype} = 'Linux';
            (undef, $browser->{osvers}) = split / /, $_, 2;
            if ($browser->{osvers} =~ / /) {
                (undef, $browser->{osvers},$browser->{osarc}) =
                split / /, $_, 3;}}
        if (/^(SunOS)|(Solaris)/i) {
            $browser->{os} = $_;
            $browser->{ostype} = 'Solaris';
            (undef, $browser->{osvers}) = split / /, $_, 2;
            if ($browser->{osvers} =~ / /) {
                ($browser->{osvers},$browser->{osarc})
              = split / /, $_, 3}}
        for my $lang (keys %lang) {
            if (/^$lang\-/) {
                my $l;
                ($l, undef) = split /\-/;
                push @{$browser->{languages}}, $lang{$l} || $1;
                push @{$browser->{langs}}, $1;}
            push @{$browser->{languages}}, $lang{$_} if /^$lang$/;
            push @{$browser->{langs}}, $_ if /^$lang$/;}}

    if ($browser->{name} eq 'Mozilla') {
        $browser->{name} = 'Netscape';}
    if ($browser->{name} eq 'Gecko') {
        $browser->{name} = 'Mozilla';}
    if ($browser->{name} eq 'Netscape6') {
        $browser->{name} = 'Netscape';}
    if ($browser->{name} eq 'Konqueror') {
        $browser->{ostype} = 'Linux';}
    $browser->{name} ||= $useragent;

    my %langs_in;
    for (@{$browser->{langs}}) {
        $langs_in{$_}++;}
    ($browser->{lang})
      = sort {$langs_in{$a} <=> $langs_in{$b}} keys %langs_in;
    $browser->{language} = $lang{$browser->{lang}} || $browser->{lang};
    delete $browser->{language} unless $browser->{language};
    return $browser;}

sub AUTOLOAD {
    my $obj = shift;
    my $me = lc $AUTOLOAD;
    $me =~ s/^.*\:\://;
    my $aref;
    $aref = \$obj->{$me} if exists $obj->{$me};
    $aref = \$obj->{version}->{$me} if exists $obj->{version}->{$me};
    if (my $replace = shift) {
        $$aref = $replace;}
    return $$aref;}

__END__

=head1 NAME

HTML::ParseBrowser - Simple interface for User Agent string parsing.

=head1 SYNOPSIS

  use HTML::ParseBrowser;
  my $ua = HTML::ParseBrowser->new($ENV{HTTP_USER_AGENT});
  my $browsername = $ua->name;

  my $browser = 'Mozilla/4.0 (compatible; MSIE 5.5; Windows 98; Win 9x 4.90)';
                    # BTW: That's IE 5.5 on Windows ME
  $ua->Parse($new_browser);
  $browsername = $ua->name;
  my $os = $ua->os_type;

  $browser = 'Mozilla 3.0 - Mozilla/3.0 (Linux 2.2.19 i686; U) Opera 5.0  [en]';
                 # BTW: that's Opera 5.0 on Linux, English
  $ua->Parse($new_browser);
  my $lingo = $ua->language;

=head1 DESCRIPTION

The HTML::ParseBrowser is an Object-Oriented interface for parsing a User Agent
string. It provides simple autoloaded methods for retrieving both the actual
values stored in the interpreted (and, so far, correct) information that these
wildly varying and nonstandardised strings attempt to convey.

It provides the following methods:

=over 4

=item new() (constructor method)

Accepts an optional User Agent string as an argument. If present, the string
will be parsed and the object populated. Either way the base object will be
created.

=item Parse()

Intended to be given a User Agent string as an argument. If present, it will be
parsed and the object repopulated.

If called without a true argument or with the argument '-' Parse() will simply
depopulate the object and return undef. (This is useful for parsing logs, which
often fill in a '-' for a null value.)

=item Case-insensitive Access Methods and properties.

Any of the methods below may be called. Properties (->{whatever}) are case
sensitive and are lowercase. Called as methods (the preferred
way ->whatever() ) they are NOT case sensitive. As a result you can say
$ua->NAME, $ua->name, $ua->Name, or $ua->nAMe if you so feel inclined.

If an item is not able to be parsed, the methods will return undef. Calling
things in the method way will not cause autovivification, while checking as
properties without using exists() in a conditional first will cause
autovivifivation first (and, in the case of the version subproperties, even
exists() will do so - Ack!)

Note that in some cases it is absolutely impossible to tell certain details.
Nothing is guaranteed to be present -- not even 'name'.

It is also possible for someone to make their browser lie about the operating
system they are using (especially with spiders) -- and in some cases, they may
even be using more than one at the same time (like running Konqueror through an
X-Windows client on a Windows box).

=back

=over 8

=item user_agent()

The actual original User Agent string you passed Parse() or new()

=item languages()

Returns an arrayref of all languages recognised by placement and context in the
User_Agent string. Uses English names of languages encountered where
comprehended, ANSI code otherwise. Feel free to add to the hash to cover more
languages.

=item language()

Returns the language of the browser, interpreted as an English language name if
possible, as above. If more than one language are uncovered in the string,
chooses the one most repeated or the first encountered on any tie.

=item langs()

Like languages() above, except uses ANSI standard language codes always.

=item lang()

Like language() above, but only containing the ANSI language code

=item detail()

The stuff inside any parentheses encountered. (Note that if for some really
weird reason some User Agent string has two sets of parens, this string will
contain the entire contents from the first paren to the last, including any
intervening close and open parens. Anyway, they aren't supposed to do that, and
such a case would likely only exist in cases of spiders and homebrewed
browsers.)

=item useragents()

Returns an arrayref of all intelligible standard User Agent engine/version
pairs, and Opera's, to, if applicable. (Please note that this is despiute the
fact that Opera's is _not_ intelligible.)

=item properties()

Returns an arrayref of the stuff in details() broken up by /;\s+/

=item name()

The _interpreted_ name of the browser. This value may not actually appear
anywhere inside the string you handed it. Netscape Communicator provides a good
example of this oddness.

=item version()

Returns a hashref containing v, major, and minor, as explained below and keyed
as such.

=item v()

The full version of the useragent (i.e. '5.6.0')
To access as a property, grab $ua->{version}->{v}

=item major()

The Major version number (i.e. '5')
To access as a property, grab $ua->{version}->{major}

=item minor()

The Minor version number (i.e. '6.0')
To access as a property, grab $ua->{version}->{minor}

=item os()

The Operating System the browser is running on.

=item ostype()

The _interpreted_ type of the Operating System. For instance, 'Windows' rather
than 'Windows 9x 4.90'

=item osvers()

The _interpreted_ version of the Operating System. For instance, 'ME' rather
than '9x 4.90'

Note: Windows NT versions below 5 will show up with ostype 'Windows NT' and
osvers as appropriate. Windows NT versions 5 and up will show up as ostype
'Windows NT' and osvers '2000'. Most of you know, but for those who don't: Windows 2000 is a version of NT, not of the 9x kernel and filesystem. I'll just have
to wait and see what to expect for XP.

=item osarc()

While rarely defined, some User Agent strings happily announce some detail or
another about the Architecture they are running under. If this happens, it will
be reflected here. Linux ('i686') and Mac ('PPC') are more likely than Windows
to do this, strangely.

=back

=head1 SEE ALSO

=head2 Modules

HTTP::BrowserDetect (similar goal but with an opposite approach)

=head2 Web Sites

=over 6

=item Distribution Site - http://www.dodger.org/modules

=back 

=head1 AUTHOR

Dodger (aka Sean Cannon)
in association with the Necrosoft Network (www.necrosoft.net)

=head1 COPYRIGHT

The HTML::ParseBrowser module and code therein is
Copyright (c)2001 Sean Cannon, Bensalem, Pennsylvania.

All rights reserved. All rites reversed.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
