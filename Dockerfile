# Pull wolfram engine 12.2 as base and follow Dockerfile based on:
# https://github.com/jupyterhub/repo2docker/tree/2f1914d8d66395e151c82453290f51d8c0894bf4
FROM scratch
COPY --from=wolframresearch/wolframengine:12.2.0 / /

# ---- SETUP ----
USER root
ENV DEBIAN_FRONTEND=noninteractive

# Set up locales properly
RUN apt-get -qq update && \
    apt-get -qq install --yes --no-install-recommends locales wget gnupg2 > /dev/null && \
    apt-get -qq purge && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Use bash as default shell, rather than sh
ENV SHELL /bin/bash

# Set up user
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}
RUN groupadd \
        --gid ${NB_UID} \
        ${NB_USER} && \
    useradd \
        --comment "Default user" \
        --create-home \
        --gid ${NB_UID} \
        --no-log-init \
        --shell /bin/bash \
        --uid ${NB_UID} \
        ${NB_USER}

RUN wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key |  apt-key add - && \
    DISTRO="bionic" && \
    echo "deb https://deb.nodesource.com/node_14.x $DISTRO main" >> /etc/apt/sources.list.d/nodesource.list && \
    echo "deb-src https://deb.nodesource.com/node_14.x $DISTRO main" >> /etc/apt/sources.list.d/nodesource.list

# install some base packages
RUN apt-get -qq update && \
    apt-get -qq install --yes --no-install-recommends \
    less unzip wget curl git libgl1-mesa-glx libfontconfig1 libasound2 g++ && \
    apt-get -qq purge && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8888

# Environment variables required for build
ENV APP_BASE /srv
ENV CONDA_DIR ${APP_BASE}/conda
ENV WOLFRAM_DIR ${APP_BASE}/wolfram
ENV WOLFRAMSCRIPT_ENTITLEMENTID O-WSDS-9826-V6NRZS7WMDZMK
ENV NB_PYTHON_PREFIX ${CONDA_DIR}/envs/notebook
ENV KERNEL_PYTHON_PREFIX ${NB_PYTHON_PREFIX}
RUN mkdir -p ${WOLFRAM_DIR} && \
    chown -R ${NB_USER}:${NB_USER} ${WOLFRAM_DIR}

ENV PATH ${NB_PYTHON_PREFIX}/bin:${CONDA_DIR}/bin:${PATH}

# Copy build scripts
COPY --chown=1000:1000 build-scripts/activate-conda.sh /etc/profile.d/activate-conda.sh
COPY --chown=1000:1000 build-scripts/environment.py-3.8.yml /tmp/environment.yml
COPY --chown=1000:1000 build-scripts/install-miniforge.bash /tmp/install-miniforge.bash

# ---- JUPYTER INSTALLATION: MAMBA ----
RUN TIMEFORMAT='time: %3R' && \
    chmod +x /tmp/install-miniforge.bash && \
    bash -c 'time /tmp/install-miniforge.bash' && \
    rm /tmp/install-miniforge.bash /tmp/environment.yml

ARG REPO_DIR=${HOME}
ENV REPO_DIR ${REPO_DIR}
WORKDIR ${REPO_DIR}
RUN chown ${NB_USER}:${NB_USER} ${REPO_DIR}

ENV PATH ${HOME}/.local/bin:${REPO_DIR}/.local/bin:${PATH}
ENV CONDA_DEFAULT_ENV ${KERNEL_PYTHON_PREFIX}

COPY --chown=1000:1000 ./environment.yml ${REPO_DIR}/environment.yml

USER ${NB_USER}
RUN TIMEFORMAT='time: %3R' \
    bash -c 'time mamba env update -p ${NB_PYTHON_PREFIX} -f "environment.yml" && \
    time mamba clean --all -f -y && \
    mamba list -p ${NB_PYTHON_PREFIX} \
   '

# ---- WOLFRAM ENGINE ----
# add wolframengine jupyter kernel
RUN cd ${WOLFRAM_DIR} && \
    git clone https://github.com/okofish/WolframLanguageForJupyter.git && \
    cd WolframLanguageForJupyter && \
    git checkout 1429f1c86b60ba79794eace378eae4f5941fc9cf -b feature/OnDemandLicensing && \
    ./configure-jupyter.wls add && \
    jupyter kernelspec list

# ---- WRAP UP ----
# Execute postBuild
COPY --chown=1000:1000 ./postBuild ${REPO_DIR}/postBuild
RUN chmod +x postBuild
RUN ./postBuild

# Add entrypoint
COPY --chown=1000:1000 build-scripts/repo2docker-entrypoint /usr/local/bin/repo2docker-entrypoint
RUN chmod +x /usr/local/bin/repo2docker-entrypoint
ENTRYPOINT ["/usr/local/bin/repo2docker-entrypoint"]

# Specify the default command to run
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
