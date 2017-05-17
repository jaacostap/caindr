#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
correccion.py
Created by Carlos J. Díaz on 2012-11.
Correccion de flat y pixeles malos a las imagenes
"""

#Importo lo necesario para el desarrollo del programa
from pyraf import iraf
import sys, os, string

#Y las funciones del iraf
iraf.caindr()

#DIRECTORIO DE LA MASCARA
#dirmasc="/home/carlos/caindr/cmask.pl"
dirmasc="caindr$cmask.pl"

#Para cada filtro corregimos de flat y pixeles malos a las imagenes
os.system("ls lisobj* > lista_tiposo")
o=open("lista_tiposo","r")
for cadalista in o:
	filtro= (cadalista[6:(len(cadalista)-1)])
	print "--------------------------------------------------"
	print "Corrigiendo",filtro,"de flat y pixeles malos"
	print "--------------------------------------------------"
	
	if os.path.exists("Flat"+filtro+".fits"):
		#Correcion de flat   
		iraf.cflatcub(input="@lisobj"+filtro,output="f",flat="Flat"+filtro+".fits")
		#Correcion bad-pixel
		iraf.cbadpix(input="f//@lisobj"+filtro,output="b",immask=dirmasc)
	else:
		print "-----------------------------------------"
		print "No hay flats del filtro",filtro,"!!!!!!!!!"
		print "-----------------------------------------"
		os.system('rm '+cadalista)
o.close()
os.system("ls lisobj* > lista_tiposo")

print '\n'
print ' <<------ Correccion de flat y pixeles malos hecha ----->> '
print '\n'



