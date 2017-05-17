# imarkstar - mark a star in an image
# Author     : Robert Greimel (greimel@ing.iac.es)
#              1. Aug. 2000  
# Last Change: J Acosta (change to use imcntr instead of imcentroid
#              10. Jul. 2004
#  
##############################################################################
procedure cmarkstar(input)

file	input		{prompt="Input image"}
real	x		{prompt="X position (return)"}
real	y		{prompt="Y position (return)"}
string	key		{prompt="key (return)"}
bool	verbose		{prompt="Verbose ?"}
string *list		{prompt="Ignore this parameter(list)"}


begin

  string	imgname
  string	range,junk
  struct	cmd
  file		tf1,tf2
  int		wcs,nsc,ix1,iy1,ix2,iy2,is
  int		naxis1,naxis2
  bool		firststat

  # copy input arguments to force definition at the beginning of the script
  imgname = input

  # default output values
  x = 0
  y = 0
  key = ""

  # constants / defaults
  is = 9
  firststat = yes

  # need to check if file is already post-pre subtracted (otherwise bail out)

  # find size of the image
  imgets (image=imgname, param="i_naxis1")
  naxis1 = int(imgets.value)
  imgets (image=imgname, param="i_naxis2")
  naxis2 = int(imgets.value)

  # allocate unique temporary file name
  tf1 = mktemp("tmp$imarkstar")
  tf2 = mktemp("tmp$imarkstar")

  # read the image cursor until "m" or "q" is returned
  while ( fscan(imcur, x, y, wcs, cmd) != EOF )
    {
    # find the key pressed
    key = substr(cmd, 1, 1)

    # find image range around position
    ix1 = int(x+0.5) - is
    iy1 = int(x+0.5) - is
    if ( ix1 < 1 ) ix1 = 1
    if ( iy1 < 1 ) iy1 = 1
    ix2 = ix1 + 2*is
    iy2 = iy1 + 2*is
    # check against image size
    if ( ix2 > naxis1 ) ix2 = naxis1
    if ( iy2 > naxis2 ) iy2 = naxis2
    range = "["//ix1//":"//ix2//","//iy1//":"//iy2//"]"

    # act according to key pressed
    switch ( key )
      {
      ###
      # plot the column at the selected position
      ###
      case 'c':
        {
        pcol(image=imgname,
             col=int(x+0.5),
             wcs="logical",
             wx1=0.,
             wx2=0.,
             wy1=0.,
             wy2=0.,
             pointmode=no,
             marker="box",
             szmarker=0.005,
             logx=no,
             logy=no,
             xlabel="wcslabel",
             ylabel="",
             title="imtitle",
             xformat="wcsformat",
             vx1=0.,
             vx2=0.,
             vy1=0.,
             vy2=0.,
             majrx=5,
             minrx=5,
             majry=5,
             minry=5,
             round=no,
             fill=yes,
             append=no)
        }
      ###
      # plot the contour around the selected position
      ###
      case 'e':
        {
        contour(image=imgname//range,
                floor=INDEF,
                ceiling=INDEF,
                zero=0.,
                ncontours=0,
                interval=0.,
                nhi=-1,
                dashpat=528,
                device="stdgraph",
                title="imtitle",
                preserve=yes,
                label=yes,
                fill=no,
                xres=64,
                yres=64,
                perimeter=yes,
                vx1=0.,
                vx2=0.,
                vy1=0.,
                vy2=0.,
                subsample=no,
                append=no)
        }
      ###
      # plot the histogram around the selected position
      ###
      case 'h':
        {
        print("h")
        phistogram(input=imgname,
                   z1=INDEF,
                   z2=INDEF,
                   binwidth=INDEF,
                   nbins=512,
                   autoscale=yes,
                   top_closed=no,
                   hist_type="normal",
                   listout=no,
                   title="imtitle",
                   xlabel="Data values",
                   ylabel="Counts",
                   wx1=INDEF,
                   wx2=INDEF,
                   wy1=0.,
                   wy2=INDEF,
                   logx=no,
                   logy=yes,
                   round=no,
                   plot_type="line",
                   box=yes,
                   ticklabels=yes,
                   majrx=5,
                   minrx=5,
                   majry=5,
                   minry=5,
                   fill=yes,
                   vx1=0.,
                   vx2=1.,
                   vy1=0.,
                   vy2=1.,
                   append=no,
                   pattern="solid",
                   device="stdgraph")
        }
      ###
      # plot the line at the selected position
      ###
      case 'l':
        {
        prow(image=imgname,
             row=int(y+0.5),
             wcs="logical",
             wx1=0.,
             wx2=0.,
             wy1=0.,
             wy2=0.,
             pointmode=no,
             marker="box",
             szmarker=0.005,
             logx=no,
             logy=no,
             xlabel="wcslabel",
             ylabel="",
             title="imtitle",
             xformat="wcsformat",
             vx1=0.,
             vx2=0.,
             vy1=0.,
             vy2=0.,
             majrx=5,
             minrx=5,
             majry=5,
             minry=5,
             round=no,
             fill=yes,
             append=no)
        }
      ###
      # a star was marked. Depending on the center parameter either
      # just report the position back ("none"), try to centroid on the
      # position ("centroid") or use xregister to find the shift ("register").
      # The last variant is there to deal with extended objects while
      # centroiding is probably best for stellar images.
      ###
      case 'm':
        {
        if ( verbose ) print("Cursor   : x="//x//" y="//y)
         ## change to use 
	 imcntr(input=imgname,
             x_init = x,
             y_init = y,           
             cboxsize = 9, > tf2) 
	  list = tf2
          nsc = fscan (list, junk, junk, x, junk, y)
          delete(tf2,yes,verify=no, >>& "/dev/null")
	                
          if ( verbose ) print("Centroid : x="//x//" y="//y)
	       

        # break out of loop
        break
        }

      ###
      # quit (ie. return to calling script)
      ###
      case 'q':
        {
        # break out of loop
        break
        }

      ###
      # plot the radial profile at the selected position
      ###
      case 'r':
        {
        pradprof(input = imgname,
                 xinit = x,
                 yinit = y,
                 radius = 11.,
                 center = yes,
                 cboxsize = 5,
                 list = no,
                 graphics = "stdgraph",
                 append = no,
                 title = "imtitle",
                 xlabel = "Radius",
                 ylabel = "Intensity",
                 wx1 = INDEF,
                 wx2 = INDEF,
                 wy1 = INDEF,
                 wy2 = INDEF,
                 round = no,
                 logx = no,
                 logy = no,
                 box = yes,
                 majrx = 5,
                 minrx = 5,
                 majry = 5,
                 minry = 5,
                 ticklabels = yes,
                 fill = yes,
                 vx1 = 0.,
                 vx2 = 1.,
                 vy1 = 0.,
                 vy2 = 1.,
                 pointmode = yes,
                 marker = "plus",
                 szmarker = 1.)
        }

      ###
      # plot the surface around the selected position
      ###
      case 's':
        {
        surface(image = imgname//range,
                floor = INDEF,
                ceiling = INDEF,
                angh = -33.,
                angv = 25.,
                device = "stdgraph",
                title = "imtitle",
                label = no,
                preserve = yes,
                xres = 64,
                yres = 64,
                subsample = no,
                append = no)
        }

      ###
      # plot the vector between the selected positions
      ###
      case 'v':
        {
        ix1 = int(x + 0.5)
        iy1 = int(y + 0.5)
        if ( verbose ) print("please press v again to mark second position")
        while ( fscan(imcur, x, y, wcs, cmd) != EOF )
          {
          # find the key pressed
          key = substr(cmd, 1, 1)
          if ( key == "v" ) break
          }
        ix2 = int(x + 0.5)
        iy2 = int(y + 0.5)

        pvector(image=imgname,
                x1=ix1,
                y1=iy1,
                x2=ix2,
                y2=iy2,
                width=1,
                theta=INDEF,
                length=INDEF,
                boundary="constant",
                constant=0.,
                vec_output="",
                out_type="text",
                wx1=0.,
                wx2=0.,
                wy1=0.,
                wy2=0.,
                pointmode=no,
                marker="box",
                szmarker=0.005,
                logx=no,
                logy=no,
                xlabel="",
                ylabel="",
                title="imtitle",
                vx1=0.,
                vx2=0.,
                vy1=0.,
                vy2=0.,
                majrx=5,
                minrx=5,
                majry=5,
                minry=5,
                round=no,
                fill=yes,
                append=no)
        }
      ###
      # print the image statistics at the selected position
      ###
      case '.':
        {
        imstatistics(images=imgname//range,
                     fields="npix,mean,midpt,stddev,min,max",
                     lower=INDEF,
                     upper=INDEF,
                     binwidth=0.1,
                     format=firststat)
        if ( firststat ) firststat = no
        }
      ###
      # print the help for available cursor commands
      ###
#                           CURSOR KEY COMMAND SUMMARY
#
#? Help              g Graphics cursor   n Next frame        u Vector plot
#a Aperture Sum      h Histogram         o Overplot          v Vector plot
#b Box coords        i Image cursor      p Previous frame    w Toggle logfile
#c Column plot       j Line gaussian fit q Quit              x Coordinates
#d Load display      k Col gaussian fit  r Radial plot       y Set origin
#e Contour plot      l Line plot         s Surface plot      z Print grid
#f Redraw            m Statistics        , Quick phot        . Quick profile fit
      case '?':
        {
        print("                           CURSOR KEY COMMAND SUMMARY")
        print(" ")
        print("? Help             h Histogram         q Quit             v Vector plot")
        print("c Column plot      l Line plot         r Radial plot      . Statistics")
        print("e Contour plot     m Mark position     s Surface plot  ")
        }
      ###
      # default is to do nothing - what a life :-)
      ###
      }
    }

  list = ""

end
