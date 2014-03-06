import glob
import os
import sys

class idfObject(object):

	def __init__(self, tokens):
		self.objectName = tokens[0]
		self.fields = tokens[1:]
		
	def objectString(self):
		if len(self.fields) == 0:
			s = self.objectName + ";\n"
		else:
			s = self.objectName + ",\n"
			for field in self.fields[:-1]:
				s += "  " + field + ",\n"
			s += "  " + self.fields[-1] + ";\n"
		return s
		
	def printObject(self):
		print self.objectString()
		
	def writeObject(self, fileObject):
		fileObject.write(self.objectString())
		
	def isOutput(self):
		objName = self.objectName.upper()
		if objName in ["OUTPUT:DIAGNOSTICS", "OUTPUT:DEBUGGINGDATA", "OUTPUT:PREPROCESSORMESSAGE", 
					   "METER:CUSTOM", "METER:CUSTOMDECREMENT", 
					   "OUTPUT:VARIABLE", "OUTPUT:METER", "OUTPUT:METER:METERFILEONLY", 
					   "OUTPUT:METER:CUMULATIVE", "OUTPUT:METER:CUMULATIVE:METERFILEONLY",
					   "OUTPUT:ENVIRONMENTALIMPACTFACTORS", "OUTPUT:SQLITE",
					   "OUTPUT:VARIABLEDICTIONARY", "OUTPUTCONTROL:TABLE:STYLE", "OUTPUT:TABLE:SUMMARYREPORTS", "OUTPUT:SURFACES:DRAWING", "OUTPUT:CONSTRUCTIONS",
					   "OUTPUTCONTROL:REPORTINGTOLERANCES", "OUTPUT:SURFACES:LIST", "OUTPUT:TABLE:MONTHLY", "OUTPUT:TABLE:TIMEBINS"]:
			return True
		else:
			return False

def processOneFile(fileName, outFileName, debug = False):
	
	# phase 0: read in lines of file
	lines = []
	with open(fileName, "r") as fo:
		lines = fo.readlines()
	if debug:
		print "*********LINES***********"
		for line in lines:
			print line
	
	# phases 1 and 2: remove comments and blank lines
	lines_a = []
	for line in lines:
		line_text = line.strip()
		this_line = ""
		if len(line_text) > 0:
			exclamation = line_text.find("!")
			if exclamation == -1:
				this_line = line_text
			elif exclamation == 0:
				this_line = ""
			elif exclamation > 0:
				this_line = line_text[:exclamation]
			if not this_line == "":
				lines_a.append(this_line)
	if debug:
		print "**********LINES B*************"
		for line in lines_a:
			print line
	
	# intermediates: join entire array and re-split by semicolon
	idfDataJoined = ''.join(lines_a)
	idfObjectStrings = idfDataJoined.split(";")
	if debug:
		print "**********IDF OBJECT LINES********"
		for line in idfObjectStrings:
			print line
	
	# phase 3: inspect each object and its fields
	objectDetails = []
	idfObjects = []
	for object in idfObjectStrings:
		tokens = object.split(",")
		niceObject = [ t.strip() for t in tokens ]
		if len(niceObject) == 1:
			if niceObject[0] == "":
				continue
		objectDetails.append(niceObject)
		idfObjects.append(idfObject(niceObject))
	if debug:
		print "**********NICE IDF OBJECT LINES********"
		for line in objectDetails:
			print line
		print "**********IDF OBJECTS*************"
		for line in idfObjects:
			line.printObject()
	downSelectedIdfObjects = []
	for obj in idfObjects:
		if not obj.isOutput():
			downSelectedIdfObjects.append(obj)
	if debug:
		print "********NON OUTPUT IDF OBJECTS*******"
		for obj in downSelectedIdfObjects:
			obj.printObject()
	
	# now we have a set of all the idf objects that aren't output, we just need to add in the ones we want
	heatingNotMetAnnual = idfObject(["Output:Variable", "*", "Facility Heating Setpoint Not Met While Occupied Time", "Annual"])
	coolingNotMetAnnual = idfObject(["Output:Variable", "*", "Facility Cooling Setpoint Not Met While Occupied Time", "Annual"])
	elecFacilityAnnual  = idfObject(["Output:Meter", "Electricity:Facility", "Annual"])
	gasFacilityAnnual   = idfObject(["Output:Meter", "Gas:Facility", "Annual"])
	downSelectedIdfObjects.extend([heatingNotMetAnnual, coolingNotMetAnnual, elecFacilityAnnual, gasFacilityAnnual])
	if debug:
		print "********FINAL IDF OBJECTS*******"
		for obj in downSelectedIdfObjects:
			obj.printObject()
	
	# open the output file and write to it
	with open(outFileName, "w") as fileOut:
		for obj in downSelectedIdfObjects:
			obj.writeObject(fileOut)

#*****************************************************************
# now the actual program		
for inFile in glob.iglob('v8.1\originals\*.idf'):
	file = os.path.basename(inFile)
	outFile = 'v8.1\scrubbedOutput\\' + file
	print inFile + " ---> " + outFile
	processOneFile(inFile, outFile)
