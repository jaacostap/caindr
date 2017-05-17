# cimcentroid - search input image offset
# Author : Miguel Charcos (mcharcos@ll.iac.es)
# Version: 26. Nov. 2003
##############################################################################
procedure cimcentroid (input, fstars, outshift, inshift)

string 	input		{prompt="List of checked input images"}
string	fstars		{prompt="Position file of stars considered"}
string 	outshift	{prompt="Shift file  result of images"}
string 	inshift		{prompt="Initial shift file "}
int 	boxsize		{"7",prompt="Size of the fine centering box"}
int	bigbox		{"11",prompt="Size of the coarse centering box"}
bool	negative	{"no",prompt="Are the features negative ?"}
real	background	{INDEF,prompt="Reference background level"}
real	lower		{INDEF,prompt="Lower threshold for data"}
real	upper		{INDEF,prompt="Upper threshold for data"}
int	niterate	{3,prompt="Maximum number of iterations"}
int	tolerance 	{0,prompt="Tolerance for convergence"}
bool	verbose 	{"yes",prompt="Print the centroids for every source ?"}


string *list1	{prompt="Ignore this parameter(list1)"}
string *list2	{prompt="Ignore this parameter(list2)"}
string *list3	{prompt="Ignore this parameter(list3)"}

begin

  string	inli,insh,outsh,tfstar
  string 	imref,junk1,junk2,fname
  int		nsc
  real		xr,yr,x,y,xi,yi
  string	tcent

  tfstar = fstars
  insh = inshift
  outsh = outshift

  if (access(outsh))
    {
    beep
    print("")
    print("ERROR: operation would overwrite output shift file "//outsh)
    print("limcentroid aborted")
    print("")
    beep
    bye
    }
    
  inli = mktemp("limcentroidinli")  
  sections(input,option="fullname",>inli)  
  list1 = inli
  nsc = fscan (list1,imref)
  tcent = mktemp("limcentroidtcent")
  
  imcentroid ( input = "@"//inli,
  	   reference = imref,
  	      coords = tfstar,
  	      shifts = insh,
  	     boxsize = boxsize,
  	      bigbox = bigbox,
  	    negative = negative,
  	  background = background,
  	       lower = lower,
  	       upper = upper,
  	    niterate = niterate,
  	   tolerance = tolerance,
  	     verbose = verbose, > tcent)
  
  # read centroiding information
  list2 = tcent
  nsc = fscan (list2)
  
  # We read logfile until found "#Shift"
  while (fscan (list2, junk1) != EOF)
    {if (junk1 == "#Shifts") break}
  
  
  list1 = inli
  list3 = insh
  while (fscan (list2, junk1, x, junk2, y) != EOF)
    {
    While (fscan (list1,fname) != EOF)
      {
      if (fscan (list3, xr,yr) == EOF)
        {
        beep
        print("")
        print("ERROR: wrong shift file format")
        print("limcentroid aborted")
        print("")
        beep
        bye
	}
      if (fname == junk1)
        {
	## round off value to avoid 1 pixel offset due to imcombine truncation
	## of the offset values
	if (x != 0) 
	  xi = int(x+0.5*x/abs(x))
	else 
	  xi = x  
	if (y != 0) 
	  yi = int(y+0.5*y/abs(y))
	else 
	  yi = y  
	print(xi," ",yi, >> outsh)
	break
	}
      else 
        {
	print(xr," ",yr, >> outsh)
	}
      } # End of While (fscan (list1=inli,fname) != EOF)
    } # End of while (fscan (list2=tcent, junk1, x, junk2, y) != EOF)
    
  delete (tcent,yes,verif-)
  delete (inli,yes,verif-)

  list1 = ""
  list2 = ""
  list3 = ""

end
