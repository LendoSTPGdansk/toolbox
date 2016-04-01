# toolbox
Various bash scripts

## pull_images.sh

Pull an image from registry to deploy on host

### Usage

```
sh pull_images.sh --image IMAGE-NAME --build BUILD-NUMBER
```

## deploy.sh

Deploy docker containers on QA machine

### Usage

```
sh deploy.sh --image IMAGE-NAME --build BUILD-NUMBER --workdir WORK-DIR
```