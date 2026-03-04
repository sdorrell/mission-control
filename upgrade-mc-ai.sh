#!/bin/bash

echo "Installing Mission Control AI Agent..."

cd /opt/mission-control

npm install systeminformation socket.io chart.js

mkdir -p agents

cat > agents/ops-agent.js << 'AGENT'
import fs from "fs"
import os from "os"
import si from "systeminformation"
import pg from "pg"

const { Pool } = pg

const pool = new Pool({
 connectionString: process.env.DATABASE_URL,
 ssl:{rejectUnauthorized:false}
})

async function logEvent(type,message){
 await pool.query(
  "INSERT INTO events(type,message) VALUES($1,$2)",
  [type,message]
 )
}

async function checkSystem(){

 const cpu = await si.currentLoad()
 const mem = await si.mem()

 if(cpu.currentLoad > 80){
  await logEvent("alert","⚠ High CPU usage: "+cpu.currentLoad.toFixed(1)+"%")
 }

 const memUsed = mem.active/mem.total

 if(memUsed > 0.85){
  await logEvent("alert","⚠ Memory usage critical")
 }

}

async function checkDisk(){

 const disks = await si.fsSize()

 if(disks[0].use > 90){
  await logEvent("alert","⚠ Disk almost full")
 }

}

async function monitor(){

 try{

  await checkSystem()
  await checkDisk()

 }catch(err){
  console.log(err)
 }

}

setInterval(monitor,10000)

console.log("AI Ops Agent running")
AGENT


cat > agents/log-watcher.js << 'LOG'
import fs from "fs"
import pg from "pg"

const { Pool } = pg

const pool = new Pool({
 connectionString: process.env.DATABASE_URL,
 ssl:{rejectUnauthorized:false}
})

const logFile="/root/.pm2/logs/server-error.log"

let size=0

setInterval(async ()=>{

 try{

  const stats=fs.statSync(logFile)

  if(stats.size>size){

   const stream=fs.createReadStream(logFile,{
    start:size,
    end:stats.size
   })

   stream.on("data",async chunk=>{

    const text=chunk.toString()

    if(text.includes("Error")){
     await pool.query(
      "INSERT INTO events(type,message) VALUES($1,$2)",
      ["error","Server error detected"]
     )
    }

   })

   size=stats.size

  }

 }catch(err){}

},5000)

console.log("Log watcher running")
LOG


pm2 start agents/ops-agent.js --name ops-agent
pm2 start agents/log-watcher.js --name log-watcher

pm2 save

echo "AI Agent installed"
