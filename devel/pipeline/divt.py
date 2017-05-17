#!/usr/bin/python
# -*- coding: utf-8 -*-

'''
divt.py
Created by Carlos J. Díaz on 2012-11.
Combina hselect y separa para todas las listas de objetos por tiempo
'''

#De una lista con $I saca otra con $I,UT,NIMAGES,EXPTIME
def hselect(x):
	from pyraf import iraf
	import sys, os, string	
	f=open(x,"r")
	w=open('h'+x,'w')
	for imagen in f:
		imagen=string.strip(imagen)
		linea=iraf.hselect(imagen, "$I,UT,NIMAGES,EXPTIME", 'yes', Stdout=1)
		w.write(linea[0]+'\n')
	f.close()
	w.close()

#Separa las imagenes en base al tiempo de exp y las guarda en archivos-lista
def separat(x):
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

	#Creo lista de tiempo
	tiempo=[]
	m=open('Lista4','r')

	for foto in m:	
		info=foto.split()
		if len(info)== 5:
			UT=info[2][:-1]
			hh=float(UT[:-6])
			mm=float(UT[-5:-3])
			ss=float(UT[-2:])
		else:
			UT=info[1]
			hh=float(UT[:-6])
			mm=float(UT[-5:-3])
			ss=float(UT[-2:])	
		ts=hh*3600+mm*60+ss
		tiempo.append(ts)
		#print info[0] ,ts,info[3]

	#Dividimos las imagenes por tiempo
	m=open('Lista4','r')
	a=0
	g=1
	w=0
	t=[]
	for foto in m:	
		info=foto.split()
		imagen=info[0]
		if a==0:
			print imagen,'grupo',g
			v=open(x+'grupo'+str(g),'w')
			v.write(imagen+'\n')
			t.insert(0,float(tiempo[0]))
		else:
			deltat=abs(tiempo[a-1]-tiempo[a])
			Textra=(3.6)    #-->><<
			if len(info)== 4:
				n=float(info[2])
				texp=float(info[3])
				TCond=n*(texp+Textra)
			else:
				n=float(info[3])
				texp=float(info[4])
				TCond=n*(texp+Textra)
			if  (TCond-deltat) >= 0 :
				w=w+1
				print imagen,'grupo',g,deltat,TCond
				v.write(imagen+'\n')
				t.insert(w,float(tiempo[a]))
			else:		
				if (t[w]-t[0]) >= 600:
					print 'CUIDADO:el tiempo trasncurrido en la lista del grupo ',g,' es demasiado grande'
				else:
					pass
				g=g+1
				t=[]
				w=0
				print '-------------------------'
				print imagen,'grupo',g,deltat,TCond
				v.close()
				v=open(x+'grupo'+str(g),'w')
				v.write(imagen+'\n')
				t.insert(w,float(tiempo[a]))

		a=a+1
	m.close()
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
	separat('h'+cadalista)
o.close()


