#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
slicef.py
Created by Carlos J. Diaz on 2013-12.
Separa las imagenes de un cubo y les anade su offset correspondiente.
"""

#Importo lo necesario para el desarrollo del programa
from pyraf import iraf
import os, string
iraf.images()
iraf.imutil()

#We split each image of cube//Separa las imagenes de un cubo
def imslice(x):
	iraf.imslice(input='sbf//@'+x+'s',output='sbf//@'+x,slice_di='3')
	o=open(x,'r')
	for i in o:
		I=string.strip(i)
		os.system('ls sbf'+I+'*00*.fits >> '+x+'sq')#Creada lista para alinear
		

#We add an offset to each image of cube//Anade el offset a cada imagen del cubo
def addshift(x):
	m=open(x+'sq','r')
	s=open(x+'shifts','r')
	v=open(x+'shiftsq','w')
	listshift=[]
	for shift in s:
		listshift.append(shift)
	a=-1
	for foto in m:
		info=foto.split()
		N=float(info[0][-6])
		if N != 1:
			v.write(listshift[a])
		else:
			a=a+1
			v.write(listshift[a])
	m.close()
	s.close()
	v.close()

##############################################
o=open('lista_group','r')
for cadalista in o:
	cadalista=string.strip(cadalista)
	imslice(cadalista)
	addshift(cadalista)
o.close()

print '\n'
print ' <<------ Separadas las imagenes de un cubo y anadido su offset correspondiente ----->> '
print '\n'

