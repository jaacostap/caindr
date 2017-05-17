#!/usr/bin/python
# -*- coding: utf-8 -*-

#######################								###########################################
#######################			DEFINITIONS			###########################################
#######################								###########################################


import sys, os, string
from pyraf import iraf
from numpy import *
from math import *
from pylab import *


def ra(hh,mm,ss):#decimal en grados
	if hh[0] =='-':
		a=-1.
		hh=hh[1:]
	else:
		a=1.
	hh=float(hh)
	mm=float(mm)
	ss=float(ss)
   	y=(((a*hh*60.)/4)+(a*mm/4.)+((a*ss/60.)/4))
   	return y
   	
def dec(hh,mm,ss): #decimal en grados
	if hh[0] =='-':
		a=-1.
		hh=hh[1:]
	else:
		a=1.
	hh=float(hh)
	mm=float(mm)
	ss=float(ss)
   	y=(a*hh+(a*mm/60.)+(a*ss/3600.))
   	return y

def sex(imagen):
                      
#   1 NUMBER                 Running object number                                     
#   2 X_IMAGE                Object position along x                                    [pixel]
#   3 Y_IMAGE                Object position along y                                    [pixel]
#   4 ELONGATION             A_IMAGE/B_IMAGE                                           
#   5 FLUX_AUTO              Flux within a Kron-like elliptical aperture                [count]
#   6 MAG_BEST               Best of MAG_AUTO and MAG_ISOCOR                            [mag]
#   7 FWHM_IMAGE             FWHM assuming a gaussian core                              [pixel]

	dir_config_file='/scratch/jacosta/tcs/pipeline/'
	os.system('sex '+imagen+' -c '+dir_config_file+'config_file2.sex -CHECKIMAGE_TYPE APERTURES -CATALOG_NAME '+imagen[:-5]+'.cat -PARAMETERS_NAME '+dir_config_file+'param2.sex  -FILTER_NAME '+dir_config_file+'gauss_4.0_7x7.conv')



def sex2catb(imagen):
	vv=open(imagen[:-5]+'.cat','r')
	ff=open(imagen[:-5]+'.obj.1','w')
	for linea in vv:
		if linea[0]!='#':
			linea2=linea.split()
			#m=median(FWHM)
			i=float(linea2[6])
			ELO=float(linea2[3])
			x=float(linea2[1])
			y=float(linea2[2])
			if x > 10. and x < 240. and y > 10. and y < 240.:	#CRITERIO POSICION
			#if ELO<=1.3:									#CRITERIO ELONGACION
				ff.write(('%8.5s %8.5s' % (linea2[1],linea2[2]))+'\n')
	ff.close()
	vv.close()

def sex2cat(imagen):
	vv=open(imagen[:-5]+'.cat','r')
	ff=open(imagen[:-5]+'.obj.1','w')
	for linea in vv:
		if linea[0]!='#':
			linea2=linea.split()
			#m=median(FWHM)
			i=float(linea2[6])
			ELO=float(linea2[3])
			x=float(linea2[1])
			y=float(linea2[2])
			if x > 30. and x < 220. and y > 30. and y < 220.:	#CRITERIO POSICION
				if ELO<=1.3:									#CRITERIO ELONGACION
					ff.write(('%8.5s %8.5s' % (linea2[1],linea2[2]))+'\n')
	ff.close()
	vv.close()

def seeing(imagen):
	#CALCULO DEL SEEING
	#RESOL CAIN: 1 pix = 1 arcsec

	f=open(imagen[:-5]+'.cat','r')
	FWHM=[]
	a=0
	for lineas in f:
		if lineas[0] != '#':
			linea=lineas.split()
			FWHM.append(float(linea[6]))
		a=a+1
	f.close()

	m=median(FWHM)
	s=m*1.
	return s,len(FWHM)
	
	
	
	
def filtraje(imagen):
	#Filtra el catalogo de SExtractor para eliminar galaxias, estrellas saturadas, ...
	FWHM=[]
	f=open(imagen[:-5]+'.cat','r')
	a=0
	for lineas in f:
		if lineas[0] != '#':
			linea=lineas.split()
			FWHM.append(float(linea[6]))
		a=a+1
	f.close()


	#CRITERIO DE ELECCION
	from numpy import median,sqrt
	m=median(FWHM)
	w=open(imagen[:-5]+'.lst','w')
	f=open(imagen[:-5]+'.cat','r')
	for linea in f:
		if linea[0] != '#':
			linea2=linea.split()
			i=float(linea2[6])
			ELO=float(linea2[3])
			x=float(linea2[1])
			y=float(linea2[2])
			if x > 40. and x < 210. and y > 40. and y < 210.:	#CRITERIO POSICION
				if i>m-sqrt(m) and i<m+sqrt(m):					#CRITERIO FWHM
					if ELO<=1.2:								#CRITERIO ELONGACION
						w.write(linea)
	f.close()
	w.close()




def file_len(fname):
	#return os.system('wc -l '+fname,stdout=a)
	import subprocess
	proc = subprocess.Popen(['wc -l '+fname], stdout=subprocess.PIPE, shell=True)
	(out, err) = proc.communicate()
	return int(out.split()[0])
	
	
def cata(imagen_sex):
	#######################################################################################
	#	Calculo la estrella con mayor flujo y los desplamientos relativos
	#######################################################################################
	flux_lis=[]
	f=open(imagen_sex[:-5]+'.lst','r')
	for linea in f:
		if linea[0]!='#':
			linea2=linea.split()
			flux=float(linea2[4])
			flux_lis.append(flux)
	f.close()

	#CRITERIO DE FLUJO MAXIMO (CON FLUJO A DISTANCIA MAYOR QUE 100)
	flux_max=max(flux_lis)

	
	flux_lis.remove(max(flux_lis))
	if flux_max>max(flux_lis)+100.:
		print 'Buena estrella detectada'
	
	'''
	flux_lis.remove(max(flux_lis))
	print 'Tercer máximo: ',max(flux_lis)
	print '\n'
	'''

	### AHORA CONSTRUYO OTRO CATÁLOGO CON LOS SHIFT DE 
	#Guardo todos lo datos de la estrella de referencia
	f=open(imagen_sex[:-5]+'.lst','r')
	for linea in f:
		if linea[0]!='#':
			linea2=linea.split()
			flux=float(linea2[4])
			if flux==flux_max:
				refe=linea2				#ESTRELLA DE REFERENCIA
	f.close()


	w=open(imagen_sex[:-5]+'.shft','w') 

	#LOS DATOS EN SHFT SERAN ASI:
	#   1 NUMBER                 Running object number                                     
	#   2 DELTA_X
	#	3 DELTA_Y
	#   4 ELONGATION             A_IMAGE/B_IMAGE                                           
	#   5 FLUX_AUTO              Flux within a Kron-like elliptical aperture                [count]
	#   6 MAG_BEST               Best of MAG_AUTO and MAG_ISOCOR                            [mag]
	#   7 FWHM_IMAGE             FWHM assuming a gaussian core                              [pixel]
	#	8 X_IMAGE                Object position along x                                    [pixel]
	#   9 Y_IMAGE                Object position along y                                    [pixel]
	f=open(imagen_sex[:-5]+'.lst','r')
	for linea in f:
		if linea[0]!='#':
			linea2=linea.split()
			linea2.append(linea2[1])
			linea2.append(linea2[2])
			linea2[1]=str(float(linea2[1])-float(refe[1]))
			linea2[2]=str(float(linea2[2])-float(refe[2]))
			entero=' '.join(linea2)
			print entero
			w.write(entero+'\n')

	f.close()
	w.close()

