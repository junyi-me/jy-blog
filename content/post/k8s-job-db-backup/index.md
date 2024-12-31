---
date: 2024-12-31
title: Routine database backup with Kubernetes Job
image: images/homelab-sideshot.jpg
tags: [kubernetes, automation, database]
categories: [self-hosting]
---

Kubernetes Job is a very versatile tool that can be used to run any containerized task either once or on a recurring schedule. It can interact with other Kubernetes resources in the cluster just as any other pod can.

As an example, this post will walk through how to set up a Kubernetes Job to back up a PostgreSQL database on a recurring schedule. It involves
1. Creating a Kubernetes Job
2. Connecting to the database service
3. Mounting volumes to the Job
4. Running a container with the `pg_dump` command

## The job manifest

Below is the manifest used to create the Kubernetes Job, along with the `PersistentVolume` and `PersistentVolumeClaim` to store the database backups.

```yaml
# test-db-bck-job.yaml

# persistent volume
apiVersion: v1
kind: PersistentVolume
metadata:
  name: test-bck-nfs-pv
  namespace: test
spec:
  storageClassName: nfs-client
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    path: /db_bck
    server: 10.0.69.110

---

# persistent volume claim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-bck-nfs-pvc
  namespace: test
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi

---

# the job itself
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pgdump-to-nfs-cron
  namespace: test
spec:
  timeZone: 'America/Denver'
  schedule: "0 4 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: pgdump
            image: postgres:17
            env:
            - name: PGUSER
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: username
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
            command: ["/bin/sh", "-c"]
            args:
              - |
                pg_dump -v "postgresql://$PGUSER:$PGPASSWORD@test-db-service.test.svc.cluster.local:80/postgres" > /mnt/nfs/test$(date +%Y%m%d%H%M%S).sql
            volumeMounts:
            - name: nfs-volume
              mountPath: /mnt/nfs
          restartPolicy: Never
          volumes:
          - name: nfs-volume
            persistentVolumeClaim:
              claimName: test-bck-nfs-pvc
```

### `PersistentVolume` and `PersistentVolumeClaim`

The first two blocks in the manifest make the `PersistentVolumeClaim` ready for the Job to use, which is where the database backups are stored.

The the following section of job manifest instructs the job to mount it.
```yaml
            volumeMounts:
            - name: nfs-volume
              mountPath: /mnt/nfs
            command: ["/bin/sh", "-c"]
# ...
          volumes:
          - name: nfs-volume
            persistentVolumeClaim:
              claimName: test-bck-nfs-pvc
```

### Container configuration

The container used in a cron job can be anything, but often times, it has to be configured for a specific task. In this example, I am using the `postgres` image which contains the `pg_dump` command to back up the database, and made the following tweaks.

1. Set timezonoe to `America/Denver` (my local timezone), and the schedule to run the job at 4:00 AM every day.
```yml
  timeZone: 'America/Denver'
  schedule: "0 4 * * *"
```

2. Set the `PGUSER` and `PGPASSWORD` environment variables to the database username and password.
```yml
            env:
            - name: PGUSER
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: username
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
```

3. Define the command to run in the container.
```yml
            command: ["/bin/sh", "-c"]
            args:
              - |
                pg_dump -v "postgresql://$PGUSER:$PGPASSWORD@test-db-service.test.svc.cluster.local:80/postgres" > /mnt/nfs/test$(date +%Y%m%d%H%M%S).sql
```

## Apply the manifest

```bash
kubectl apply -f test-db-bck-job.yaml
```

Check if the job is created successfully:

```bash
kubectl get cronjob --namespace test
```

## Testing the job

Theoretically, the job is now set up, and will run at 4:00 AM every day. We can wait until the next time it runs to find out if it works, but I always like to test my jobs manually first.

```bash
kubectl create job --from=cronjob/pgdump-to-nfs-cron manual-job --namespace test
```

The above command creates a job from the cron job, and runs it **once, immediately**. That means we can check the results right away.

```bash
kubectl logs manual-job --namespace test
```

Take a moment to see if everything looks right, and if so, the job can be left to run on its own.

### Optional: Clean up

```bash
kubectl delete cronjob manual-job --namespace test
```

