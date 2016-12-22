# OPENSTACK CEILOMETER TIPS AND TRICKS.

- **By Reinaldo Martínez P.**
- **Caracas, Venezuela.**
- **TigerLinux AT gmail DOT com**
- **[My Google Plus Site](https://plus.google.com/+ReinaldoMartinez)**
- **[My Github Site](https://github.com/tigerlinux)**
- **[My Linkedin Profile - English](https://ve.linkedin.com/in/tigerlinux/en)**
- **[My Linkedin Profile - Spanish](https://ve.linkedin.com/in/tigerlinux/es)**


## About the Cloud and it's Metrics.

Let's talk about an engineering concept: **Telemetry**: Accordind to [Wikipedia telemetry article](https://en.wikipedia.org/wiki/Telemetry): "_Telemetry is an automated communications process by which measurements and other data are collected at remote or inaccessible points and transmitted to receiving equipment for monitoring._"

For openstack, the concept it really fits !. The telemetry OpenStack component, **Ceilometer**, is the one which function is to gatter system metrics from the other OpenStack components, convert those metrics in usable numbers, and store them in a database.

Almost everything can be measured by Ceilometer: Instance System Metrics (cpu, ram, traffic, disk-i/o, etc.), Block Storage used space, Network Floating IP's and Port usage, etc etc etc etc !.

Those metrics are also "married" to the project (tenant) which uses the resources, so in fact in a multi-tenant system we can obtain what resources has been used by each tenant, what is very good for billing purposes in a hybrid or public cloud.


## How do we obtain the metrics ?

Ceilometer store all it's metrics in a Database. The "production-usable" options range from MongoDB (non-sql approach) to SQL-based databases (MySQL, PostgreSQL, etc.), and more recently, gnocchi (we'll talk about gnocchi in other recipe).

Stored data means, timeline data !. Most practical system metrics used in modern monitoring are married with time, and is perfectly normal to have metric-vs-time graphics.

So, how can we obtain the metrics stored in ceilometer database backend ?. Two practical ways: Horizon "Resource Usage" tab, and the ceilometer "cli".

Using horizon can give you a fast view of resource usage in a specific time span. That's fully gui oriented, but, it can be very slow to use, even falling into "not practical". You can see the usage by tenant, but not by an specific resource (mean: An individual instance).

The second way is by far the more practical way and ir gives you the option to use your own billing system to interface with OpenStack telemetry: Using the ceilometer cli. That's the way this recipe will show to you in the following section !.


## Ceilometer client operations: Practical tips.

Ok... with no more delay, let's see some practical examples:


### Case 1: How to obtain CPU usage percent from a single, specific instance. Keys and Comparators:

First, remember to source your keystone identity file:

```
source ~/keystonerc_admin
```

Remember that in OpenStack, al components use keystone token-based authentication.

**NOTE: All this operations are fully available in the lasts OpenStack releases to date: juno, kilo, liberty and mitaka**

First thing to do, is obtain the **UUID** of the instance. Let's see try to find the **UUID** of an instance which name is ZABBIX-SERVER:

By using the openstack client, and some shell-scripting voodoo magic, we can obtain the UUID:

```
openstack server show ZABBIX-SERVER --format=shell|grep ^id=|cut -d\" -f2

005fab7d-ec10-4b44-9504-b58888731c78
```

Then, with the UUID, we can ask ceilometer for the cpu_util metric for that specific instance:

```
ceilometer statistics --meter cpu_util -q "resource=005fab7d-ec10-4b44-9504-b58888731c78"

+--------+---------------------+---------------------+---------------+---------+---------------+---------------+-------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Max           | Min     | Avg           | Sum           | Count | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+---------+---------------+---------------+-------+----------+---------------------+---------------------+
| 0      | 2016-05-18T16:43:55 | 2016-05-18T16:43:55 | 1.68916666667 | 0.84875 | 1.15199593322 | 165.887414384 | 144   | 85800.0  | 2016-05-18T16:43:55 | 2016-05-19T16:33:55 |
+--------+---------------------+---------------------+---------------+---------+---------------+---------------+-------+----------+---------------------+---------------------+
```

The metric "cpu_util" will display the CPU PERCENT utilization values:

* Max: Maximun value along all measurements.
* Min: Minimun value along all measurements.
* Avg: The Average value allong all measurements.

The duration start/end are dates in UTC (or Zulu Time) so for the actual date you need to take into consideration your timezone.
The "Duration" column show's the total time (in seconds) stored in the ceilometer database for this specific resource, and the "Count" shows how many samples are stored in the database.

So in conclusion for this specific case: We have 144 samples, spanning up to 85800 seconds starting at 18-May-2016, 4:43:55pm UTC, ending at 19-May-2016, 4:33:55pm UTC, where the maximun value was 1.689% CPU Usage, the minimun was 0.848%, and the average was 1.151%.

**Note something here:** The total duration of data will be limited by the "time-to-live" settings in your ceilometer installation. For this specific case, the platform I used have a TTL of one day (86400 seconds). The more the data, the more the storage, and the more the time it takes ceilometer to obtain the data you are loking for !.

The **"Max"**, **"Min"** and **"Avg"** are considered by ceilometer: "Functions". Those functions can be queried individually. See the following examples:

**Average function:**
```
ceilometer statistics --meter cpu_util -q "resource=005fab7d-ec10-4b44-9504-b58888731c78" -a avg

+--------+---------------------+---------------------+--------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg          | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+--------------+----------+---------------------+---------------------+
| 0      | 2016-06-05T12:43:57 | 2016-06-05T12:43:57 | 1.1261225341 | 85800.0  | 2016-06-05T12:43:57 | 2016-06-06T12:33:57 |
+--------+---------------------+---------------------+--------------+----------+---------------------+---------------------+
```

**Min and Max functions:**
```
ceilometer statistics --meter cpu_util -q "resource=005fab7d-ec10-4b44-9504-b58888731c78" -a min -a max
+--------+---------------------+---------------------+----------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Min            | Max           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+----------------+---------------+----------+---------------------+---------------------+
| 0      | 2016-06-05T12:43:57 | 2016-06-05T12:43:57 | 0.992174457429 | 1.48481697171 | 85800.0  | 2016-06-05T12:43:57 | 2016-06-06T12:33:57 |
+--------+---------------------+---------------------+----------------+---------------+----------+---------------------+---------------------+
```

Now, what if I want to see the metric behaviour partitioned in hours ??. We can add "-p PERIOD-IN-SECONDS" to the ceilometer cli: 


```
ceilometer statistics --meter cpu_util -q "resource=005fab7d-ec10-4b44-9504-b58888731c78" -p 3600

+--------+---------------------+---------------------+----------------+----------------+----------------+---------------+-------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Max            | Min            | Avg            | Sum           | Count | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+----------------+----------------+----------------+---------------+-------+----------+---------------------+---------------------+
| 3600   | 2016-05-18T16:53:09 | 2016-05-18T17:53:09 | 1.68916666667  | 1.39708333333  | 1.50381944444  | 9.02291666667 | 6     | 3000.0   | 2016-05-18T16:53:55 | 2016-05-18T17:43:55 |
| 3600   | 2016-05-18T17:53:09 | 2016-05-18T18:53:09 | 1.54625        | 1.3475         | 1.46828125     | 8.8096875     | 6     | 3000.0   | 2016-05-18T17:53:55 | 2016-05-18T18:43:55 |
| 3600   | 2016-05-18T18:53:09 | 2016-05-18T19:53:09 | 1.58666666667  | 1.4921875      | 1.54375        | 9.2625        | 6     | 3000.0   | 2016-05-18T18:53:55 | 2016-05-18T19:43:55 |
| 3600   | 2016-05-18T19:53:09 | 2016-05-18T20:53:09 | 1.48489583333  | 1.23291666667  | 1.39083333333  | 8.345         | 6     | 3000.0   | 2016-05-18T19:53:55 | 2016-05-18T20:43:55 |
| 3600   | 2016-05-18T20:53:09 | 2016-05-18T21:53:09 | 1.35604166667  | 1.13989583333  | 1.26996527778  | 7.61979166667 | 6     | 3000.0   | 2016-05-18T20:53:55 | 2016-05-18T21:43:55 |
| 3600   | 2016-05-18T21:53:09 | 2016-05-18T22:53:09 | 1.1315625      | 0.910416666667 | 0.990225694444 | 5.94135416667 | 6     | 3000.0   | 2016-05-18T21:53:55 | 2016-05-18T22:43:55 |
| 3600   | 2016-05-18T22:53:09 | 2016-05-18T23:53:09 | 1.00145833333  | 0.911666666667 | 0.964201388889 | 5.78520833333 | 6     | 3000.0   | 2016-05-18T22:53:55 | 2016-05-18T23:43:55 |
| 3600   | 2016-05-18T23:53:09 | 2016-05-19T00:53:09 | 0.964583333333 | 0.9025         | 0.929982638889 | 5.57989583333 | 6     | 3000.0   | 2016-05-18T23:53:55 | 2016-05-19T00:43:55 |
| 3600   | 2016-05-19T00:53:09 | 2016-05-19T01:53:09 | 1.01802083333  | 0.912083333333 | 0.976024305556 | 5.85614583333 | 6     | 3000.0   | 2016-05-19T00:53:55 | 2016-05-19T01:43:55 |
| 3600   | 2016-05-19T01:53:09 | 2016-05-19T02:53:09 | 0.9803125      | 0.940625       | 0.967673611111 | 5.80604166667 | 6     | 3000.0   | 2016-05-19T01:53:55 | 2016-05-19T02:43:55 |
| 3600   | 2016-05-19T02:53:09 | 2016-05-19T03:53:09 | 1.00739583333  | 0.934479166667 | 0.966458333333 | 5.79875       | 6     | 3000.0   | 2016-05-19T02:53:55 | 2016-05-19T03:43:55 |
| 3600   | 2016-05-19T03:53:09 | 2016-05-19T04:53:09 | 0.986770833333 | 0.900729166667 | 0.933680555556 | 5.60208333333 | 6     | 3000.0   | 2016-05-19T03:53:55 | 2016-05-19T04:43:55 |
| 3600   | 2016-05-19T04:53:09 | 2016-05-19T05:53:09 | 0.961875       | 0.9053125      | 0.934479166667 | 5.606875      | 6     | 3000.0   | 2016-05-19T04:53:55 | 2016-05-19T05:43:55 |
| 3600   | 2016-05-19T05:53:09 | 2016-05-19T06:53:09 | 0.946875       | 0.891666666667 | 0.9265625      | 5.559375      | 6     | 3000.0   | 2016-05-19T05:53:55 | 2016-05-19T06:43:55 |
| 3600   | 2016-05-19T06:53:09 | 2016-05-19T07:53:09 | 0.942708333333 | 0.916875       | 0.928506944444 | 5.57104166667 | 6     | 3000.0   | 2016-05-19T06:53:55 | 2016-05-19T07:43:55 |
| 3600   | 2016-05-19T07:53:09 | 2016-05-19T08:53:09 | 0.9840625      | 0.918020833333 | 0.95078125     | 5.7046875     | 6     | 3000.0   | 2016-05-19T07:53:55 | 2016-05-19T08:43:55 |
| 3600   | 2016-05-19T08:53:09 | 2016-05-19T09:53:09 | 1.00854166667  | 0.84875        | 0.945052083333 | 5.6703125     | 6     | 3000.0   | 2016-05-19T08:53:55 | 2016-05-19T09:43:55 |
| 3600   | 2016-05-19T09:53:09 | 2016-05-19T10:53:09 | 0.999270833333 | 0.9284375      | 0.961163194444 | 5.76697916667 | 6     | 3000.0   | 2016-05-19T09:53:55 | 2016-05-19T10:43:55 |
| 3600   | 2016-05-19T10:53:09 | 2016-05-19T11:53:09 | 1.08375        | 0.92625        | 1.00623190924  | 6.03739145543 | 6     | 3000.0   | 2016-05-19T10:53:55 | 2016-05-19T11:43:55 |
| 3600   | 2016-05-19T11:53:09 | 2016-05-19T12:53:09 | 1.30739583333  | 1.00572916667  | 1.14707596714  | 6.88245580283 | 6     | 3001.0   | 2016-05-19T11:53:55 | 2016-05-19T12:43:56 |
| 3600   | 2016-05-19T12:53:09 | 2016-05-19T13:53:09 | 1.534375       | 1.4152754591   | 1.49480285429  | 8.96881712577 | 6     | 3000.0   | 2016-05-19T12:53:55 | 2016-05-19T13:43:55 |
| 3600   | 2016-05-19T13:53:09 | 2016-05-19T14:53:09 | 1.5809375      | 1.44854166667  | 1.53105902778  | 9.18635416667 | 6     | 3000.0   | 2016-05-19T13:53:55 | 2016-05-19T14:43:55 |
| 3600   | 2016-05-19T14:53:09 | 2016-05-19T15:53:09 | 1.5784375      | 1.40875        | 1.48340277778  | 8.90041666667 | 6     | 3000.0   | 2016-05-19T14:53:55 | 2016-05-19T15:43:55 |
| 3600   | 2016-05-19T15:53:09 | 2016-05-19T16:53:09 | 1.54427083333  | 1.38114583333  | 1.44743055556  | 8.68458333333 | 6     | 3000.0   | 2016-05-19T15:53:55 | 2016-05-19T16:43:55 |
+--------+---------------------+---------------------+----------------+----------------+----------------+---------------+-------+----------+---------------------+---------------------+
```

The obtained data in the above command is now broken into 3600 seconds spans. 

What if you want to see the metric in a very specific time stamp ??. Then see the following example:

```
ceilometer statistics --meter cpu_util -q "resource=005fab7d-ec10-4b44-9504-b58888731c78;start=2016-06-05T21:53:56;end=2016-06-06T11:53:57" -a avg
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| 0      | 2016-06-05T21:53:56 | 2016-06-05T21:53:56 | 1.11850983748 | 49800.0  | 2016-06-05T21:53:56 | 2016-06-06T11:43:56 |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
```

**Please remember again: The dates/time's are UTC !!.**

In the example above, we combined in the query (-q) the resource UUID with the start and end dates:

```
q "resource=005fab7d-ec10-4b44-9504-b58888731c78;start=2016-06-05T21:53:56;end=2016-06-06T11:53:57"
```

**Please note something here:** As you probably noticed, the end date is not exactly the same you've specified in your query. That is because ceilometer will show you the last sample it found just before or at the exact time the "end" date is. Because it found no sample at "exactly" your end date, then it found for you the most nearer the end date in your query.

Also please note you can use ">", ">=", "<" and "=<" for date operations, if you use "timestamp" instead of "start/end" (start/end only support "="):


```
ceilometer statistics --meter cpu_util -q "resource=005fab7d-ec10-4b44-9504-b58888731c78;timestamp>=2016-06-05T21:53:56;timestamp<=2016-06-06T11:53:57" -a avg
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| 0      | 2016-06-05T21:53:56 | 2016-06-05T21:53:56 | 1.11823261496 | 50401.0  | 2016-06-05T21:53:56 | 2016-06-06T11:53:57 |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
```

In conclusion, you can (and should) construct your query with different keys and comparators (all ";" separated) in order to obtain the specific data you want.

The most common types of keys you can use in your query are:

* start: Start Date.
* End: End Date.
* Resource: Resource UUID.
* Project: Tenant/Project UUID.
* Timestamp: TimeStamp in UTC (see examples above).

Note: Please take a reading in ceilometer documentation to see other usable keys !.


### Case 2: What about the metric-samples and queries to specific projects/tenants ??

If you are not sure about the "samples" supported by an specific resource, you can query ceilometer. See the following example:

```
ceilometer sample-list -q "resource=608b358f-e3de-43e9-be1d-007e2f010c02"|grep 608b358f-e3de-43e9-be1d-007e2f010c02|awk '{print $6}'|sort|uniq

cpu
cpu.delta
cpu_util
disk.allocation
disk.capacity
disk.ephemeral.size
disk.read.bytes
disk.read.bytes.rate
disk.read.requests
disk.read.requests.rate
disk.root.size
disk.usage
disk.write.bytes
disk.write.bytes.rate
disk.write.requests
disk.write.requests.rate
instance
memory
memory.resident
vcpus
```

The command "**ceilometer sample-list**" by itself can show you a LOT of information, so is better to use the queries and filters in order to limit it's output. In the example above, by combining the "-q" and some shell scripting we manage to obtain the list of supported metrics for a specific resource (in this case, a single instance with UUID: 608b358f-e3de-43e9-be1d-007e2f010c02).

Let's see some how to obtain some data for a specific project (or tenant):

First, let's obtain the projects and it's UUID's:

```
openstack project list

+----------------------------------+-----------------+
| ID                               | Name            |
+----------------------------------+-----------------+
| 0de1e86542724be380d33acdc395eedd | admin           |
| 3e611e2108db4a638b4845b7715e25ca | Infrastructure  |
| 44d30c54a04243eb8ba4af053712b3d6 | services        |
| 9554c9a3e7594d47a09c992c5cd4adcc | development     |
| 962c86b9de4c4bc9ae13bef4c8902c02 | operations      |
| b3d1f623d5c64a8c968b81ff7b751686 | cloudtesting    |
+----------------------------------+-----------------+
```

Then, we can obtain the full list of all and each recorded metric sample for a specific metric in a specific project (or tenant):

```
ceilometer query-samples --filter '{"and": [{"=": {"counter_name":"cpu_util"}}, {"=": {"project":"3e611e2108db4a638b4845b7715e25ca"}}]}'
```

The result of the former example is far too long to put it here, because it include all samples for the metric (cpu_util in this case) and for all instances in the project (3e611e2108db4a638b4845b7715e25ca)

We can limit the output with **"--limit N"**. Example follows:

```
ceilometer query-samples --filter '{"and": [{"=": {"counter_name":"cpu_util"}}, {"=": {"project":"3e611e2108db4a638b4845b7715e25ca"}}]}' --limit 20

+--------------------------------------+----------+-------+-----------------+------+---------------------+
| Resource ID                          | Meter    | Type  | Volume          | Unit | Timestamp           |
+--------------------------------------+----------+-------+-----------------+------+---------------------+
| 47af0bfc-3d5d-45e2-be5c-977748bcdd06 | cpu_util | gauge | 0.189583333333  | %    | 2016-05-19T17:23:59 |
| 1989a262-c455-4f69-8f70-a5afdb850765 | cpu_util | gauge | 0.0666666666667 | %    | 2016-05-19T17:23:59 |
| 583948c8-fdee-46f9-a62d-108820f054f5 | cpu_util | gauge | 0.560416666667  | %    | 2016-05-19T17:23:59 |
| fd34499d-4c6b-4342-b2c2-3dab16613224 | cpu_util | gauge | 0.218958333333  | %    | 2016-05-19T17:23:57 |
| cfb875e9-13ae-46f8-a9e2-4fc6e07a48e4 | cpu_util | gauge | 2.11666666667   | %    | 2016-05-19T17:23:57 |
| 5caffa6c-8ecb-4a27-bb1c-6f3835d18163 | cpu_util | gauge | 1.81946755408   | %    | 2016-05-19T17:23:57 |
| d1445466-6949-4e70-9796-b5b0e97e418e | cpu_util | gauge | 0.108985024958  | %    | 2016-05-19T17:23:57 |
| 385943cb-4fd7-4757-ba78-6fc202f834b6 | cpu_util | gauge | 0.164309484193  | %    | 2016-05-19T17:23:57 |
| 27b28934-2d5c-4e54-ab10-bd7e71de9a3f | cpu_util | gauge | 1.31916666667   | %    | 2016-05-19T17:23:56 |
| 782df4d8-8490-42b5-b2dd-8e707aa4a441 | cpu_util | gauge | 2.59708333333   | %    | 2016-05-19T17:23:56 |
| 7e9f9226-36ba-4b29-b5d4-26603b75e5d0 | cpu_util | gauge | 3.33583333333   | %    | 2016-05-19T17:23:56 |
| c7c3f761-6592-4e6a-b8b2-49108d3c7fe6 | cpu_util | gauge | 6.44916666667   | %    | 2016-05-19T17:23:56 |
| abcc6f29-27d2-45a4-97a7-b9278c2eec76 | cpu_util | gauge | 0.583333333333  | %    | 2016-05-19T17:23:56 |
| cf113c26-ee82-4e9e-89dd-63fd08a5ee7d | cpu_util | gauge | 5.12916666667   | %    | 2016-05-19T17:23:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.27083333333   | %    | 2016-05-19T17:23:56 |
| b8d5dea3-896b-4322-aa66-b8ef092d8fec | cpu_util | gauge | 0.669166666667  | %    | 2016-05-19T17:23:56 |
| b0876ad6-69fa-4cf6-9658-9a39a218de16 | cpu_util | gauge | 0.123333333333  | %    | 2016-05-19T17:23:56 |
| 31d2bfa2-b5a1-41a2-8417-14bac1f71e2d | cpu_util | gauge | 0.710104166667  | %    | 2016-05-19T17:23:56 |
| abc0da57-b5da-409e-b4e2-bcae2ba35721 | cpu_util | gauge | 0.0875          | %    | 2016-05-19T17:23:56 |
| c3cae294-e71e-4642-a2a8-fb8b057202de | cpu_util | gauge | 48.8658333333   | %    | 2016-05-19T17:23:56 |
+--------------------------------------+----------+-------+-----------------+------+---------------------+
```

This list include all resource ID's. We can see a specific resource too:

```
ceilometer query-samples --filter '{"and": [{"=": {"counter_name":"cpu_util"}}, {"=": {"resource":"503ace48-b9e6-4dfa-aa25-2e22522aedac"}}]}' --limit 20

+--------------------------------------+----------+-------+---------------+------+---------------------+
| Resource ID                          | Meter    | Type  | Volume        | Unit | Timestamp           |
+--------------------------------------+----------+-------+---------------+------+---------------------+
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.45008319468 | %    | 2016-05-19T17:33:57 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.27083333333 | %    | 2016-05-19T17:23:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.37          | %    | 2016-05-19T17:13:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.45492487479 | %    | 2016-05-19T17:03:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.34442595674 | %    | 2016-05-19T16:53:57 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.285         | %    | 2016-05-19T16:43:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.44833333333 | %    | 2016-05-19T16:33:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.26166666667 | %    | 2016-05-19T16:23:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.31969949917 | %    | 2016-05-19T16:13:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.43760399334 | %    | 2016-05-19T16:03:57 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.32333333333 | %    | 2016-05-19T15:53:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.3575        | %    | 2016-05-19T15:43:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.49666666667 | %    | 2016-05-19T15:33:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.33583333333 | %    | 2016-05-19T15:23:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.30916666667 | %    | 2016-05-19T15:13:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.51833333333 | %    | 2016-05-19T15:03:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.36          | %    | 2016-05-19T14:53:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.325         | %    | 2016-05-19T14:43:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.48916666667 | %    | 2016-05-19T14:33:56 |
| 503ace48-b9e6-4dfa-aa25-2e22522aedac | cpu_util | gauge | 1.305         | %    | 2016-05-19T14:23:56 |
+--------------------------------------+----------+-------+---------------+------+---------------------+
```

Ok but what is the possible purpose of this ??.. Simple: What if you want to export the raw data from ceilometer to another system ?. This is the way to perform such task.

If you are interested on obtaining all cpu usage for a whole project and all it's instances, you can use the UUID of the project into the ceilometer query:

First, obtain the project list and uuid's:

```
openstack project list

+----------------------------------+-----------------+
| ID                               | Name            |
+----------------------------------+-----------------+
| 0de1e86542724be380d33acdc395eedd | admin           |
| 3e611e2108db4a638b4845b7715e25ca | Infrastructure  |
| 44d30c54a04243eb8ba4af053712b3d6 | services        |
| 9554c9a3e7594d47a09c992c5cd4adcc | development     |
| 962c86b9de4c4bc9ae13bef4c8902c02 | operations      |
| b3d1f623d5c64a8c968b81ff7b751686 | cloudtesting    |
+----------------------------------+-----------------+
```

Let's see how much average cpu has been used by the "Infrastructure" project, UUID: 3e611e2108db4a638b4845b7715e25ca, between 2016-06-06T00:00:00 and 2016-06-06T15:00:00

```
ceilometer statistics --meter cpu_util -q "project=3e611e2108db4a638b4845b7715e25ca;timestamp>=2016-06-06T00:00:00;timestamp<=2016-06-06T15:00:00" -a avg
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| 0      | 2016-06-06T01:13:55 | 2016-06-06T01:13:55 | 1.59205229434 | 49801.0  | 2016-06-06T00:02:44 | 2016-06-06T13:52:45 |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
```

The above sample show's all average CPU usage in the specific timestamp range for all instances in the "Infrastructure" project/tenant.

What about the vcpus used by the project ??:

```
ceilometer statistics --meter vcpus -q "project=3e611e2108db4a638b4845b7715e25ca;timestamp>=2016-06-06T00:00:00;timestamp<=2016-06-06T15:00:00"
+--------+----------------------------+----------------------------+------+-----+---------------+--------+-------+-----------+----------------------------+----------------------------+
| Period | Period Start               | Period End                 | Max  | Min | Avg           | Sum    | Count | Duration  | Duration Start             | Duration End               |
+--------+----------------------------+----------------------------+------+-----+---------------+--------+-------+-----------+----------------------------+----------------------------+
| 0      | 2016-06-06T13:00:59.494000 | 2016-06-06T13:00:59.494000 | 16.0 | 1.0 | 5.69736842105 | 6062.0 | 1064  | 46859.098 | 2016-06-06T00:00:00.396000 | 2016-06-06T13:00:59.494000 |
+--------+----------------------------+----------------------------+------+-----+---------------+--------+-------+-----------+----------------------------+----------------------------+
```

So in conclusion, our guys at "Infrastructure project" has been using an average of 1.5920% of CPU Power and a maximun of 16 vpu's during all the timestamp we included in our queries.


### Case 3: Using scripting to get our data in an ordered way

We can use our openstack client tools to creativelly obtain some data from ceilometer. The following sample will give you some tips of how to use those tools to get the data you need in an ordered way:

```
source /root/keystonerc_admin

for uuid in `openstack server list --format=csv --all-projects 2>/dev/null|grep -v ID|cut -d\" -f2`; do echo "Instance:$uuid"; ceilometer statistics --meter cpu_util --query resource=$uuid -a avg;echo "";done

Instance:47ba7715-adba-40ab-a525-5e70f2006fa0
+--------+---------------------+---------------------+----------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg            | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+----------------+----------+---------------------+---------------------+
| 0      | 2016-05-26T17:03:53 | 2016-05-26T17:03:53 | 0.224484987928 | 85800.0  | 2016-05-26T17:03:53 | 2016-05-27T16:53:53 |
+--------+---------------------+---------------------+----------------+----------+---------------------+---------------------+

Instance:e469d5a1-272a-4de6-b662-4df9ac170ff0
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| 0      | 2016-05-26T17:03:57 | 2016-05-26T17:03:57 | 2.38767393187 | 85800.0  | 2016-05-26T17:03:57 | 2016-05-27T16:53:57 |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+

Instance:82fb6b5e-acf8-4ef6-81aa-66d77502001e
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| 0      | 2016-05-26T17:03:58 | 2016-05-26T17:03:58 | 2.88892884891 | 85800.0  | 2016-05-26T17:03:58 | 2016-05-27T16:53:58 |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+

Instance:47facb40-d8d1-49ac-8c7b-b230d9bf890c
+--------+---------------------+---------------------+----------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg            | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+----------------+----------+---------------------+---------------------+
| 0      | 2016-05-26T17:03:56 | 2016-05-26T17:03:56 | 0.862603927067 | 85800.0  | 2016-05-26T17:03:56 | 2016-05-27T16:53:56 |
+--------+---------------------+---------------------+----------------+----------+---------------------+---------------------+

Instance:ccfa4b72-0d49-49c3-940a-c9491e4f711f
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| Period | Period Start        | Period End          | Avg           | Duration | Duration Start      | Duration End        |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
| 0      | 2016-05-26T17:03:53 | 2016-05-26T17:03:53 | 1.22981112257 | 85800.0  | 2016-05-26T17:03:53 | 2016-05-27T16:53:53 |
+--------+---------------------+---------------------+---------------+----------+---------------------+---------------------+
```

The above command will list all your instances in all your projects and print the average CPU_UTIL used by each instance during the full duration of your ceilometer-collected data. This sample is very easy to convert into a crontab task that will periodically show the cpu consumption in our your cloud.


## Things you need to consider in Ceilometer.

The following tips and considerations must be taken into account by you for a better ceilometer experience:

* By default, ceilometer take samples every 600 seconds. This is controlled in the file: `/etc/ceilometer/pipeline.yaml`. You can adjust this time to less or more seconds, but, take into account the following: The less seconds you configure, the more accurate picture you'll have, but, you'll increase the pressure over the database backend (more space, and more disk I/O). Also your queries will take longer. In other hand, the more seconds you configure here, you'll decrease your database consumption in terms of space and I/O, but, your data will be less acurate. Also, your queries will be faster.
* In big deployments, you should consider installing your ceilometer backend database in it's own server (or servers) separated from the Ceilometer installation. Remember also that from OpenStack Mitaka, the ceilometer alarming has been separated from the main ceilometer-core into it's own module (aodh) with it's own SQL-Based database.
* Please DONT use SQL-Based databases for the metrics database. Mongo-DB is still the best option for ceilometer metrics storage, at least until "gnocchi" is fully integrated to the ceilometer core. Eventually, gnocchi will replace mongodb for the metric-storage backend in ceilometer, but until this finally happens, stick with MongoDB.
* Adjust your "time to live" in ceilometer to realistic values. If you want to include a "year", take into account that your stored data will take A LOT of space and it will need a lot of I/O. You'll need to plan very carefully your queries, or you can basically lock ceilometer and it's database. Again: Be realistic !!.
* Script everything, and "crontab it" too. Don't loose your time with manual tasks that you can (and should) automate. Be practical and save time (time is money in the real world) !. Linux has many ways to automate things, and OpenStack CLI tools has also many ways to help you do things.

END.-
