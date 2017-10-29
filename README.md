# ローカル環境構築手順

## 構成

| サーバ | OS | 台数 | Spark |YARN Resource | HDFS NameNode | YARN NodeManager | HDFS DataNode | Ruby Itamae |
|:--|:--|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Hadoopマスター | CentOS7(64bit) | 1 | | ○ | ○ |
| Hadoopスレーブ | CentOS7(64bit) | 2 | |  |  | ○ | ○ |
| Local Mac | MacOS | 1 | ○ | |  |  |  | ○ | ○ | ○ | ○ |


## 環境構築方法の方針

環境構築ツールとして、`itamae` を利用して、VitualBox上にHadoopサーバ、ローカルにSparkをインストールする。
ローカル環境には、「brew」,「Ruby＋Itamae」は既にインストールされてるものとする。


## 開発環境構築

### 1. Hadoop関係サーバをVagrantで立ち上げる

ローカル環境で以下のコマンドを実行

```
local$ cd ${local_build}/vagrant
local$ vagrant up
```


### 2. Vagrantアカウントでitamaeインストールするための秘密鍵情報を登録する

ローカル環境で以下のコマンドを実行

```
local$ vagrant ssh-config >> ~/.ssh/config
```


### 3. Itamaeを使ってHadoop環境を構築

ローカル環境で以下のコマンドを実行

```
local$ itamae ssh -h hdp-mst cookbooks/hadoop-common.rb -y node.yml
local$ itamae ssh -h hdp-slv1 cookbooks/hadoop-common.rb -y node.yml
local$ itamae ssh -h hdp-slv2 cookbooks/hadoop-common.rb -y node.yml
```



### 4. hadoopマスターノードにログインしてNamenodeを初期化

```
local$ ssh hdp-mst

hdp-mst$ su - hadoop
hdp-mst$ start-dfs.sh
hdp-mst$ hdfs namenode -format
hdp-mst$ stop-dfs.sh
```


### 5. Hadoop,YARNを起動する

Hadoopマスタサーバで以下のコマンドを実行

```
hdp-mst$ su - hadoop
hdp-mst$ start-dfs.sh
hdp-mst$ start-yarn.sh
```


### 6. ローカルPC側の設定

#### 6-1. /etc/hostsの設定

`/etc/hosts`に以下の設定を追加する。

```
192.168.1.10    hdp-mst
192.168.1.11    hdp-slv1
192.168.1.12    hdp-slv2
```

#### 6-2. インストール

ローカルPCにJavaとSparkをインストールする。　　
また、ローカルPCをクライアントとしてHadoopに接続するために、`brew`でhadoopをインストールする。

```
# Javaのインストール
localPC$ brew cask install java

# Hadoopのインストール
localPC$ brew install hadoop

# Sparkのインストール
localPC$ curl -LO /tmp
localPC$ curl -LO https://d3kbcqa49mib13.cloudfront.net/spark-2.2.0-bin-hadoop2.7.tgz
localPC$ cd /tmp
localPC$ tar xvfz spark-2.2.0-bin-hadoop2.7.tgz
localPC$ ln -s /tmp/spark-2.2.0-bin-hadoop2.7 /tmp/spark
```

#### 6-3. Hadoopの設定

ローカルPCの`core-site.xml`, `yarn-site.xml`ファイルを編集して以下の設定をいれる

`/usr/local/Cellar/hadoop/2.8.1/libexec/etc/hadoop/core-site.xml`

```
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://hdp-mst:8020</value>
  </property>
</configuration>
```

`/usr/local/Cellar/hadoop/2.8.1/libexec/etc/hadoop/yarn-site.xml`

```
<?xml version="1.0"?>
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>hdp-mst</value>
  </property>
</configuration>
```


環境変数を設定する。

```
localPC$ export HADOOP_USER_NAME=hadoop
localPC$ echo 'export HADOOP_USER_NAME=hadoop' >> ~/.bashrc
```

#### 6-4. Sparkの設定

HDFSにディレクトリ作成

```
localPC$ hdfs dfs -mkdir /spark-logs
localPC$ hdfs dfs -mkdir /hadoop
localPC$ hdfs dfs -mkdir /hadoop/tmp
localPC$ hdfs dfs -mkdir /hadoop/yarn
localPC$ hdfs dfs -mkdir /hadoop/yarn/app-logs
```

`$SPARK_HOME/conf/spark-defaults.conf`に以下の内容を追記する。

```
spark.master  yarn
spark.eventLog.enabled  true
spark.eventLog.dir  hdfs://hdp-mst:8020/spark-logs
spark.serializer  org.apache.spark.serializer.KryoSerializer
spark.driver.memory   2g
spark.history.fs.logDirectory  hdfs://hdp-mst:8020/spark-logs
```

`$SPARK_HOME/conf/spark-env.sh`に以下の内容を追記する。

```
HADOOP_CONF_DIR=/usr/local/Cellar/hadoop/2.8.1/libexec/etc/hadoop
```

環境変数を設定する。

```
localPC$ export SPARK_HOME=/tmp/spark
localPC$ export PATH=$PATH:$SPARK_HOME/bin
localPC$ echo 'export SPARK_HOME=/tmp/spark' >> ~/.bashrc
localPC$ echo 'export PATH=$PATH:$SPARK_HOME/bin' >> ~/.bashrc
```

### 7. 動作確認

`spark-shell`を起動して、yarnに接続できることを確認する。以下のような表示であればOK。

```
localPC$ spark-shell --master yarn --deploy-mode client

...

17/10/30 00:26:42 INFO Client: Application report for application_1509288512260_0003 (state: ACCEPTED)
17/10/30 00:26:42 INFO Client:
   client token: N/A
   diagnostics: AM container is launched, waiting for AM container to Register with RM
   ApplicationMaster host: N/A
   ApplicationMaster RPC port: -1
   queue: default
   start time: 1509289658886
   final status: UNDEFINED
   tracking URL: http://hdp-mst:8088/proxy/application_1509288512260_0003/
   user: hadoop
...

Spark context Web UI available at http://192.168.1.1:4041
Spark context available as 'sc' (master = yarn, app id = application_1509288512260_0003).
Spark session available as 'spark'.
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 2.2.0
      /_/

Using Scala version 2.11.8 (Java HotSpot(TM) 64-Bit Server VM, Java 1.8.0_144)
Type in expressions to have them evaluated.
Type :help for more information.

scala>
```

yarnを使わずに、ローカルモードで起動したい場合は、以下のコマンドで起動する。

```
localPC$ spark-shell --master local
```
