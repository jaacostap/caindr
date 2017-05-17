#!/usr/bin/python
# -*- coding: utf-8 -*-

'''
div.py
Created by Carlos J. Díaz on 2012-11.
Combina hselect y separa para todas las listas de objetos por nombre
'''

#De una lista con $I saca otra con $I,UT,NIMAGES,OBJECT
def hselect(x):
	from pyraf import iraf
	import sys, os, string	
	f=open(x,"r")
	w=open('h'+x,'w')
	for imagen in f:
		imagen=string.strip(imagen)
		linea=iraf.hselect(imagen, "$I,UT,NIMAGES,OBJECT", 'yes', Stdout=1)
		w.write(linea[0]+'\n')
	f.close()
	w.close()

#Separa las imagenes en base al nombre (a,b,c,d...) y las guarda en archivos-lista
def separa(x):
	import sys, os, string
	
	print '\n'
	print ' <<------ Busqueda de imagenes erroneas ----->> '
	print '\n'


	#Quitamos las imagenes malas
	h=open('Lista4','w')
	f=open(x,'r')
	e=open('Imgerror.log','a') 
	for foto in f:
		info=foto.split()
		imagen=info[0]
		if len(info)>=4:
			if len(info)==4:
				if info[1]=='"':
					nimagen=1
				else:
					nimagen=float(info[2])	
			elif len(info)==5:
				nimagen=float(info[3])
			else:
				print imagen,"imagen erronea"
				print '-------------------------'
				e.write('%s\n' % (imagen))
			if nimagen > 1:
				h.write(foto)
			else:
				print imagen,"imagen erronea"
				print '-------------------------'
				e.write('%s\n' % (imagen))
		else:
			print imagen,"imagen erronea"
			print '-------------------------'
			e.write('%s\n' % (imagen))
	f.close()
	h.close()


	print '\n'
	print ' <<------ Division de las imagenes en grupos ----->> '
	print '\n'


	#Dividimos las imagenes por nombre
	a=0
	m=open('Lista4','r')
	v=open('X','w')

	for foto in m:	
		info=foto.split()
		imagen=info[0]
		objeto=info[-1]
		if objeto[-1] != 'a':
			print imagen,'grupo',a
			v.write(imagen+'\n')
		else:		
			a=a+1
			print '-------------------------'
			print imagen,'grupo',a
			v.close()
			v=open(x+'grupo'+str(a),'w')
			v.write(imagen+'\n')

	m.close()
	os.system('rm X')
	os.system('rm Lista4')

	print '\n'
	print ' <<------ Division de las imagenes en grupos terminada ----->> '
	print '\n'



#Combina hselect y separa para todas las listas de objetos
import sys, os, string
o=open("lista_tiposo","r")
for cadalista in o:
	cadalista=string.strip(cadalista)
	hselect(cadalista)
	separa('h'+cadalista)
o.close()


