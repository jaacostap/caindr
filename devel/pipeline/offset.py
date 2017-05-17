#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
offset.py
Created by Carlos J. Díaz on 2012-11.
Medicion del offset entre cada una de las imagenes.
"""

#Importo lo necesario para el desarrollo del programa
import sys, os, string
from math import cos

def hselect2(x):
	from pyraf import iraf
	f=open(x,'r')
	w=open('z'+x,'w')
	for imagen in f:
		imagen=string.strip(imagen)
		linea=iraf.hselect(imagen, "$I,RA,DEC,IMAGE", 'yes', Stdout=1)
		w.write(linea[0]+'\n')
	f.close()
	w.close()

def dec(hh,mm,ss): #decimal en grados
   	y=(hh+(mm/60.)+(ss/3600.))
   	return y

def ra(hh,mm,ss):#decimal en grados
   	y=(((hh*60.)/4)+(mm/4.)+((ss/60.)/4))
   	return y

def off(w):
	lisDEC=[]
	lisRA=[]
	a=0
	from sympy import pi
	o=open('z'+w,'r')
	for i in o:
		info=i.split('\t')
		#imagen=info[0]
		RA=string.strip(info[1],'"')
		hhra=float(RA[-8:-6])
		mmra=float(RA[-5:-3])
		ssra=float(RA[-2:])
		DEC=info[2].strip('"\n')
		if DEC[-9:-8]=='-':
			hhdec=-float(DEC[-8:-6])
			mmdec=-float(DEC[-5:-3])
			ssdec=-float(DEC[-2:])
		else:
			hhdec=float(DEC[-8:-6])
			mmdec=float(DEC[-5:-3])
			ssdec=float(DEC[-2:])
		DEC=dec(hhdec,mmdec,ssdec)
		RA=ra(hhra,mmra,ssra)
		lisDEC.append(DEC)
		lisRA.append(RA)
		y=(lisDEC[0]-DEC)*3600
		x=(lisRA[0]-RA)*3600*cos(DEC*float(pi)/180.)
		v=open(w+'shifts','a')
		v.write(('%8.5s %8.5s' % (-x,y))+'\n')
		a=a+1
	o.close()
	v.close()
##############################################

#os.system('rm z*')
#os.system('rm *shift*')

o=open('lista_group',"r")
for cadalista in o:
	cadalista=string.strip(cadalista)
	hselect2(cadalista)
	off(cadalista)
o.close()


print '\n'
print ' <<------ Medicion del offset entre cada una de las imagenes hecha ----->> '
print '\n'

'''
	#CALCULO OFFSET CON PYFITS
	import pyfits
	from function2 import ra,dec

	lisDEC=[]
	lisRA=[]
	from sympy import pi
	from math import *
	for w in lista1.split(','):
		w=string.strip(w)
		
		os.system('rm '+w+'shifts2')
		
		hdulist = pyfits.open(w)
		prihdr = hdulist[0].header
		RA=prihdr['RA'].split(':')
		RA=ra(RA[0],RA[1],RA[2])
		DEC=prihdr['DEC'].split(':')
		DEC=dec(DEC[0],DEC[1],DEC[2])
		hdulist.close()
		
		print RA,DEC
		
		lisDEC.append(DEC)
		lisRA.append(RA)
		y=(lisDEC[0]-DEC)*3600.
		x=(lisRA[0]-RA)*3600.*cos(DEC*float(pi)/180.)
		vv=open(w+'shifts2','a')
		vv.write(('%8.5s %8.5s' % (-x,y))+'\n')
		print -x,y
	vv.close()
	'''

