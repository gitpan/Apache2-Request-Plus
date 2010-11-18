package Apache2::Request::Plus;
use strict;
use Debug::ShowStuff ':all';
use String::Util ':all';
use Apache2::RequestUtil;
use base 'Apache2::Request';

# version
use vars '$VERSION';
$VERSION = '0.10';


=head1 NAME

Apache2::Request::Plus -- A few extra features added to Apache2::Request.

=head1 SYNOPSIS

 use Apache2::Request::Plus;

 my $r = Apache2::Request::Plus->new();

 # anything you can already do with Apache2::Request
 $r->content_type('text/html');
 $r->headers_out->set('charset' => 'ISO-8859-1');

 # was the form submitted (as opposed to just a request sent)?
 if ($r->form_sent) {
   # stuff
 }

=head1 DESCRIPTION

The original purpose of Apache2::Request::Plus was to make a mod_perl request
object that had some of the features of an old school CGI.pm object.  An object
of this class gives the request object some methods like textfield()
and popup_menu() which you may be used to from CGI.pm

Since its creation this module has also some other convenient methods for
creating and processing web forms.

=head1 INSTALLATION

Apache2::Request::Plus can be installed with the usual routine:

	perl Makefile.PL
	make
	make test
	make install

=head1 Paradigm: submit to self and form_sent

The methods in this module are built around the idea that the web page form
submits back to itself.  That is, the form's action is the current page.

The methods detect if the request was submitted by the form (as opposed to
a request from some other source) by looking for a request parameter called
"form_sent".  By defaul the C<$r->form_open()> method adds a hidden field
with the name "form_sent" and the value "1".

=head1 METHODS


=cut


#------------------------------------------------------------------------------
# new
#

=head2 Apache2::Request::Plus->new()

Instantiates a new Apache2::Request::Plus object.  No parameters
needed or used.

=cut

sub new {
	my ($class) = @_;
	my $r = Apache2::Request->new(Apache2::RequestUtil->request());
	bless $r, $class;
	
	return $r;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# formopen
#

=head2 $r->formopen()

Returns a <form> tag with optional attributes.  The form submits to the current
page.

Its simplest use:

 print $r->formopen();

outputs a <form> element with a GET method and directing the browser right back
to the current page.  The hidden "form_sent" field is added directly after the
<form> tag.

 <form action="/path/to/current/page.pl" method="GET">
 <input type="hidden" name="form_sent" value="1">

B<option:> -action

Sets the URI of the page the form should submit to.  Defaults to the current
page.  So, for example, this call

 print $r->formopen(-action=>'mypage.pl');

results in this HTML:

 <form action="mypage.pl" method="GET">
 <input type="hidden" name="form_sent" value="1">

B<option:> -method

Set the method.  Usually the method is either GET or POST, though there are
other HTTP headers out there too.  Defaults to GET.  So, this code

 print $r->formopen(-method=>'POST');

outputs this HTML:

 <form action="/path/to/current/page.pl" method="POST">
 <input type="hidden" name="form_sent" value="1">

B<option:> -form_sent

If this option is true then the hidden "form_sent" field is added to the
output.  See notes on the C<$->form_sent()> method.

This code

 print $r->formopen(-form_sent=>0);

results in this HTML:

 <form action="/path/to/current/page.pl" method="GET">

B<other options>

Any other options sent are output as tag attributes.  For example, this
code:

 print $r->formopen(-foo=>'bar');

outputs this HTML:

 <form action="/path/to/current/page.pl" method="GET" foo="bar">
 <input type="hidden" name="form_sent" value="1">

=cut

my %formopen_options = (
	-action => 1,
	-method => 1,
	-form_sent => 1,
);

sub formopen {
	my ($r, %opts) = @_;
	my ($rv, $val);
	
	# open tag
	$rv = '<form';
	
	# action
	if (defined $opts{'-action'})
		{ $rv .= add_att('action', $opts{'-action'}) }
	else
		{ $rv .= add_att('action', $r->uri) }
	
	# method
	if (defined $opts{'-method'})
		{ $rv .= add_att('method', $opts{'-method'}) }
	else
		{ $rv .= add_att('method', $r->method) }
	
	# all other options
	$rv .= other_options(\%formopen_options, \%opts);
	
	# close tag
	$rv .= '>';
	
	# form_sent hidden field
	unless ( defined($opts{'-form_sent'}) && ! $opts{'-form_sent'} )
		{ $rv .= qq|\n<input type="hidden" name="form_sent" value="1">| }
	
	# return
	return $rv;
}
#
# formopen
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# form_sent
#

=head2 $r->form_sent

Returns true if the "form_sent" param was sent as true.

This is handy for discerning the difference between a request for a page that
was sent from the form in that page, and one that was requested from outside
the page.  This distinction is simply made by looking for a parameter called
"form_sent".

For example, if the form is opened with this HTML:

 <form action="mypage.pl" method="GET">
 <input type="hidden" name="form_sent" value="1">

then when the form is submitted, $r->form_sent will evaluate to true.

=cut

sub form_sent {
	return $_[0]->param('form_sent');
}
#
# form_sent
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# textfield
#
my %textfield_general_options = (
	-name => 1,
	-value => 1,
);

=head2 $r->textfield()

Mimics CGI.pm's C<textfield()> function.  This method is not fully implemented
to provide every feature of CGI.pm's C<textfield()>. Currently provides just
the -name option and the ability to add other miscellaneous attributes.

=cut

sub textfield {
	my $r = shift;
	return $r->textfield_general('text', @_);
}

=head2 $r->hidden()

Mimics CGI.pm's C<hidden()> function.  This method is not fully implemented
to provide every feature of CGI.pm's C<hidden()>. Currently provides just
the -name option and the ability to add other miscellaneous attributes.

=cut

sub hidden {
	my $r = shift;
	return $r->textfield_general('hidden', @_);
}

=head2 $r->hiddenfield()

Works exactly like C<$r->hidden()>.  I just added this function for consistency:
if there's a "textfield" method then I felt like there ought to be a
hiddenfield() method.  My dad the engineer would be proud.

=cut

sub hiddenfield {
	my $r = shift;
	return $r->textfield_general('hidden', @_);
}

# PRIVATE method: $r->textfield_general()
# This method actually does all the work of textfield(), hidden(), and
# hiddenfield().

sub textfield_general {
	my ($r, $field_type, %opts) = @_;
	my ($rv, $val);
	
	# open tag
	$rv = qq|<input type="$field_type"|;
	
	# name and value
	if (defined $opts{'-name'}) {
		my ($sent_val);
		$rv .= qq| name="$opts{'-name'}"|;
		
		# get sent_val
		$sent_val = $r->param($opts{'-name'});
		
		# value
		if ($r->form_sent)
			{ $val = $sent_val }
		elsif (defined $opts{'-value'})
			{ $val = $opts{'-value'} }
	}
	
	# else no name, use value if sent
	elsif (defined $opts{'-value'}) {
		$val = $opts{'-value'};
	}
	
	# add value attribute
	if (defined $val)
		{ $rv .= ' value="' . htmlesc($val) . '"' }
	
	# all other options
	$rv .= other_options(\%textfield_general_options, \%opts);
	
	# close tag
	$rv .= '>';
	
	# return
	return $rv;
}
#
# textfield
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# textarea
#

=head2 $r->textarea()

Mimics CGI.pm's C<textarea()> function.  This method is not fully implemented
to provide every feature of CGI.pm's C<textarea()>.  Currently provides just
the -name option and the ability to add other miscellaneous attributes.

=cut

sub textarea {
	my ($r, %opts) = @_;
	my ($rv);
	
	# open tag
	$rv = qq|<textarea|;
	
	# name
	if (defined $opts{'-name'}) {
		$rv .= qq| name="$opts{'-name'}"|;
	}
	
	# all other options
	$rv .= other_options(\%textfield_general_options, \%opts);
	
	# close opening tag
	$rv .= '>';
	
	# if form was sent and not force-value
	if (
		$r->form_sent &&
		defined($opts{'-name'}) &&
		(! $opts{'-force-value'})
		) {
		$rv .= htmlesc($r->param($opts{'-name'}));
	}
	
	# else use value option if sent
	elsif (defined $opts{'-value'}) {
		$rv .= $opts{'-value'};
	}
	
	# closing tag
	$rv .= '</textarea>';
	
	# return
	return $rv;
}
#
# textarea
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# selectfield
#

=head2 $r->selectfield()

Similar to CGI.pm's popup_menu function.  This method is named "selectfield"
because 1) it doesn't actually work just like popup_menu so it has a different
name to avoid confusion, and 2) I never really liked the name popup_menu()
anyway.

The first argument is the name of the select field.  The second argument is an
array ref (not an array!) of options.  Each option should be a hashref with
the value of the option, and, optionally, the text for the option.  If the
"selected" key is also set in the hashref, and if the form was *not* sent then
that option is the default selected option.

For example, this code:

 my @options;

 push @options, {value=>'stooge1', text=>'Larry'};
 push @options, {value=>'stooge2', text=>'Curly'};
 push @options, {value=>'stooge3', text=>'Moe', selected=>1};

 # Note that a *reference* to the array is sent, not just the array!
 print $r->selectfield('stooges', \@options);

Outputs the following HTML if the form has not been sent.

 <select name="stooges">
 <option value="stooge1">Larry</option>
 <option value="stooge2">Curly</option>
 <option value="stooge3" selected="true">Moe</option>
 </select>

=cut

sub selectfield {
	my ($r, $name, $options) = @_;
	my ($rv, $sent_val, $form_sent);
	$rv = '';
	
	# get sent value
	if ($r->form_sent)
		{ $sent_val = $r->param($name) }
	
	# open element
	$rv .= qq|<select name="$name">\n|;
	
	# loop through options
	foreach my $opt (@$options) {
		# begin opening tag
		$rv .= '<option';
		
		# set value of option if sent
		if (defined $opt->{'value'}) {
			$rv .= qq| value="$opt->{'value'}"|;
			
			# set as selected option if value was sent
			if ($r->form_sent && equndef($sent_val, $opt->{'value'}))
				{ $rv .= ' selected="true"' }
		}
		
		# if set as selected and form was not submitted
		if ( (! $r->form_sent) && $opt->{'selected'} )
			{ $rv .= ' selected="true"' }
		
		# closing opening tag
		$rv .= '>';
		
		if (defined $opt->{'text'})
			{ $rv .= $opt->{'text'} }
		
		$rv .= "</option>\n";
	}
	
	
	# close element
	$rv .= qq|</select>|;
	
	# return
	return $rv;
}
#
# selectfield
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# get_cookie
#

=head2 $r->get_cookie($cookie_name)

Given a cookie name, returns the cookie's value. For example, this code:

 $r->get_cookie('sessionx');

might return something like this:

 sessionx=505-6

Note that the cookie includes the name of the cookie followed by an
equals sign followed by the value.

=cut

sub get_cookie {
	my ($r, $key) = @_;
	my $pnotes = $r->pnotes('cookies');
	
	# set cookies hash if it doesn't already exist
	if (! $pnotes->{'cookies'}) {
		$pnotes->{'cookies'} = Apache2::Cookie->fetch($r);
	}
	
	# get cookie
	return $pnotes->{'cookies'}->{$key};
}
#
# get_cookie
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# other_options
# Private function.  Given a hash, returns the name=values pairs as HTML
# attributes.  Will not add attributes already defined in the hash ref that
# is the first param.
#
sub other_options {
	my ($defined, $opts) = @_;
	my $rv = '';
	
	OPT_LOOP:
	while (my ($k,$v) = each(%$opts)) {
		$defined->{$k} and next OPT_LOOP;
		$k =~ s|^\-||s;
		$rv .= add_att($k, $v);
	}
	
	return $rv;
}
#
# other_options
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# add_att
#
# Private function.  Given an attribute name and value, returns them
# for use as an attribute in an HTML tag.
#
sub add_att {
	my ($k, $v) = @_;
	return qq| $k="| . htmlesc($v) . '"';
}
#
# add_att
#------------------------------------------------------------------------------



# return true
1;

__END__


=head1 TERMS AND CONDITIONS

Copyright (c) 2010 by Miko O'Sullivan.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHORS

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

=over

=item Version 0.10    November 17, 2010

Initial release

=back


=cut
