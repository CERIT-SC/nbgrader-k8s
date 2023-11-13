
FROM jupyter/minimal-notebook:hub-4.0.2
USER root
RUN apt-get update && apt install -y vim procps

RUN mkdir -p /mnt/exchange
RUN chown -R ${NB_USER} /mnt/exchange
RUN chmod -R 755 /mnt/exchange

RUN pip install https://github.com/CERIT-SC/nbgrader-k8s/releases/download/v0.0.1/nbgrader_k8s_exchange-0.0.1.tar.gz
RUN conda install --quiet --yes nb_conda_kernels nbgrader

RUN jupyter server extension disable nbgrader.server_extensions.formgrader
RUN jupyter server extension disable nbgrader.server_extensions.course_list
RUN jupyter labextension disable nbgrader:formgrader
RUN jupyter labextension disable nbgrader:course-list
RUN jupyter labextension disable nbgrader:create-assignment

USER ${NB_USER}
