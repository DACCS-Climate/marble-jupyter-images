ARG ROOT_CONTAINER=quay.io/jupyter/minimal-notebook:python-3.11

FROM $ROOT_CONTAINER

ENV MAMBA_ROOT_PREFIX="/opt/conda"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

COPY marble_environment.yml /environment.yml

# Installing jupyter lab extensions in the main environment
RUN mamba install --yes jupyterlab-git jupyter_conda jupyter-archive jupyter-server-proxy dask-labextension
# Creating a "Marble" environment
RUN mamba env create -f /environment.yml

ENV PATH="/opt/conda/envs/marble/bin:$PATH"

RUN python -m ipykernel install --name Marble

USER ${NB_UID}

# CMD ["mamba", "run", "-n", "Marble", "/usr/local/bin/start-notebook.sh"]