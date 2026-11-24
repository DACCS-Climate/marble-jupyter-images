ARG ROOT_CONTAINER=quay.io/jupyter/minimal-notebook:python-3.13.18@sha256:b97cc9adde649c3b7b8209f4aa17996b7ec0df8b5424f22aae50ce1329d900c8

FROM $ROOT_CONTAINER

ENV MAMBA_ROOT_PREFIX="/opt/conda"
# For import xesmf since esmf-8.4.0, see
# https://github.com/conda-forge/esmf-feedstock/issues/91
ENV ESMFMKFILE=/opt/conda/envs/marble/lib/esmf.mk

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update --yes && \
    # - `apt-get upgrade` is run to patch known vulnerabilities in system packages
    #   as the Ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get install --yes --no-install-recommends build-essential gfortran && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo 'export PS1="\[\033[01;32m\]${JUPYTERHUB_USER:-$NB_USER}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] >>> "' >> /etc/bash.bashrc && \
    echo 'cd ${HOME}' >> /etc/bash.bashrc && \
    echo 'conda init' >> /etc/bash.bashrc && \
    rm "/home/$NB_USER/.bashrc" && \
    # New kernels are installed in /usr/local/share/jupyter. Changing permissions of this location to be writable by the user.
    # This opens the possibility that in the jupyter environment a user can create a new environment and install a new kernel.
    mkdir -p /usr/local/share/jupyter && \
    fix-permissions /usr/local/share/jupyter

USER ${NB_UID}
COPY marble_environment.yml /tmp/environment.yml
RUN set -x && \
    # Installing jupyter lab extensions in the base environment and install weaver in the base environment so that it's pinned
    # packages don't conflict with the marble env.
    mamba install --yes jupyterlab-git=0.51.2 \
    jupytext=1.19.7 \
    jupyter-archive=3.5.1 \
    jupyter-server-proxy=4.6.1 \
    dask-labextension=7.0.0 \
    ipywidgets=8.1.9 \
    jupyterlab=4.6.6 \
    jupyter_bokeh=4.1.0 && \
    nodejs=26.13.1 && \
    pip install git+https://github.com/crim-ca/weaver.git && \
    mamba env create -f /tmp/environment.yml && \
    mamba clean --all -f -y && \
    $MAMBA_ROOT_PREFIX/envs/marble/bin/python -m ipykernel install --name Marble
