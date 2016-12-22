# OPENSTACK CEILOMETER ALARMS - A PRACTICAL EXAMPLE

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## What we want to acomplish here ?:

Show the way alarm's are created and used in OpenStack Ceilometer.


## Where are we going to do it ?:

OpenStack MITAKA Cloud with ceilometer/aodh properlly installed and configured.
Running S/O Cirros instance. ID: 0169b375-335f-473c-9d32-9d46b087994d


## How are we going to do it ??:

First things first: Let's load our keystone credentials, or we are going no where here:

source /root/keystonerc_fulladmin

**NOTE: Remember OpenStack need's your Keystone credentials for any task you want to perform in the cloud.**

We want to create an alarm for a specific server, so, we need the server UUID:

```
openstack server list
+--------------------------------------+-----------+--------+-----------------------------------------+
| ID                                   | Name      | Status | Networks                                |
+--------------------------------------+-----------+--------+-----------------------------------------+
| 0169b375-335f-473c-9d32-9d46b087994d | cirros-01 | ACTIVE | internal-01=192.168.34.4, 192.168.100.4 |
+--------------------------------------+-----------+--------+-----------------------------------------+
```

Our "target" server (cirros-01) UUID is: 0169b375-335f-473c-9d32-9d46b087994d.

We want to include a "CPU-Percent max usage" alarm for our server. This requires the ceilometer metric "cpu_util". We need to ensure that metric is available for the instance:

```
ceilometer meter-list --query resource=0169b375-335f-473c-9d32-9d46b087994d|grep cpu_util

| cpu_util | gauge | % | 0169b375-335f-473c-9d32-9d46b087994d | 09932ce4d85f4c8c8475af22b0ac860e | 69354f037e484e27872d86e1fc8ea5e9 |
```

So yes, the metric is there. Let's continue.


Also, we can obtain the metric recorded value with the command:

```
ceilometer statistics --meter cpu_util --query resource=0169b375-335f-473c-9d32-9d46b087994d
```

Knowing the instance ID (uuid), and the cpu metrics are active, we proceed to create an alarm.

This alarm will use the metric "cpu_util", and will enter on "alarmed" state when the metric goes beyond 50% (our threshold) by one measurement period. The "default" measurement period is 600 seconds (file: `/etc/ceilometer/pipeline.yaml`.) - this is 10 minutes:

```
ceilometer alarm-threshold-create \
--name cpu_high \
--description "CPU usage high" \
--meter-name cpu_util \
--threshold 50 \
--comparison-operator gt \
--statistic avg --period 600 \
--evaluation-periods 1 \
--alarm-action 'log://' \
--query resource_id=0169b375-335f-473c-9d32-9d46b087994d

+---------------------------+-----------------------------------------------------+
| Property                  | Value                                               |
+---------------------------+-----------------------------------------------------+
| alarm_actions             | ["log://"]                                          |
| alarm_id                  | 84440a6e-d3d6-44a5-9558-2ecf19ddc2c9                |
| comparison_operator       | gt                                                  |
| description               | CPU usage high                                      |
| enabled                   | True                                                |
| evaluation_periods        | 1                                                   |
| exclude_outliers          | False                                               |
| insufficient_data_actions | []                                                  |
| meter_name                | cpu_util                                            |
| name                      | cpu_high                                            |
| ok_actions                | []                                                  |
| period                    | 600                                                 |
| project_id                | 69354f037e484e27872d86e1fc8ea5e9                    |
| query                     | resource_id == 0169b375-335f-473c-9d32-9d46b087994d |
| repeat_actions            | False                                               |
| severity                  | low                                                 |
| state                     | insufficient data                                   |
| statistic                 | avg                                                 |
| threshold                 | 50.0                                                |
| type                      | threshold                                           |
| user_id                   | 09932ce4d85f4c8c8475af22b0ac860e                    |
+---------------------------+-----------------------------------------------------+
```

Once our alarm is created, we proceed to "force" a more-than-50% CPU utilization on the cirros instance by running the following command in the instance O/S shell:

```
while [ 1 ] ; do echo $((13**99)) 1>/dev/null 2>&1; done &
```

Initially, we can see that our alarm is in "ok" state, as the meausurement period is not reached yet:

```
ceilometer alarm-list

+--------------------------------------+----------+-------+----------+---------+------------+--------------------------------------+------------------+
| Alarm ID                             | Name     | State | Severity | Enabled | Continuous | Alarm condition                      | Time constraints |
+--------------------------------------+----------+-------+----------+---------+------------+--------------------------------------+------------------+
| 84440a6e-d3d6-44a5-9558-2ecf19ddc2c9 | cpu_high | ok    | low      | True    | False      | avg(cpu_util) > 50.0 during 1 x 600s | None             |
+--------------------------------------+----------+-------+----------+---------+------------+--------------------------------------+------------------+
```

After 10 minutes (600 seconds), we can se the alarm state changed to "alarm":

```
ceilometer alarm-list

+--------------------------------------+----------+-------+----------+---------+------------+--------------------------------------+------------------+
| Alarm ID                             | Name     | State | Severity | Enabled | Continuous | Alarm condition                      | Time constraints |
+--------------------------------------+----------+-------+----------+---------+------------+--------------------------------------+------------------+
| 84440a6e-d3d6-44a5-9558-2ecf19ddc2c9 | cpu_high | alarm | low      | True    | False      | avg(cpu_util) > 50.0 during 1 x 600s | None             |
+--------------------------------------+----------+-------+----------+---------+------------+--------------------------------------+------------------+
```

and

```
ceilometer statistics --meter cpu_util --query resource=0169b375-335f-473c-9d32-9d46b087994d

+--------+----------------------------+----------------------------+---------------+---------------+---------------+---------------+-------+----------+----------------------------+----------------------------+
| Period | Period Start               | Period End                 | Max           | Min           | Avg           | Sum           | Count | Duration | Duration Start             | Duration End               |
+--------+----------------------------+----------------------------+---------------+---------------+---------------+---------------+-------+----------+----------------------------+----------------------------+
| 0      | 2016-05-26T16:30:21.363000 | 2016-05-27T16:16:45.767000 | 90.3621146879 | 5.62770481563 | 52.5658767796 | 841.054028473 | 16    | 4797.072 | 2016-05-27T14:56:48.695000 | 2016-05-27T16:16:45.767000 |
+--------+----------------------------+----------------------------+---------------+---------------+---------------+---------------+-------+----------+----------------------------+----------------------------+
```

We enter again to the cirros instance, and kill the proccess consuming the cpu. Then after 10 minutes, our alarm goes to normal (state:ok) again:

```
ceilometer statistics --meter cpu_util --query resource=0169b375-335f-473c-9d32-9d46b087994d -a avg
+--------+----------------------------+----------------------------+---------------+----------+----------------------------+----------------------------+
| Period | Period Start               | Period End                 | Avg           | Duration | Duration Start             | Duration End               |
+--------+----------------------------+----------------------------+---------------+----------+----------------------------+----------------------------+
| 0      | 2016-05-26T17:00:21.485000 | 2016-05-27T16:46:45.757000 | 48.4355795118 | 6597.062 | 2016-05-27T14:56:48.695000 | 2016-05-27T16:46:45.757000 |
+--------+----------------------------+----------------------------+---------------+----------+----------------------------+----------------------------+

ceilometer alarm-list
+--------------------------------------+----------+-------+----------+---------+------------+--------------------------------------+------------------+
| Alarm ID                             | Name     | State | Severity | Enabled | Continuous | Alarm condition                      | Time constraints |
+--------------------------------------+----------+-------+----------+---------+------------+--------------------------------------+------------------+
| 84440a6e-d3d6-44a5-9558-2ecf19ddc2c9 | cpu_high | ok    | low      | True    | False      | avg(cpu_util) > 50.0 during 1 x 600s | None             |
+--------------------------------------+----------+-------+----------+---------+------------+--------------------------------------+------------------+
```

You can use the "ceilometer alarm-list" command with specific queries. Samples:

The following example show's all alarms in "alarm" state:

```
ceilometer alarm-list -q "state=alarm"

+----------+------+-------+---------+------------+-----------------+------------------+
| Alarm ID | Name | State | Enabled | Continuous | Alarm condition | Time constraints |
+----------+------+-------+---------+------------+-----------------+------------------+
+----------+------+-------+---------+------------+-----------------+------------------+
```

This example shows all alarms in "alarm" state only for the project with ID: 3e611e2108db4a638b4845b7715e25ca.

```
ceilometer alarm-list -q "state=alarm;project=3e611e2108db4a638b4845b7715e25ca"

+----------+------+-------+---------+------------+-----------------+------------------+
| Alarm ID | Name | State | Enabled | Continuous | Alarm condition | Time constraints |
+----------+------+-------+---------+------------+-----------------+------------------+
+----------+------+-------+---------+------------+-----------------+------------------+
```

This example shows all alarms in "ok" state for the metric "vcpus" and the project with ID: 3e611e2108db4a638b4845b7715e25ca.

```
ceilometer alarm-list -q "state=ok;project=3e611e2108db4a638b4845b7715e25ca;meter=vcpus"

+----------+------+-------+---------+------------+-----------------+------------------+
| Alarm ID | Name | State | Enabled | Continuous | Alarm condition | Time constraints |
+----------+------+-------+---------+------------+-----------------+------------------+
+----------+------+-------+---------+------------+-----------------+------------------+
```


## Tips for advanced usage: Use of instance metadata

The previouslly created alarm on the section above was constructed for an specific instance by adjusting the "query" to the resource_id of the instance. The same query can be applied to any kind of key supported by ceilometer, by example: project=UUID-OF-THE PROJECT.

But, what if you want to use the instance metadata, or group a set of resources by a common metadata key=value combination ?. We can achieve this task by adjusting the query to use the resource_metadata item.

For this to work, we need first to include a "Metadata item" on the instance, either at creation time, or later on run time. The metadata item name need to include at the beginning "metering.". Sample: metering.environment=production.

For reasons we'll explain later, the "--meta key=value" should be better set up on the instance boot command (nova boot). If our instance is already running, we still can include the metadata item with the command "nova meta SERVER-ID set key=value". Example:

```
nova meta c3cae294-e71e-4642-a2a8-fb8b057202de set metering.environment=cloudtesting
```

In any case, let's assume we created a server or group of servers with a common metadata key named "metering.environment" set to the value "production".

```
--meta metering.environment=production
```

You can do a normal ceilometer query by using this metadata, but changing "metering.environment=cloudtesting by "metadata.user_metadata.environment=cloudtesting":

```
ceilometer statistics --meter cpu_util -q "metadata.user_metadata.environment=cloudtesting" -a avg

+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| 0      | 2016-06-06T17:13:56 | 2016-06-06T17:13:56 | 24.0611480865 | 0.0      | 2016-06-06T17:13:56 | 2016-06-06T17:13:56 |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
```

**NOTE SOMETHING HERE AND IT'S VERY IMPORTANT FOR YOU TO UNDERSTAND:** Only after you set on the instance the "metering.KEY=VALUE" metadata item, the samples will contain the metadata string and will be obtainable by using the query in the form "metadata.user_metadata.KEY=VALUE". The metadata "data" is included in the message wich contains the sample-data stored by ceilometer, but only from the moment the key=value is included on the instance. That means IT IS very important to plan ahead if you want to include metadata key=value's in your instances !. Previous samples for the instance WILL NOT HAVE the "metering.KEY=VALUE" string !.

Now, we can create the alarm that will be trigered for any server wich includes the "metering.environment=cloudtesting" metadata. The command:

```
ceilometer alarm-threshold-create \
--name cpu_high_enviro_prod \
--description "CPU usage above 5 percent on Production Environment" \
--meter-name cpu_util \
--threshold 5 \
--comparison-operator gt \
--statistic avg --period 600 \
--evaluation-periods 1 \
--alarm-action 'log://' \
--query 'metadata.user_metadata.environment=cloudtesting'

+---------------------------+-----------------------------------------------------+
| Property                  | Value                                               |
+---------------------------+-----------------------------------------------------+
| alarm_actions             | [u'log://']                                         |
| alarm_id                  | 2366d12b-5d4e-41a8-8d76-37b21eac7a36                |
| comparison_operator       | gt                                                  |
| description               | CPU usage above 5 percent on Production Environment |
| enabled                   | True                                                |
| evaluation_periods        | 1                                                   |
| exclude_outliers          | False                                               |
| insufficient_data_actions | []                                                  |
| meter_name                | cpu_util                                            |
| name                      | cpu_high_enviro_prod                                |
| ok_actions                | []                                                  |
| period                    | 600                                                 |
| project_id                | 0de1e86542724be380d33acdc395eedd                    |
| query                     | metadata.user_metadata.environment == cloudtesting  |
| repeat_actions            | False                                               |
| state                     | insufficient data                                   |
| statistic                 | avg                                                 |
| threshold                 | 5.0                                                 |
| type                      | threshold                                           |
| user_id                   | c2ba631c180d43f3a2900cc3d300fb46                    |
+---------------------------+-----------------------------------------------------+
```

Please remember that the **metering.KEY=VALUE** item called in "nova boot/nova meta" command must be used in the alarm query section in the form **"metadata.user_metadata.KEY=VAULE"** during alarm creation with the command "ceilometer alarm-threshold-create":

**metering.KEY=VALUE => metadata.user_metadata.KEY=VALUE**

You can combine multiple metadata items in your query. Example:

```
ceilometer alarm-threshold-create \
--name cpu_high_enviro_prod_tigerlinux \
--description "CPU usage above 5 percent on Production Environment" \
--meter-name cpu_util \
--threshold 10 \
--comparison-operator gt \
--statistic avg --period 600 \
--evaluation-periods 1 \
--alarm-action 'log://' \
--query 'metadata.user_metadata.environment=cloudtesting;metadata.user_metadata.sysadmin=tigerlinux'

+---------------------------+--------------------------------------------------------+
| Property                  | Value                                                  |
+---------------------------+--------------------------------------------------------+
| alarm_actions             | [u'log://']                                            |
| alarm_id                  | fe5343fd-28d0-4622-9a1a-6c2f9c4a0e4c                   |
| comparison_operator       | gt                                                     |
| description               | CPU usage above 5 percent on Production Environment    |
| enabled                   | True                                                   |
| evaluation_periods        | 1                                                      |
| exclude_outliers          | False                                                  |
| insufficient_data_actions | []                                                     |
| meter_name                | cpu_util                                               |
| name                      | cpu_high_enviro_prod_tigerlinux                        |
| ok_actions                | []                                                     |
| period                    | 600                                                    |
| project_id                | 0de1e86542724be380d33acdc395eedd                       |
| query                     | metadata.user_metadata.environment == cloudtesting AND |
|                           | metadata.user_metadata.sysadmin == tigerlinux          |
| repeat_actions            | False                                                  |
| state                     | insufficient data                                      |
| statistic                 | avg                                                    |
| threshold                 | 10.0                                                   |
| type                      | threshold                                              |
| user_id                   | c2ba631c180d43f3a2900cc3d300fb46                       |
+---------------------------+--------------------------------------------------------+
```

The example above created an alarm that will trigger with any instance that have both keys: **metering.environment=cloudtesting** and **metering.sysadmin=tigerlinux**.

Also, you can query ceilometer the same way:

```
ceilometer statistics --meter cpu_util -q "metadata.user_metadata.environment=cloudtesting;metadata.user_metadata.sysadmin=tigerlinux" -a avg

+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| 0      | 2016-06-06T18:13:55 | 2016-06-06T18:13:55 | 1.89833333333 | 0.0      | 2016-06-06T18:13:55 | 2016-06-06T18:13:55 |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
```

## Final notes about webhooks:

Normally your configured alarms will show it's statuses to either ceilometer client and/or the logs, but, what if yoy want to call a REST when something change it's state ?. You can use the "alarm actions" and "ok actions" in the command used for alarm creation. Even when you have insufficient data you can call a REST:

From the ceilometer help:

```
  --alarm-action <Webhook URL>
                        URL to invoke when state transitions to alarm. May be
                        used multiple times. Defaults to None.
  --ok-action <Webhook URL>
                        URL to invoke when state transitions to OK. May be
                        used multiple times. Defaults to None.
  --insufficient-data-action <Webhook URL>
                        URL to invoke when state transitions to
                        insufficient_data. May be used multiple times.
```

Example:

```
ceilometer alarm-threshold-create \
--name cpu_high_enviro_prod_tigerlinux \
--description "CPU usage above 5 percent on Production Environment" \
--meter-name cpu_util \
--alarm-action http://myalarmconsole.mydomain.dom/restapi/alarm/environment/cloudtesting/sysadmin/tigerlinux \
--ok-action http://myalarmconsole.mydomain.dom/restapi/restored/environment/cloudtesting/sysadmin/tigerlinux \
--threshold 10 \
--comparison-operator gt \
--statistic avg --period 600 \
--evaluation-periods 1 \
--alarm-action 'log://' \
--query 'metadata.user_metadata.environment=cloudtesting;metadata.user_metadata.sysadmin=tigerlinux'
```

**NOTE ABOUT AUTOSCALING AND HEAT:** This is the base of AutoScaling groups in HEAT. The Scale-UP and Scale-DOWN events inside an AutoScale HEAT Template uses alarms and their webhooks. Normally you define a "scale-up" alarm tied with a "scale-up" policy for adding more instances when a determined metric is reached or maxed out, and "scale-down" alarm tied tith a "scale-down" policy once the metric falls bellow a specific value. The most used metric for this case is "cpu_util".

END.-


