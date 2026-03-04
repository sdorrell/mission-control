#!/bin/bash

echo "Upgrading Mission Control..."

cd /opt/mission-control

npm install systeminformation socket.io chart.js

cat > server.js << 'SERVER'
import express from "express"
import pg from "pg"
import cors from "cors"
import path from "path"
import { fileURLToPath } from "url"
import http from "http"
import { Server } from "socket.io"
import si from "systeminformation"

const { Pool } = pg

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const app = express()
const server = http.createServer(app)
const io = new Server(server)

app.use(cors())
app.use(express.json())

const pool = new Pool({
 connectionString: process.env.DATABASE_URL,
 ssl:{rejectUnauthorized:false}
})

app.use("/mc", express.static(path.join(__dirname,"mc")))

app.get("/api/projects", async(req,res)=>{
 const r = await pool.query("SELECT * FROM projects ORDER BY id")
 res.json(r.rows)
})

app.get("/api/events", async(req,res)=>{
 const r = await pool.query("SELECT * FROM events ORDER BY timestamp DESC LIMIT 20")
 res.json(r.rows)
})

setInterval(async()=>{

 const cpu = await si.currentLoad()
 const mem = await si.mem()
 const disk = await si.fsSize()

 io.emit("telemetry",{
  cpu: cpu.currentLoad,
  memUsed:(mem.active/1024/1024/1024).toFixed(2),
  memTotal:(mem.total/1024/1024/1024).toFixed(2),
  disk: disk[0].use
 })

},3000)

const port = process.env.PORT || 3000

server.listen(port,()=>{
 console.log("Mission Control running on",port)
})
SERVER

cat > mc/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
<title>Mission Control</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="/socket.io/socket.io.js"></script>
<link rel="stylesheet" href="styles.css">
</head>

<body>

<h1>🚀 Mission Control</h1>

<div class="grid">

<div class="panel">
<h2>CPU</h2>
<canvas id="cpuChart"></canvas>
</div>

<div class="panel">
<h2>Memory</h2>
<div id="memory"></div>
</div>

<div class="panel">
<h2>Projects</h2>
<div id="projects"></div>
</div>

<div class="panel">
<h2>Events</h2>
<div id="events"></div>
</div>

</div>

<script src="app.js"></script>

</body>
</html>
HTML

cat > mc/app.js << 'JS'
const socket = io()

const ctx = document.getElementById("cpuChart")

let cpuData=[]

const chart=new Chart(ctx,{
 type:"line",
 data:{
  labels:[],
  datasets:[{
   label:"CPU %",
   data:cpuData
  }]
 },
 options:{animation:false}
})

socket.on("telemetry",data=>{

 document.getElementById("memory").innerText=
  data.memUsed+"GB / "+data.memTotal+"GB"

 chart.data.labels.push("")
 chart.data.datasets[0].data.push(data.cpu)

 if(chart.data.labels.length>20){
  chart.data.labels.shift()
  chart.data.datasets[0].data.shift()
 }

 chart.update()

})

async function load(){

 const p=await fetch("/api/projects").then(r=>r.json())
 const e=await fetch("/api/events").then(r=>r.json())

 document.getElementById("projects").innerHTML=
  p.map(x=>"<div>"+x.name+" "+x.status+"</div>").join("")

 document.getElementById("events").innerHTML=
  e.map(x=>"<div>"+x.message+"</div>").join("")

}

load()
setInterval(load,5000)
JS

cat > mc/styles.css << 'CSS'
body{
 background:#0b0f19;
 color:#65f4ff;
 font-family:monospace;
 padding:20px;
}

.grid{
 display:grid;
 grid-template-columns:repeat(2,1fr);
 gap:20px;
}

.panel{
 background:#111827;
 padding:20px;
 border-radius:10px;
}
CSS

pm2 restart mission-control

echo "Mission Control upgraded."
