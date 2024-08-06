#!/bin/bash
set -e


cd  $CW_BUILD_TMPDIR
echo "export env_root=$CW_INSTALLATION_PATH/miniforge/envs/$CW_ENV_NAME/" >> _extra_envs.sh
echo "export env_root=$CW_INSTALLATION_PATH/miniforge/envs/$CW_ENV_NAME/" >> _vars.sh
export env_root=$CW_INSTALLATION_PATH/miniforge/envs/$CW_ENV_NAME/

cd $CW_INSTALLATION_PATH

export CW_CONDA_VERSION=24.3.0-0
export CW_CONDA_ARCH=Linux-x86_64
print_info "Using miniforge version Miniforge3-$CW_CONDA_VERSION-$CW_CONDA_ARCH" 1
print_info "Downloading miniforge " 2
curl -LO https://github.com/conda-forge/miniforge/releases/download/$CW_CONDA_VERSION/Miniforge3-$CW_CONDA_VERSION-$CW_CONDA_ARCH.sh &>/dev/null 
print_info "Installing miniforge " 1 
bash Miniforge3-$CW_CONDA_VERSION-$CW_CONDA_ARCH.sh -b -p $CW_INSTALLATION_PATH/miniforge  > $CW_BUILD_TMPDIR/_inst_miniforge.log &   
inst_pid=$!
follow_log $inst_pid $CW_BUILD_TMPDIR/_inst_miniforge.log 10
rm Miniforge3-$CW_CONDA_VERSION-$CW_CONDA_ARCH.sh
eval "$($CW_INSTALLATION_PATH/miniforge/bin/conda shell.bash hook)"
cd $CW_WORKDIR
source $CW_INSTALLATION_PATH/_pre_install.sh
if [[ ! -z "$(echo "$CW_ENV_FILE" | grep ".*\.yaml\|.*\.yml")" ]];then 
    _EC="env"
    _FF="-f"
else
    _FF="--file"
fi
cd $CW_INSTALLATION_PATH
print_info "Creating env, full log in $CW_BUILD_TMPDIR/build.log" 1

if [[ ${CW_MAMBA} == "yes" ]] ;then
    print_info "Using mamba to install packages" 1 
    conda install -y mamba -n base -c conda-forge
    mamba $_EC create --name $CW_ENV_NAME $_FF $( basename $CW_ENV_FILE ) &>> $CW_BUILD_TMPDIR/build.log &
else
    conda $_EC create --name $CW_ENV_NAME $_FF $( basename $CW_ENV_FILE ) &>> $CW_BUILD_TMPDIR/build.log &
fi

inst_pid=$!
follow_log $inst_pid $CW_BUILD_TMPDIR/build.log 10  
wait $inst_pid
conda activate $CW_ENV_NAME
if [[ ${CW_REQUIREMENTS_FILE+defined}  ]];then
    pip install -r $( basename "$CW_REQUIREMENTS_FILE" )
fi
cd $CW_WORKDIR
print_info "Running user supplied commands" 1
source $CW_INSTALLATION_PATH/_post_install.sh
if [[ -d $CW_INSTALLATION_PATH/miniforge/envs/$CW_ENV_NAME/bin/ ]];then
    echo 'echo "' > $CW_INSTALLATION_PATH/miniforge/envs/$CW_ENV_NAME/bin/list-packages
    conda list >> $CW_INSTALLATION_PATH/miniforge/envs/$CW_ENV_NAME/bin/list-packages 
    echo '"' >> $CW_INSTALLATION_PATH/miniforge/envs/$CW_ENV_NAME/bin/list-packages 
    chmod +x $CW_INSTALLATION_PATH/miniforge/envs/$CW_ENV_NAME/bin/list-packages 
else
    print_warn "Created env is empty"
fi


# Set here as they are dynamic
# Could also set them in construct.py...
echo "CW_WRAPPER_PATHS+=( \"$CW_INSTALLATION_PATH/miniforge/envs/$CW_ENV_NAME/bin/\" )" >>  $CW_BUILD_TMPDIR/_vars.sh
