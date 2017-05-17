procedure cfilename(filename)

# Routine to parse a file name into its root and extension.
# The extension is assumed to be the portion of the file name
# which follows the last period in the input string supplied
# by the user;   the root is everything which preceeds that period.
#
# 930816: Included parameter 'validim' to force a check to see if the extension 
# represents a valid IRAF image datatype, and if not, to negate the parsing.  
# This would be a common usage;  often the user only wants to strip off the 
# portion of the filename after the last period if that substring represents a 
# valid IRAF image type such as .imh or .pl.  Without the 'validim' parameter, 
# if the file included another period somewhere in its name, then the portion 
# of the filename after that period would be erroneously returned as an image 
# extension.  At present, the routine only checks for a few datatypes;  
# this should be expanded in the future.
# 980622: updated valid ID headers to include FITS (fts and fits) for V2.11 
# 990112: updated valid ID headers to include FITS (fit) for V2.11 
## 17-Oct-04: corrected a bug to deal with directory names including a period (JACOSTA)

string	filename 	{prompt="File name"}
bool		validim	{yes,prompt="Parse only if extension represents valid image datatype?"}
string	root		{"",prompt="Returned filename root"}
string	extension	{"",prompt="Returned filename extension"}
string	imgext	{"",prompt="Returned image extension"}
string	path		{"",prompt="Returned filename path"}
string	reference	{"",prompt="Returned filename reference"}

begin

	string	fname			# Equals filename
	string	revname		# Reversed version of input string
	int 	ilen,ipos,ic		# String position markers
	int 	ipos_dir			# String position markers
	int	ipos_ref			# String position markers
	int	ipos_iext1,ipos_iext2	# String position markers
	int	ii				# Counter
	int	rootlen,reflen

	string	imtype 	=	"imh",		
				"fits",
				"fts",
				"fit",
				"hhh",
				"pl",
				"qpoe",
				"qp",
				""	# Must use null string to terminate!

# Get query parameter.

	fname = osfn(filename)

# Reverse filename string character by character --> revname.

	ilen = strlen(fname)
	revname = ""
	for (ic=ilen; ic>=1; ic-=1) {
		revname = revname // substr(fname,ic,ic)
	}

# Look for the first period in the reversed name. It may happen that the 
# path name contains a period in the whole path. Then ipos_dir < ipos 

	ipos = stridx(".",revname)
	
	ipos_dir = stridx("/",revname)
	
	
	if (ipos > ipos_dir && ipos_dir > 0)
	  { ipos = 0 } 
	
	#ipos_ref = stridx("_",revname)
	
	ipos_iext1 = stridx("[",revname)
	ipos_iext2 = stridx("]",revname)
	
	
##	if (ipos_dir!=0)
##	  {
##	  if (ipos_ref > ipos_dir && ipos_dir!=0) 
##	    {ipos_ref=0}
##	  if (ipos_iext1 > ipos_dir || ipos_iext2 > ipos_dir ) 
##	    {
##	    ipos_iext1=0
##	    ipos_iext2=0
##	    }
##	  }

# If period exists, break filename into root and extension.  Otherwise,
# return null values for the extension, and the whole file name for the root.


	if (ipos_dir != 0) 
	  {path = substr(fname,1,ilen-ipos_dir+1)} 
	else 
	  {
	  path = osfn("./")
	  #path = ""
	  ipos_dir=ilen+1
	  }

	if (ipos != 0) 
	  {
	  root = substr(fname,ilen-ipos_dir+2,ilen-ipos)
	  extension = substr(fname,ilen-ipos+2,ilen)
	  } 
	else 
	  {
	  root = substr(fname,ilen-ipos_dir+2,ilen)
	  extension = ""
	  }

##	if (ipos_ref != 0) 
##	  {reference = substr(fname,ilen-ipos_ref+2,ilen-ipos)} 
##	else 
	  {reference = root}


      if (ipos_iext1 !=0)
	  {
	  imgext = substr(fname,ilen-ipos_iext1+2,ilen-ipos_iext2)
	  
	  if (ipos_iext1 > ipos)
	    {
	    rootlen = strlen(root)
	    reflen = strlen(reference)
	    root = substr(root,1,rootlen-ipos_iext1+ipos_iext2-1)
	    reference = substr(reference,1,reflen-ipos_iext1+ipos_iext2-1)
	    }
	  else
	    {
	    extension = substr(fname,ilen-ipos+2,ilen-ipos_iext1)
	    }
	  }
      else
	  {imgext = ""}

# If validim = yes and extension != "", check to see if the parsed extension
# is a string indicating a valid image data type, e.g. "imh", "pl", etc.  
# If not, then undo the parsing, replacing the root with the complete input
# string 'filename' and setting the extension to null.

	if (validim && extension != "") {
		ii = 1
		while (imtype[ii] != "") {
			if (extension == imtype[ii]) break
			ii += 1
		}
		if (imtype[ii] == "") {
			path = ""
			root = fname
			extension = ""
			reference = ""
		}
	}

end
