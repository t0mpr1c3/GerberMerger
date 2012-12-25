# Notes on merging Gerbers
#
# Perl script to merge FusionPCB gerbers
#
# usage:
# GerberMerger.pl prefixA prefixB Xoffset Yoffset
#
# prefixA, prefixB = prefix names of gerber files
# Xoffset, Yoffset = Cartesian offset of prefixB files relative to prefixA files, units = 1/10 mil
#
$x = $ARGV[ 0 ];
$y = $ARGV[ 1 ];
$xoffset = $ARGV[ 2 ];
$yoffset = $ARGV[ 3 ];
$z = $x . "_" . $y;
#
#
###################################################################################################################
#
# 											merge drill files
#
###################################################################################################################
#
#
open( INX, "$x.TXT" ) or die "Can't open file $x.TXT for input";
open( INY, "$y.TXT" ) or die "Can't open file $y.TXT for input";
open( OUT, ">$z.TXT" ) or die "Can't open file $z.TXT for output";
#
# get header
#
# get initial %
$i = 0;
$next = 1;
do
{ 
	$i++; 
	$_ = <INX>; 
	$next = !( /%/ ); 
}
while ( $_ && $next );
$i = 0;
$next = 1;
do
{ 
	$i++; 
	$_ = <INY>; 
	$next = !( /%/ ); 
}
while ( $_ && $next );
print OUT "%\n";
#
# get header rows
$next = 1;
do
{
	$a = <INX>;
	$b = <INY>;
	if ( $a =~ /^T/ || $b =~ /^T/ )
	{
		$next = 0;
	} elsif ( $a ne $b )
	{	
		die;
	} else
	{
		print OUT $a;
	}
} while ( $a && $b && $next );
#
# get drill diameters
%drill = ();
$next = 1;
%diameterx = ();
do
{
	if ( $a =~ /^T/ )
	{
		( $i, $j ) = split( /C/, $a );
		$diameterx{ $i } = $j;
		$drill{ $j }++;
		$a = <INX>;
	} else
	{
		$next = 0;
	}
} while ( $a && $next );
$next = 1;
%diametery = ();
do
{
	if ( $b =~ /^T/ )
	{
		( $i, $j ) = split( /C/, $b );
		$diametery{ $i } = $j;
		$drill{ $j }++;
		$b = <INY>;
	} else
	{
		$next = 0;
	}
} while ( $b && $next );
#
# merge drill diameters
@diameter = sort keys %drill;
for ( $i = 0; $i < @diameter; $i++ )
{
	$drill{ $diameter[ $i ] } = sprintf( "T%0.2i", $i + 1 ); 
	print OUT $drill{ $diameter[ $i ] } . "C" . $diameter[ $i ];
}
print OUT "%\n";
#
# loop over drill diameters
$a = <INX>;
chomp $a;
if ( $a =~ /\r$/ )
{
	chop $a; # remove CR
}
$b = <INY>;
chomp $b;
if ( $b =~ /\r$/ )
{
	chop $b; # remove CR
}
for ( $i = 0; $i < @diameter; $i++ )
{
	print OUT $drill{ $diameter[ $i ] } . "\n";
	$xnext = 0;
	$ynext = 0;
	if ( $diameterx{ $a } && $diametery{ $b } && ( $diameterx{ $a } <= $diametery{ $b } ) )
	{
		$xnext++;
	}
	if ( $diameterx{ $a } && $diametery{ $b } && ( $diameterx{ $a } >= $diametery{ $b } ) )
	{
		$ynext++;
	}
	if ( $diameterx{ $a } && !$diametery{ $b } )
	{
		$xnext++;
	}
	if ( !$diameterx{ $a } && $diametery{ $b } )
	{
		$ynext++;
	}
	if ( $xnext )
	{
		# print drill locations from X without offsets
		$next = 1;
		##print "X\n";
		##print "$a\n";
		##print $diameterx{$a}."\n";
		do
		{
			$a = <INX>;
			if ( $a =~ /^X/ )
			{
				print OUT $a;
			} else
			{
				chomp $a;
				if ( $a =~ /\r$/ )
				{
					chop $a; # remove CR
				}
				$next = 0;
			}
		}
		while ( $next );
	} 
	if ( $ynext )
	{
		# print drill locations from X with offsets
		$next = 1;
		##print "Y\n";
		##print "$b\n";
		##print $diameterx{$b}."\n";
		do
		{
			$b = <INY>;
			if ( $b =~ /^X/ )
			{
				( $dummy, $xloc, $yloc ) = split( /[XY]/, $b );
				$xloc += $xoffset;
				$yloc += $yoffset;
				print OUT "X$xloc" . "Y$yloc" . "\n";
			} else
			{
				chomp $b;
				if ( $b =~ /\r$/ )
				{
					chop $b; # remove CR
				}
				$next = 0;
			}
		}
		while ( $next );
	}
}
if ( $a ne $b )
{
	print "$a\n";
	print "$b\n";
	die;
};
print OUT $a . "\n";
#
# end
close( INX );
close( INY );
close( OUT );
#
#
###################################################################################################################
#
# 											merge subroutine
#
###################################################################################################################
#
#
sub merge( $ )
{
	( $suffix ) = @_;
	open( INX, "$x.$suffix" ) or die "Can't open file $x.$suffix for input";
	open( INY, "$y.$suffix" ) or die "Can't open file $y.$suffix for input";
	open( OUT, ">$z.$suffix" ) or die "Can't open file $z.$suffix for output";
	# get header rows
	$next = 1;
	do
	{
		$a = <INX>;
		$b = <INY>;
		if ( $a =~ /^%ADD/ || $b =~ /^%ADD/ )
		{
			$next = 0;
		} elsif ( $a ne $b )
		{	
			die;
		} else
		{
			print OUT $a;
		}
	} while ( $a && $b && $next );
	#
	#
	# get features
	@attribute = ();
	$k = 0;
	$next = 1;
	@attributex = ();
	do
	{
		if ( $a =~ /^%ADD/ )
		{
			$a =~ /%ADD(\d+)(.*)/;
			$i = "D" . $1 . "*";
			$j = $2;

			push @attributex, $i;
			push @attribute, sprintf( "D%i*", $k + 10 ); 
			printf OUT "%%ADD%0.2i%s\n", $k + 10, $j;
			$k++;
			$a = <INX>;
		} else
		{
			$next = 0;
		}
	} while ( $a && $next );
	$next = 1;
	@attributey = ();
	do
	{
		if ( $b =~ /^%ADD/ )
		{
			$b =~ /%ADD(\d+)(.*)/;
			$i = "D" . $1 . "*";
			$j = $2;
			push @attributey, $i;
			push @attribute, sprintf( "D%i*", $k + 10 ); 
			printf OUT "%%ADD%0.2i%s\n", $k + 10, $j;
			$k++;
			$b = <INY>;
		} else
		{
			$next = 0;
		}
	} while ( $b && $next );
	#
	# loop over X feature attributes
	##$a = <INX>;
	chomp $a;
	if ( $a =~ /\r$/ )
	{
		chop $a; # remove CR
	}
	$k = 0;
	for ( $i = 0; $i < @attributex; $i++, $k++ )
	{
		print OUT $attribute[ $k ] . "\n";
		if ( $attributex[ $i ] eq $a )
		{
			# print feature locations from X without offsets
			$next = 1;
			do
			{
				$a = <INX>;
				if ( $a =~ /^X/ )
				{
					print OUT $a;
				} else
				{
					chomp $a;
					if ( $a =~ /\r$/ )
					{
						chop $a; # remove CR
					}
					$next = 0;
				}
			}
			while ( $next );
		} else
		{
			print "$a\n";
			print "$i\n";
			print $attributex[ $i ] . "\n";
			print "$k\n";
			print $attribute[ $k ] . "\n";
			die;
		}
	}
	#
	# loop over Y feature attributes
	##$b = <INY>;
	chomp $b;
	if ( $b =~ /\r$/ )
	{
		chop $b; # remove CR
	}
	for ( $i = 0; $i < @attributey; $i++, $k++ )
	{
		print OUT $attribute[ $k ] . "\n";
		if ( $attributey[ $i ] eq $b )
		{
			# print feature locations from Y with offsets
			$next = 1;
			do
			{
				$b = <INY>;
				if ( $b =~ /^X/ )
				{
					( $dummy, $xloc, $yloc, $rest ) = split( /[XYD]/, $b );
					$xloc += $xoffset;
					$yloc += $yoffset;
					print OUT "X$xloc" . "Y$yloc" . "D$rest";
				} else
				{
					chomp $b;
					if ( $b =~ /\r$/ )
					{
						chop $b; # remove CR
					}
					$next = 0;
				}
			}
			while ( $next );
		} else
		{
			print "$b\n";
			print "$i\n";
			print $attributey[ $i ] . "\n";
			print "$k\n";
			print $attribute[ $k ] . "\n";
			die;
		}
	}
	die if ( $a ne $b );
	print OUT $a . "\n";
	close( INX );
	close( INY );
	close( OUT );
}
#
#
merge( "GTL" );
merge( "GTS" );
merge( "GTO" );
merge( "GBL" );
merge( "GBS" );
merge( "GBO" );

