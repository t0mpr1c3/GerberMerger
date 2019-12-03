#!/usr/bin/perl
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
#                     merge drill files
#
###################################################################################################################
#
#
# if only one .TXT file, copy it to output
if (!-e "$x.TXT" && !-e "$y.TXT")
{
  print STDERR "Warning: can't find drill files $x.TXT or $y.TXT\n";
}
elsif (-e "$x.TXT" && !-e "$y.TXT")
{
  print STDERR "Warning: can't find drill file $y.TXT\n";
  system("cp $x.TXT $z.TXT") == 0 or die "Can't copy to file $z.TXT";
}
elsif (!-e "$x.TXT" && -e "$y.TXT")
{
  print STDERR "Warning: can't find drill file $x.TXT\n";
  system("cp $y.TXT $z.TXT") == 0 or die "Can't copy to file $z.TXT";
} else
{
  open( INX, "$x.TXT" ) or die "Can't open file $x.TXT for input";
  open( INY, "$y.TXT" ) or die "Can't open file $y.TXT for input";
  open( OUT, ">$z.TXT" ) or die "Can't open file $z.TXT for output";
  #
  # get header rows
  $next = 1;
  do
  {
    $a = <INX>;
    $b = <INY>;
    if ( $a =~ /^T\d+C[0-9.]+/ || $b =~ /^T\d+C[0-9.]+/ )
    {
      $next = 0;
    } elsif ( $a ne $b )
    { 
      die ".TXT file headers do not match";
    } else
    {
      print OUT $a;
    }
  } while ( $a && $b && $next );
  #
  # get drill diameters
  %drill = ();
  $k = 1;
  %diameter = ();
  $next = 1;
  %diameterx = ();
  %diametery = ();
  do
  {
    if ( $a =~ /^T(\d+)C([0-9.]+)/ )
    {
      ( $i, $j ) = ( $1, $2 );
      $diameterx{ $i } = $j;
      if ( !exists( $drill{ $j } ) )
      {
        $diameter{ $k } = $j;
        $drill{ $j } = $k;
        $k++;
      }
      $a = <INX>;
    } else
    {
      $next = 0;
    }
  } while ( $a && $next );
  $next = 1;
  do
  {
    if ( $b =~ /^T(\d+)C([0-9.]+)/ )
    {
      ( $i, $j ) = ( $1, $2 );
      $diametery{ $i } = $j;
      if ( !exists( $drill{ $j } ) )
      {
        $diameter{ $k } = $j;
        $drill{ $j } = $k;
        $k++;
      }
      $b = <INY>;
    } else
    {
      $next = 0;
    }
  } while ( $b && $next );
  for ( $i = 1; $i < $k; $i++ )
  {
    print OUT "T" . $i . "C" . $diameter{ $i } . "\n";
  }
  print OUT "%\n";
  #
  # loop over X drills
  $a = <INX>;
  chomp $a;
  if ( $a =~ /\r$/ )
  {
    chop $a; # remove CR
  }
  while ( $a && $a !~ /^M/ )
  {
    if ( $a =~ /^T(\d+)/ )
    {
      $i = $1;
      print OUT "T" . $drill{ $diameterx{ $i } } . "\n";
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
    }
  }
  #
  # loop over Y drills
  $b = <INY>;
  chomp $b;
  if ( $b =~ /\r$/ )
  {
    chop $b; # remove CR
  }
  while ( $b && $b !~ /^M/ )
  {
    if ( $b =~ /^T(\d+)/ )
    {
      $i = $1;
      print OUT "T" . $drill{ $diametery{ $i } } . "\n";
      # print feature locations from Y with offsets
      $next = 1;
      do
      {
        $b = <INY>;
        if ( $b =~ /^X/ )
        {
          ( $dummy, $xloc, $yloc ) = split( /[XY]/, $b );
          $xloc += $xoffset / 10;
          $yloc += $yoffset / 10;
          print OUT "X$xloc" . "Y$yloc\n";
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
  #
  die if ( $a ne $b );
  print OUT $a . "\n";
  #
  # end
  close( INX );
  close( INY );
  close( OUT );
}
#
#
###################################################################################################################
#
#                     merge subroutine
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
    if ( $a =~ /^G01[*]/ && $b =~ /^G01[*]/ )
    {
      print OUT "G01*\n";
      $next = 0;
    } elsif ( $a ne $b )
    { 
      print "Error:\n";
      print $a;
      print $b;
      die ".$suffix file headers do not match";
    } else
    {
      print OUT $a;
    }
  } while ( $a && $b && $next );
  #
  # get apertures
  %aperture = ();
  %attribute = ();
  $k = 10;
  $next = 1;
  %aperturex = ();
  do
  {
  	$a = <INX>;
    if ( $a =~ /%ADD(\d+)C,(.*)/ )
    {
      $i = $1;
      $j = $2;
      $aperturex{ $i } = $j;
      if ( !exists( $attribute{ $j } ) )
      {
        $attribute{ $j } = $k;
        $aperture{ $k } = $j;
        $k++; 
      }
    } else
    {
      $next = 0;
    }
  } while ( $a && $next );
  $next = 1;
  %aperturey = ();
  do
  {
  	$b = <INY>;
    if ( $b =~ /%ADD(\d+)C,(.*)/ )
    {
      $i = $1;
      $j = $2;
      $aperturey{ $i } = $j;
      if ( !exists( $attribute{ $j } ) )
      {
        $attribute{ $j } = $k;
        $aperture{ $k } = $j;
        $k++; 
      }
    } else
    {
      $next = 0;
    }
  } while ( $b && $next );
  for ( $i = 10; $i < $k; $i++ )
  {
  	printf OUT "%%ADD%iC,%s\n", $i, $aperture{ $i };
  }
  #
  # loop over X fill areas, if any
  $fill = 0;
  if ( $a eq "\n" )
  {
    $a = <INX>;
  }
  while ( $a =~ /^G36[*]/ )
  {
    $fill = 1;
    print OUT "G36*\n";
    # print fill locations from X without offsets
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
    if ( $a !~ /^G37[*]/ )
    {
      die "Can't find G37* at end of G36* block\n";
    }
    $a = <INX>;
  }
  #
  # loop over Y fill areas, if any
  if ( $b eq "\n" )
  {
    $b = <INY>;
  }
  while ( $b =~ /^G36[*]/ )
  {
    if ( $fill == 0 )
    {
      print OUT "G36*\n";
    }
    $fill = 1;
    # print fill locations from Y with offsets
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
    if ( $b !~ /^G37[*]/ )
    {
      die "Can't find G37* at end of G36* block\n";
    }
    $b = <INY>;
  }
  #
  if ( $fill == 1 )
  {
    print OUT "G37*\n";
  }
  #
  # loop over X apertures
  ##$a = <INX>;
  if ( $a eq "\n" )
  {
    $a = <INX>;
  }
  chomp $a;
  if ( $a =~ /\r$/ )
  {
    chop $a; # remove CR
  }
  while ( $a && $a !~ /^M/ )
  {
    if ( $a =~ /^D(\d+)[*]/ )
    {
      $i = $1;
      print OUT "D" . $attribute{ $aperturex{ $i } } . "*\n";
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
    }
  }
  #
  # loop over Y apertures
  ##$b = <INY>;
  if ( $b eq "\n" )
  {
    $b = <INY>;
  }
  chomp $b;
  if ( $b =~ /\r$/ )
  {
    chop $b; # remove CR
  }
  while ( $b && $b !~ /^M/ )
  {
    if ( $b =~ /^D(\d+)[*]/ )
    {
      $i = $1;
      print OUT "D" . $attribute{ $aperturey{ $i } } . "*\n";
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
    }
  }
  #
  die if ( $a ne $b );
  print OUT $a . "\n";
  #
  # end
  close( INX );
  close( INY );
  close( OUT );
}
#
#
merge( "GTL" );
merge( "GTS" );
merge( "GTO" );
merge( "GTP" );
merge( "GBL" );
merge( "GBS" );
merge( "GBO" );
merge( "GBP" );
merge( "GML" );

