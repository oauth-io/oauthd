import sys
import getopt
import os

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
	del Conflines[len(Conflines) - 1:]

	nb = 0;
	rmlineFrom = 0;
	rmlineTo = 0;
	for c in Conflines:
		word = c.split();
		if len(word) != 0:
			if word[0] == "\"href\":":
				rmlineFrom = nb;
			elif rmlineTo == 0 and rmlineFrom != 0 and word[0] == '}':
				rmlineTo = nb + 1 ;
				break;
		nb += 1;

	if rmlineTo != 0:
		del Conflines[rmlineFrom:rmlineTo]
	else:
		Conflines[len(Conflines) - 1] = Conflines[len(Conflines) - 1].rstrip('\n') + ',\n'
	URLtoWrite = ["\t\"href\": {\n"];
	for url in URLlines:
		word = url.split();
		if len(word) != 0:
			if word[0] == "provider_url":
				URLtoWrite.append("\t\t\"provider\": \"" + word[2].replace('\'', '') +"\"\n" );
			elif word[0] == "docs_url":
				URLtoWrite.append("\t\t\"docs\": \"" + word[2].replace('\'', '')  +"\"\n");
			elif word[0] == "register_url":
				URLtoWrite.append("\t\t\"keys\": \"" + word[2].replace('\'', '')  +"\"\n");
			elif word[0] == "my_apps":
				URLtoWrite.append("\t\t\"apps\": \"" + word[2].replace('\'', '')  +"\"\n");

	nb = 0;
	for url in URLtoWrite:
		if nb != len(URLtoWrite) -1 and nb != 0:
			URLtoWrite[nb] = URLtoWrite[nb].rstrip('\n') + ',\n'
		nb += 1;

	URLtoWrite.append('\t}\n');
	URLtoWrite.append('}');
	conf = open(filename, 'w');
	conf.writelines(Conflines);
	conf.writelines(URLtoWrite);


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