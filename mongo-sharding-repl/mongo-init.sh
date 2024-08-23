#!/bin/bash

# Config servers initialization
docker exec -it mongo_cfgrs_1 mongosh --port 27091 --eval \
"rs.initiate({_id:'mongo_cfgrs', configsvr: true, \
members: [ \
  {_id:0, host:'mongo_cfgrs_1:27091'}, \
  {_id:1, host:'mongo_cfgrs_2:27092'}, \
  {_id:2, host:'mongo_cfgrs_3:27093'} \
]});"

# First shart initialization
docker exec -it mongo_dbrs_1 mongosh --port 27011 --eval \
"rs.initiate({_id:'mongo_dbrs', \
members: [ \
  {_id:0, host:'mongo_dbrs_1:27011'}, \
  {_id:1, host:'mongo_dbrs_2:27012'}, \
  {_id:2, host:'mongo_dbrs_3:27013'} \
]});"

# Second shart initialization
docker exec -it mongo_dbrs2_1 mongosh --port 27021 --eval \
"rs.initiate({_id:'mongo_dbrs2', \
members: [ \
  {_id:0, host:'mongo_dbrs2_1:27021'}, \
  {_id:1, host:'mongo_dbrs2_2:27022'}, \
  {_id:2, host:'mongo_dbrs2_3:27023'} \
]});"

sleep 20

# Router config
docker exec -it mongo_router mongosh --port 27080 --eval "sh.addShard('mongo_dbrs/mongo_dbrs_1:27011');"
docker exec -it mongo_router mongosh --port 27080 --eval "sh.addShard('mongo_dbrs2/mongo_dbrs2_1:27021');"
docker exec -it mongo_router mongosh --port 27080 --eval "sh.enableSharding('somedb');"
docker exec -it mongo_router mongosh --port 27080 --eval "sh.shardCollection('somedb.helloDoc', {'name': 'hashed'});"

# Adding initial data (1000 documents)
docker exec -it mongo_router mongosh --port 27080 --eval 'for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})' somedb