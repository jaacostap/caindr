#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
flat.py
Created by Carlos J. Díaz on 2012-11.
Sustracción del cielo a cada grupo de imagenes
"""

#Importo lo necesario para el desarrollo del programa
from pyraf import iraf
import sys, os, string, numpy

#Y las funciones del iraf
iraf.caindr()

os.system('ls *grupo* > lista_group')
o=open('lista_group','r')

for cadagrupo in o:
	cadagrupo=string.strip(cadagrupo)
	iraf.csubditsky('bf//@'+cadagrupo,prefix='s',combine='median',scalecomb="offset",reject="sigclip",nhigh='0.25',nlow='0.05',maskobj='no',maskpre='',delsky='yes')

o.close()

print '\n'
print ' <<------ Sustracción del cielo terminada ----->> '
print '\n'
