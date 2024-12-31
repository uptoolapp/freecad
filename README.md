# Backport of FreeCAD to Ubuntu 24.04 LTS

 1. Download the .deb package from releases.

 2. Install it:
 
        apt-get update
        apt-get install -y ./freecad-uptool.deb
    
 3. Set paths:
 
        PATH=$PATH:/opt/freecad/bin
        PYTHONPATH=/opt/freecad/lib

 4. Use:

        FreeCADCmd --version
    
    or

        python3 -c "import FreeCAD; print(FreeCAD.newDocument())"
