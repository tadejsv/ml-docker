ARG UBUNTU_VERSION=20.04
FROM continuumio/miniconda3 AS conda

COPY env.yml /
COPY .devcontainer/env_dev.yml /
RUN /opt/conda/bin/conda update conda -c conda-forge && \
    /opt/conda/bin/conda env update -f /env.yml -f /env_dev.yml -n base && \
    /opt/conda/bin/conda clean -afy

FROM ubuntu:${UBUNTU_VERSION}

# Prepare shell and file system
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 SHELL=/bin/bash
ENV PATH /opt/conda/bin:$PATH
SHELL ["/bin/bash", "-c"]

# Install all system stuff, including node
COPY sys_requirements.txt /tmp
ARG DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && apt-get install -y --no-install-recommends \
    $(cat tmp/sys_requirements.txt) && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create the sudo user
ARG USERNAME
ARG UID
RUN echo ${USERNAME}
RUN echo ${UID}
RUN useradd $USERNAME -u $UID -G sudo -s /bin/bash -m && \
    echo $USERNAME' ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER $USERNAME
ENV HOME=/home/$USERNAME

# Copy over conda and bashrc, install environment
COPY --from=conda --chown=$USERNAME /opt/ /opt/
RUN sudo ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

# Jupyter config
COPY --chown=$USERNAME jupyter_lab_config.py $HOME/.jupyter/ 

# Prepare entrypoint and mount folder
RUN mkdir $HOME/ws
WORKDIR $HOME/ws