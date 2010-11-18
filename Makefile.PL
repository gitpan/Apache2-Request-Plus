use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'            => "Apache2::Request::Plus",
	'VERSION_FROM'    => "Plus.pm", # finds $VERSION
	'PREREQ_PM'       => {
		'String::Util' => 1.01,
		'Debug::ShowStuff' => 1.1,
	}, # e.g., Module::Name => 1.1
	
	# Add these new keywords supported since 5.005
	(
		$] >= 5.005 ?
			(
				ABSTRACT_FROM  => "Plus.pm", # retrieve abstract from module
				AUTHOR         => "Miko O'Sullivan <miko\@idocs.com>"
			) :
			
			()
	),
);
