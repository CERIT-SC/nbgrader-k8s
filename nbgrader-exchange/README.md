# Nbgrader K8s Exchange

This is a modified version of the [default nbgrader exchange](https://nbgrader.readthedocs.io/en/stable/user_guide/what_is_nbgrader.html#filesystem-exchange) which works in a JupyterHub + Kubernetes environment.

## Key idea

The default exchange relies on the assumption, that the users are uniquely identifiable by their UNIX user ids (UIDs).
However, this assumption does not hold when running nbgrader on Kubernetes, where each student has their own pod with the same user (jovyan, UID=1000).
To address this issue, we reorganized the directory structure of the exchange to easily mount only the files of the respective student into their pod.
Therefore, the students have no access to the files of other students. The shared files that need to be accessible by all students simultaneously, should be mounted as "read-only" volumes.

## Directory structure

The directory structure of the default exchange is the following:

```
exchange
├── course101
│   ├── feedback
│   │   ├── 662a2398141ddb53.html
│   │   └── be4a67ab2876f854.html
│   ├── inbound
│   │   ├── studend1+assignment1+timestamp+random_string.ipynb
│   │   └── studend2+assignment1+timestamp+random_string.ipynb
│   └── outbound
│       ├── assignment1
│       │   └── assignment1.ipynb
│       └── assignment2
│           └── assignment2.ipynb
└── course102
    ├── feedback
    ├── inbound
    └── outbound
```

Directory structure of the modified exchange:

```
exchange
├── course101
│   ├── feedback
│   ├── feedback_public
│   │   ├── student1
│   │   │   └── 662a2398141ddb53.html
│   │   └── student2
│   │       └── be4a67ab2876f854.html
│   ├── inbound
│   │   ├── student1
│   │   │   └── assignment1+timestamp+random_string.ipynb
│   │   └── student2
│   │       └── assignment1+timestamp+random_string.ipynb
│   └── outbound
│       ├── assignment1
│       │   └── assignment1.ipynb
│       └── assignment2
│           └── assignment2.ipynb
└── course102
    ├── feedback
    ├── feedback_public
    ├── inbound
    └── outbound
```

The advantage of this structure is, that the directories can be mounted into the pods by the names of the students.

## Usage

1. Install the exchange plugin to the "hub" and "singleuser" images:

```bash
pip install https://github.com/CERIT-SC/nbgrader-k8s/releases/download/v0.0.1/nbgrader_k8s_exchange-0.0.1.tar.gz
```

or use the provided [docker images](../images/)

2. Configure the exchange in the `nbgrader_config.py` file:

```python
c.ExchangeFactory.collect = 'nbgrader_k8s_exchange.plugin.ExchangeCollect'
c.ExchangeFactory.exchange = 'nbgrader_k8s_exchange.plugin.Exchange'
c.ExchangeFactory.fetch_assignment = 'nbgrader_k8s_exchange.plugin.ExchangeFetchAssignment'
c.ExchangeFactory.fetch_feedback = 'nbgrader_k8s_exchange.plugin.ExchangeFetchFeedback'
c.ExchangeFactory.list = 'nbgrader_k8s_exchange.plugin.ExchangeList'
c.ExchangeFactory.release_assignment = 'nbgrader_k8s_exchange.plugin.ExchangeReleaseAssignment'
c.ExchangeFactory.release_feedback = 'nbgrader_k8s_exchange.plugin.ExchangeReleaseFeedback'
c.ExchangeFactory.submit = 'nbgrader_k8s_exchange.plugin.ExchangeSubmit'
```

3. Mount the exchange into the pods:

```python
async def bootstrap_pre_spawn(spawner):
    # ...
    # ...
    spawner.volumes.extend([
        {
            "name": "nbgrader-exchange",
            "persistentVolumeClaim": {
                "claimName": f"nbgrader-exchange"
            }
        }
    ])

    spawner.volume_mounts.extend([
        {
            "name": "nbgrader-exchange",
            "mountPath": f"/mnt/exchange/{courseName}/inbound/{username}",
            "subPath": f"{courseName}/inbound/{username}",
        },
        {
            "name": "nbgrader-exchange",
            "mountPath": f"/mnt/exchange/{courseName}/feedback_public/{username}",
            "subPath": f"{courseName}/feedback_public/{username}",
        },
        {
            "name": "nbgrader-exchange",
            "mountPath": f"/mnt/exchange/{courseName}/outbound",
            "subPath": f"{courseName}/outbound",
            "readOnly": True
        }
    ])
    # ...
    # ...
```
