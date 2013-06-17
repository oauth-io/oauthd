import sys
import getopt
import os
import json

from os.path import basename
from os.path import expanduser
home = expanduser("~")

def conv(filename):
	provider = basename(filename);
	provider, fileExtension = os.path.splitext(provider)
	if fileExtension != ".json":
		print "Error the file must be in json",
		return;
	text = home + "/fs/bin/" + provider + "/v0.1/text.txt";
	if os.path.exists(filename) != True:
		print "For provider " + provider + " no json found"
		return;
	if  os.path.exists(text) != True:
		print "For provider " + provider + " no text.txt found"
		return;
	conf=open(filename, 'r');
	urls=open(text, 'r');
	Conflines = conf.readlines();
	URLlines = urls.readlines();

	nb = 0;
	rmlineFrom = 0;
	rmlineTo = 0;

	allconf = "";	
	for c in Conflines:
		allconf += c;

	confdecode = json.loads(allconf)
	if (confdecode.get("href") != True):
		confdecode.update({"href":{}})

	for url in URLlines:
		word = url.split();
		if len(word) != 0:
			if word[0] == "provider_url":
				confdecode["href"]["provider"] =  word[2].replace('\'', '');		
			elif word[0] == "docs_url":
				confdecode["href"]["docs"] =  word[2].replace('\'', '');		
			elif word[0] == "register_url":
				confdecode["href"]["keys"] =  word[2].replace('\'', '');		
			elif word[0] == "my_apps":
				confdecode["href"]["apps"] =  word[2].replace('\'', '')		

	conf = open(filename, 'w');
	conf.writelines(json.dumps(confdecode, indent=2));

def main():
	if (len(sys.argv) != 2):
		print "Error Usage :\npython addURLinConf.py [conf.json]"
	else:
		filename = sys.argv[1];
		if (os.path.isdir(filename)):
			dirList = os.listdir(filename);
			for d in dirList:
				print d;
				if os.path.isdir(d) != True:
					provider, fileExtension = os.path.splitext(d)
					if fileExtension == ".json":
						conv(filename + d);
		else:
			conv(filename);


if __name__ == "__main__":
	main()