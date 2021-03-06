#!/bin/bash
# upgrade a base ubuntu to have the following:
#1. Ubuntu server with appropriate security and ssh access
#2. Ubuntu packages supporting:
#    a. Developers (e.g., gcc)
#    b. R and various R packages
#    c. HPC (e.g., hdf5, openmpi)
#3. Intel's MKL
#4. Base R
#5. TOPMed Specific Support
#    a. NFS volume for projects, home base directory for users (not for ubuntu user)
#    b. TOPMed analysis packages (via bioconductor)
#    c. Miscellaneous R packages (e.g., rmarkdown)
#    d. UW analysis_pipeline
#6. User accounts in topmed group and having home directories on NFS
#7. Optional RStudio server
#8. Optional Shiny server
#
# arg1: R version
# arg2: analysis pipeline branch
# arg2: NFS address /projects
# arg3: NFS address /topmed_home
# arg4: NFS address /admin
f () {
    errcode=$? # save the exit code as the first thing done in the trap function
    echo "error $errorcode"
    echo "the command executing at the time of the error was"
    echo "$BASH_COMMAND"
    echo "on line ${BASH_LINENO[0]}"
    # do some error handling, cleanup, logging, notification
    # $BASH_COMMAND contains the command that was being executed at the time of the trap
    # ${BASH_LINENO[0]} contains the line number in the script of that command
    # exit the script or return to try again, etc.
    exit $errcode  # or use some other value or do return instead
}
trap f ERR
R_VERSION=${1:-3.5.1}
AP_BRANCH=${2:-master}
PROJ_IP=${3:-172.255.33.0:/export_ebs/projects}
HOME_IP=${4:-172.255.33.0:/export_ebs/topmed_home}
ADMIN_IP=${5:-172.255.33.0:/export_ebs/topmed_admin}
RS_VERSION=1.1.447
echo ">>> Upgrading Ubuntu to R $R_VERSION"
echo ">>>   Analysis Pipeline: $AP_BRANCH"
echo ">>>   Project NFS address: $PROJ_IP"
echo ">>>   Home NFS address: $HOME_IP"
echo ">>>   Admin NFS address: $ADMIN_IP"
# update basic ubuntu
echo ">>> Update Ubuntu packages ..."
./update_ubuntu.bash > update_ubuntu.log 2>&1

echo ">>> Update Ubuntu with hpc packages ..."
./install_ubuntu_hpc.bash > update_ubuntu_hpc.log 2>&1

echo ">>> Installing R $R_VERSION ..."
./install_R.bash $R_VERSION > install_r.log 2>&1

# install TOPMed R packages
echo ">>> Installing TOPMed R packages ..."
./install_topmed_ubuntu.bash $R_VERSION $AP_BRANCH > install_topmed.log 2>&1
# manually, mount the NFS volumes
echo ">>> Mounting NFS volumes ..."
#if [ ! -d /projects ]; then
#    sudo mkdir /projects
#fi
if [ ! -d /topmed_home ]; then
    sudo mkdir /topmed_home
fi
if [ ! -d /admin ]; then
    sudo mkdir /admin
fi
if ! sudo mount | grep $PROJ_IP > /dev/null; then
    sudo mount -t nfs4 -o vers=4.1 $PROJ_IP /projects
else
    echo "$PROJ_IP already mounted"
fi
if ! sudo mount | grep $HOME_IP > /dev/null; then
    sudo mount -t nfs4 -o vers=4.1 $HOME_IP /topmed_home
else
    echo "$HOME_IP already mounted"
fi
if ! sudo mount | grep $ADMIN_IP > /dev/null; then
    sudo mount -t nfs4 -o vers=4.1 $ADMIN_IP /admin
else

    echo "$ADMIN_IP already mounted"
fi

echo ">>> Adding topmed group ..."
# create the topmed group
mgroup=topmed
if ! compgen -g | grep $mgroup > /dev/null; then
    sudo addgroup -gid 1002 $mgroup
    # update ubuntu account (current login)
    sudo usermod -a -G $mgroup ubuntu
    sudo usermod -g $mgroup ubuntu
fi

# create user account
echo ">>> Creating UW user accounts  ..."
uaccnt=levined
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --home /topmed_home/$uaccnt --uid 1002 --ingroup $mgroup --disabled-password --gecos GECOS $uaccnt
    sudo adduser $uaccnt sudo
fi

uaccnt=kuraisa
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --home /topmed_home/$uaccnt --uid 1001 --ingroup $mgroup --disabled-password --gecos GECOS $uaccnt
    sudo adduser $uaccnt sudo
fi

uaccnt=sdmorris
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --home /topmed_home/$uaccnt --uid 1003 --ingroup $mgroup --disabled-password --gecos GECOS $uaccnt
    sudo adduser $uaccnt sudo
fi

uaccnt=mchughc
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --home /topmed_home/$uaccnt --uid 1010 --ingroup $mgroup --disabled-password --gecos GECOS $uaccnt
    sudo adduser $uaccnt sudo
fi

uaccnt=mconomos
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --home /topmed_home/$uaccnt --uid 1011 --ingroup $mgroup --disabled-password --gecos GECOS $uaccnt
    sudo adduser $uaccnt sudo
fi

uaccnt=amarise
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --home /topmed_home/$uaccnt --uid 1012 --ingroup $mgroup --disabled-password --gecos GECOS $uaccnt
    sudo adduser $uaccnt sudo
fi

uaccnt=avmikh
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --home /topmed_home/$uaccnt --uid 1013 --ingroup $mgroup --disabled-password --gecos GECOS $uaccnt
    sudo adduser $uaccnt sudo
fi

uaccnt=calaurie
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --home /topmed_home/$uaccnt --uid 1014 --ingroup $mgroup --disabled-password --gecos GECOS $uaccnt
    sudo adduser $uaccnt sudo
fi

uaccnt=analyst
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --home /topmed_home/$uaccnt --uid 1099 --ingroup $mgroup --disabled-password --gecos GECOS $uaccnt
    sudo adduser $uaccnt sudo
fi


# install RStudio server
echo ">>> Install RStudio server  ..."
# install RStudio
if [ ! -d /usr/local/src/rstudio ]; then
    sudo apt-get update
    sudo apt-get install -y gdebi-core net-tools
    mkdir /usr/local/src/rstudio
    cd /usr/local/src/rstudio
    wget https://download2.rstudio.org/rstudio-server-$RS_VERSION-amd64.deb
    sudo gdebi -n rstudio-server-$RS_VERSION-amd64.deb
else
    echo "RStudio Server already built"
fi
# add uw users to rstudio group
echo ">>> Adding rstudio-server group to UW accounts ..."
sudo usermod -a -G rstudio-server levined
sudo usermod -a -G rstudio-server kuraisa
sudo usermod -a -G rstudio-server sdmorris
# rstudio users
echo ">>> Creating RStudio accounts"
uaccnt=rstudio1
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --ingroup rstudio-server --disabled-password --gecos GECOS $uaccnt
    PWD=$uaccnt"server"
    echo "$uaccnt:$PWD" | sudo chpasswd
fi
uaccnt=rstudio2
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --ingroup rstudio-server --disabled-password --gecos GECOS $uaccnt
    PWD=$uaccnt"server"
    echo "$uaccnt:$PWD" | sudo chpasswd
fi
uaccnt=rstudio3
if ! compgen -u | grep $uaccnt > /dev/null; then
    sudo adduser --ingroup rstudio-server --disabled-password --gecos GECOS $uaccnt
    PWD=$uaccnt"server"
    echo "$uaccnt:$PWD" | sudo chpasswd
fi

echo "Modifying /etc/rc.local to mount nfs volumes ..."
# update /etc/rc.local to mount NFS volumes
echo '#!/bin/sh -e' > rc.local
echo '#' >> rc.local
echo '# rc.local' >> rc.local
echo '# ' >> rc.local
echo '# mount nfs topmed volumes' >> rc.local
#echo mount -t nfs4 -o vers=4.1 $PROJ_IP /projects >> rc.local
echo mount -t nfs4 -o vers=4.1 $HOME_IP /topmed_home >> rc.local
echo mount -t nfs4 -o vers=4.1 $ADMIN_IP /admin >> rc.local
echo exit 0 >> rc.local
sudo cp rc.local /etc/rc.local
