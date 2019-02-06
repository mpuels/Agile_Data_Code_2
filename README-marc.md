# Agile Data Science 2.0: Marc's Notes

Provisioning script `aws/ec2_bootstrap.sh` does not register all services in
the system, so that some have to be started manually when restarting the EC2
instance.

Script `aws/start-services.sh` is intended to be run manually after each start
of the EC2 instance to start services.

Start PySpark on the EC2 instance with

    ubuntu$ /home/ubuntu/Agile_Data_Code_2
    ubuntu$ pyspark

Then on the local machine open http://localhost:8889 .


https://www.elastic.co/guide/en/elasticsearch/reference/5.3/gs-index-query.html

```
curl -XPUT 'localhost:9200/agile_data_science?pretty' \
-H 'Content-Type: application/json' -d'
{
"settings" : {
"index" : {
"number_of_shards" : 1,
"number_of_replicas" : 1
}
}
}
'
```

## Quick Tour through the Stack

- Jupyter Notebook
- PySpark (on Jupyter Notebook)
- MongoDB: We'll write data from Python to MongoDB
- ElasticSearch: Also a document store (but MongoDB has its advantages)
