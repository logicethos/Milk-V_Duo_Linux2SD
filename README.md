# Milk-V Duo Linux Image builder

- Menu driven selection
- Writes to SD Card & expands partition
- Create your own custom builds

#### Requirements
- Docker  
- whiptail (usually already installed)


### To Run
```
clone https://github.com/logicethos/Milk-V_Duo_Linux2SD.git
cd Milk-V_Duo_Linux2SD
./run.sh
```

#### Custom builds
Copy one of the existing directorys, and edit the files.

```
ENV - Distro vairables.
bootstrap.sh - This is run within your new envirment during the build.
```