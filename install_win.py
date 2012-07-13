import xml.dom.minidom
import shutil
import os

moduleName = "MultiAccountChat"
moduleDmName = "Relena_" + moduleName + ".dm"
moduleSwfName = moduleName + ".swf"
moduleXmlName = "xml"

srcPath = "."
dstPath = os.environ['PROGRAMFILES(X86)'] + "\\Dofus2BetaModule\\app\\ui\\" + moduleName;

dom = xml.dom.minidom.parse(srcPath + "\\" + moduleDmName)

versionNumbers = dom.getElementsByTagName("version")[0].firstChild.data.split('.')
versionNumbers[1] = str(int(versionNumbers[1]) + 1)

dom.getElementsByTagName("version")[0].firstChild.data = '.'.join(versionNumbers)

with open(srcPath + "\\" + moduleDmName, encoding='utf-8', mode='w') as f:
	dom.writexml(f)



shutil.copyfile(srcPath + "\\" + moduleDmName, dstPath + "\\" + moduleDmName)
shutil.copyfile(srcPath + "\\" + moduleSwfName, dstPath + "\\" + moduleSwfName)
shutil.rmtree(dstPath + "\\" + moduleXmlName, 1)
shutil.copytree(srcPath + "\\" + moduleXmlName, dstPath + "\\" + moduleXmlName)