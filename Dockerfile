ARG ROOT_CONTAINER=quay.io/jupyter/minimal-notebook:python-3.11@sha256:c0454dbeca4146113ea9f8c882d88ba03663105dd4b8ff6b153c066e453a2dd8

FROM $ROOT_CONTAINER

ENV MAMBA_ROOT_PREFIX="/opt/conda"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    # - `apt-get upgrade` is run to patch known vulnerabilities in system packages
    #   as the Ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends build-essential gfortran && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}
RUN set -x && \
    # Installing jupyter lab extensions in the base environment
    mamba install --yes jupyterlab-git=0.44.0 \
    mamba_gator=5.2.1 \
    jupytext=1.16.1 \
    jupyter-archive=3.4.0 \
    jupyter-server-proxy=4.1.0 \
    dask-labextension=6.2.0 \
    ipywidgets=8.1.2 \
    jupyterlab=3.6.7 \
    jupyter_bokeh=3.0.7 && \
    mamba clean --all -f -y

# Creating the "Marble" environment:
COPY marble_environment.yml /tmp/environment.yml
RUN set -x && \
    mamba env create -f /tmp/environment.yml && \
    mamba clean --all -f -y

# To get the marble version of pip for weaver installation:
ENV PATH="$MAMBA_ROOT_PREFIX/envs/marble/bin:$PATH"
# Installing weaver into the Marble environment:
RUN set -x && \
    git clone https://github.com/crim-ca/weaver.git && \
    cd weaver && \
    rm -rf .git && \
    make install-pip

# Installing s3fs separately because of issues with weaver dependencies
RUN set -x && \
    mamba install -n marble s3fs=2024.2.0 && \
    mamba clean --all -f -y

USER root
# New kernels are installed in /usr/local/share/jupyter. Changing permissions of this location to be writable by the user.
# This opens the possibility that in the jupyter environment a user can create a new environment and install a new kernel.
RUN mkdir -p /usr/local/share/jupyter
RUN fix-permissions /usr/local/share/jupyter

USER ${NB_UID}
RUN python -m ipykernel install --name Marble

# For import xesmf since esmf-8.4.0, see
# https://github.com/conda-forge/esmf-feedstock/issues/91
ENV ESMFMKFILE=/opt/conda/envs/marble/lib/esmf.mk

USER root
# These need to be run as root
RUN fix-permissions "/home/${NB_USER}/.ipython"
RUN fix-permissions "/home/${NB_USER}/.cache"

RUN echo 'PS1="\[\033[01;32m\]${JUPYTERHUB_USER}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] >>> "' >> /etc/bash.bashrc
RUN echo 'cd ${HOME}' >> /etc/bash.bashrc

USER ${NB_UID}
