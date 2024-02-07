ARG ROOT_CONTAINER=quay.io/jupyter/minimal-notebook:python-3.11

FROM $ROOT_CONTAINER

ENV MAMBA_ROOT_PREFIX="/opt/conda"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

COPY marble_environment.yml /environment.yml

USER ${NB_UID}

RUN set -x && \
# Installing jupyter lab extensions in the main environment
    mamba install --yes jupyterlab-git jupyter_conda jupyter-archive jupyter-server-proxy dask-labextension ipywidgets jupyterlab=3.6.7 jupyter_bokeh=3.0.7 && \
# Creating a "Marble" environment
    mamba env create -f /environment.yml && \
    mamba clean --all -f -y

USER root
# Install the marble environment kernel. The installation command has to be run as root as the 
# information about the new kernel is installed in /usr/local/share/jupyter
ENV PATH="$MAMBA_ROOT_PREFIX/envs/marble/bin:$PATH"
RUN python -m ipykernel install --name Marble

# These need to be run as root
RUN fix-permissions "/home/${NB_USER}/.ipython"
RUN fix-permissions "/home/${NB_USER}/.cache"


USER ${NB_UID}

# CMD ["mamba", "run", "-n", "Marble", "/usr/local/bin/start-notebook.sh"]