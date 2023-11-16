# Nbgrader on Kubernetes

Since there is no official guide on how to deploy nbgrader on Kubernetes, this repository provides a working example.
The deployment is based on the [Zero to Jupyterhub](https://zero-to-jupyterhub.readthedocs.io/en/latest/) helm chart.

## Key features

1. By default, nbgrader is not really meant to be deployed in an environment, where users cannot be uniquely identified by their UNIX user ids (UIDs).
   This is the case for Kubernetes, where each student has their own pod with the same user (jovyan, UID=1000).
   To overcome this limitation, we need to modify the [default nbgrader exchange](https://nbgrader.readthedocs.io/en/stable/user_guide/what_is_nbgrader.html#filesystem-exchange).
   The modified exchange is provided in the `nbgrader_exchange` folder, and also is part of all the docker images.
   See [/nbgrader-exchange/README.md](/nbgrader-exchange/README.md) for more details.

2. Courses are run as managed JupyterHub services.
   This means, that for each course there is a `singleuser` process running in the "hub" pod, which is only accessible by the instructors of the given course.

   > NOTE: Currently all the courses have to be defined in the `values.yaml` file. This can be easily moved to a different location, if needed.

   Each course is bound to a specific port starting from `9000`.
   There is a headless kubernetes service, allowing the proxy to route traffic to any port of the "hub" pod.

3. Students and instructors are distinguished by the groups they belong to.
   In order for the instructor to be able to access a course, he/she has to be a member of the group `formgrade-{course_id}`, where ` course_id` is the name of the course.
   The same is true for the students, but they have to be a member of the `nbgrader-{course_id}` group.
   There are separate images for students and instructors with different nbgrader extensions enabled.
   The image is selected based on the groups of the user.

## Deployment

Since we are using `helm`, the deployment is pretty straightforward.

1. Install helm (see [here](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-helm.html) for more details)
2. Clone this repository

   ```bash
   git clone https://github.com/CERIT-SC/nbgrader-k8s
   cd nbgrader-k8s
   ```

3. Modify the `nbgrader-chart/values.yaml` file to suit your needs

   The main values to change are:

   - `exchange.size` - size of the exchange volume
   - `exchange.storageClassName` - storage class to use for the exchange volume
   - `ingress` - ingress configuration
   - `jupyterhub.extraConfig.00-extra-config.PVC_STORAGE_CLASS` - storage class to use for user home volumes
   - `jupyterhub.hub.db.pvc.storageClassName` - storage class to use for the hub database volume

   All the other JupyterHub related values can be found [here](https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/main/jupyterhub/values.yaml)

4. Download the dependencies

   ```bash
   helm dependency update nbgrader-chart
   ```

5. Deploy the chart

   ```bash
   helm install nbgrader nbgrader-chart -f nbgrader-chart/values.yaml
   ```
