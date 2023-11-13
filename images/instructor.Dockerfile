FROM jupyter/minimal-notebook:hub-4.0.2
USER root
RUN apt-get update && apt install -y vim procps
RUN pip install https://github.com/CERIT-SC/nbgrader-k8s/releases/download/v0.0.1/nbgrader_k8s_exchange-0.0.1.tar.gz
RUN conda install --quiet --yes nb_conda_kernels nbgrader

RUN jupyter server extension disable nbgrader.server_extensions.formgrader
RUN jupyter labextension disable nbgrader:formgrader
RUN jupyter labextension disable nbgrader:create-assignment

USER ${NB_USER}
